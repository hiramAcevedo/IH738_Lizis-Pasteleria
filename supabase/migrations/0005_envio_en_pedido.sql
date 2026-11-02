-- crear_pedido guardaba el total con envío pero dejaba la columna envio en 0.
-- p_items: [{"producto_id": 1, "variantes": [3, 5], "cantidad": 2}]. Devuelve el folio.
create or replace function public.crear_pedido(
  p_items jsonb,
  p_modalidad text,
  p_fecha date,
  p_horario text,
  p_direccion text,
  p_telefono text,
  p_notas text default null
)
returns text
language plpgsql security definer set search_path = ''
as $$
declare
  v_usuario uuid := auth.uid();
  v_aj public.ajustes;
  v_pedido bigint;
  v_folio text;
  v_item jsonb;
  v_prod public.productos;
  v_cantidad int;
  v_variantes bigint[];
  v_extra numeric(10, 2);
  v_detalle text;
  v_subtotal numeric(10, 2) := 0;
  v_envio numeric(10, 2) := 0;
  v_ocupados int;
begin
  if v_usuario is null then
    raise exception 'Inicia sesión para hacer un pedido';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'El carrito está vacío';
  end if;
  select * into v_aj from public.ajustes where id = 1;
  if p_modalidad is null or p_modalidad not in ('entrega', 'recoleccion') then
    raise exception 'Elige entrega a domicilio o recolección';
  end if;
  if p_fecha is null or p_fecha < public.hoy_mx() + v_aj.dias_anticipacion then
    raise exception 'La fecha debe ser a partir del %', to_char(public.hoy_mx() + v_aj.dias_anticipacion, 'DD/MM/YYYY');
  end if;
  if p_fecha > public.hoy_mx() + 60 then
    raise exception 'Los pedidos se reciben con un máximo de 60 días de anticipación';
  end if;
  if p_horario is null or not (p_horario = any (v_aj.horarios)) then
    raise exception 'Elige uno de los horarios disponibles';
  end if;
  if p_modalidad = 'entrega' and coalesce(trim(p_direccion), '') = '' then
    raise exception 'Escribe la dirección de entrega';
  end if;
  if coalesce(trim(p_telefono), '') !~ '^[0-9 +()-]{10,20}$' then
    raise exception 'Escribe un teléfono de 10 dígitos';
  end if;

  -- Dos pedidos al mismo tiempo para la misma fecha no rebasan el cupo: la fecha se bloquea durante la transacción.
  perform pg_advisory_xact_lock(hashtext('lizis-fecha-' || p_fecha::text));
  select count(*) into v_ocupados from public.pedidos where fecha_entrega = p_fecha and estado <> 'cancelado';
  if v_ocupados >= v_aj.capacidad_diaria then
    raise exception 'Ya no hay lugar para el %; elige otra fecha', to_char(p_fecha, 'DD/MM/YYYY');
  end if;

  if p_modalidad = 'entrega' then
    v_envio := v_aj.costo_envio;
  end if;

  insert into public.pedidos (usuario_id, modalidad, fecha_entrega, horario, direccion, telefono, notas)
  values (v_usuario, p_modalidad, p_fecha, p_horario, nullif(trim(p_direccion), ''), trim(p_telefono), nullif(trim(p_notas), ''))
  returning id, folio into v_pedido, v_folio;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_prod from public.productos where id = (v_item ->> 'producto_id')::bigint and visible;
    if not found then
      raise exception 'Un producto del carrito ya no está disponible';
    end if;
    v_cantidad := coalesce((v_item ->> 'cantidad')::int, 0);
    if v_cantidad < 1 or v_cantidad > 50 then
      raise exception 'La cantidad de % debe ser de 1 a 50', v_prod.nombre;
    end if;
    select coalesce(array_agg(x::bigint), '{}') into v_variantes
    from jsonb_array_elements_text(coalesce(v_item -> 'variantes', '[]'::jsonb)) as x;
    if exists (
      select 1 from unnest(v_variantes) as vid
      where not exists (select 1 from public.variantes v where v.id = vid and v.producto_id = v_prod.id)
    ) then
      raise exception 'Hay una opción que no corresponde a %', v_prod.nombre;
    end if;
    -- Una opción por grupo, y todos los grupos del producto elegidos.
    if (select count(distinct grupo) from public.variantes where id = any (v_variantes)) <> cardinality(v_variantes)
       or (select count(distinct grupo) from public.variantes where producto_id = v_prod.id) <> cardinality(v_variantes) then
      raise exception 'Elige una opción de cada grupo en %', v_prod.nombre;
    end if;
    select coalesce(sum(precio_extra), 0), coalesce(string_agg(grupo || ': ' || nombre, ' · ' order by grupo), '')
    into v_extra, v_detalle
    from public.variantes where id = any (v_variantes);

    insert into public.pedido_items (pedido_id, producto_id, nombre, detalle, precio_unitario, cantidad, importe)
    values (v_pedido, v_prod.id, v_prod.nombre, v_detalle, v_prod.precio + v_extra, v_cantidad, (v_prod.precio + v_extra) * v_cantidad);
    v_subtotal := v_subtotal + (v_prod.precio + v_extra) * v_cantidad;
  end loop;

  update public.pedidos set subtotal = v_subtotal, envio = v_envio, total = v_subtotal + v_envio where id = v_pedido;
  insert into public.historial_estados (pedido_id, estado, usuario_id) values (v_pedido, 'pendiente_pago', v_usuario);
  return v_folio;
end
$$;

-- El pedido de prueba que se creó antes de la corrección.
update public.pedidos set envio = total - subtotal where envio = 0 and total > subtotal;
