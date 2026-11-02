-- Lizis Pastelería · reglas de negocio en la base
-- Los precios, la capacidad por día y los cambios de estado se deciden aquí, no en el navegador.

create or replace function public.es_admin()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.perfiles where id = auth.uid() and rol = 'admin')
$$;

create or replace function public.hoy_mx()
returns date
language sql stable set search_path = ''
as $$
  select (now() at time zone 'America/Mexico_City')::date
$$;

-- Cada cuenta nueva de Supabase Auth tiene su perfil de cliente.
create or replace function public.crear_perfil()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.perfiles (id, nombre)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'nombre', ''));
  return new;
end
$$;

create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil();

-- Las fechas que el cliente puede elegir: desde hoy más la anticipación, con lugar si no se llenó el cupo del día.
create or replace function public.fechas_entrega(p_dias int default 21)
returns table (fecha date, ocupados int, disponible boolean)
language sql stable security definer set search_path = ''
as $$
  with a as (select dias_anticipacion, capacidad_diaria from public.ajustes where id = 1),
  d as (
    select (public.hoy_mx() + a.dias_anticipacion + g)::date as fecha, a.capacidad_diaria
    from a, generate_series(0, least(greatest(p_dias, 1), 60) - 1) as g
  )
  select d.fecha, coalesce(c.n, 0)::int, coalesce(c.n, 0) < d.capacidad_diaria
  from d
  left join (
    select fecha_entrega, count(*) as n from public.pedidos where estado <> 'cancelado' group by fecha_entrega
  ) c on c.fecha_entrega = d.fecha
  order by d.fecha
$$;

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

-- El servidor la llama después de comprobar con Stripe que la sesión de pago está pagada.
-- La clave vive en el esquema privado, que la API no expone; sólo el servidor la conoce.
create schema if not exists privado;
revoke all on schema privado from public, anon, authenticated;
create table privado.claves (
  nombre text primary key,
  valor text not null
);

create or replace function public.confirmar_pago(p_folio text, p_sesion text, p_clave text)
returns text
language plpgsql security definer set search_path = ''
as $$
declare
  v_id bigint;
  v_estado text;
begin
  if p_clave is null or p_clave is distinct from (select valor from privado.claves where nombre = 'servidor') then
    raise exception 'No autorizado';
  end if;
  select id, estado into v_id, v_estado from public.pedidos where folio = p_folio for update;
  if not found then
    raise exception 'Pedido no encontrado';
  end if;
  if v_estado <> 'pendiente_pago' then
    return v_estado;
  end if;
  update public.pedidos set estado = 'pagado', pagado_el = now(), stripe_sesion = p_sesion where id = v_id;
  insert into public.historial_estados (pedido_id, estado) values (v_id, 'pagado');
  return 'pagado';
end
$$;

-- El cliente cancela su pedido mientras no lo haya pagado.
create or replace function public.cancelar_pedido(p_folio text)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_id bigint;
begin
  select id into v_id from public.pedidos
  where folio = p_folio and usuario_id = auth.uid() and estado = 'pendiente_pago'
  for update;
  if not found then
    raise exception 'Sólo se cancela un pedido propio que todavía no se paga';
  end if;
  update public.pedidos set estado = 'cancelado' where id = v_id;
  insert into public.historial_estados (pedido_id, estado, usuario_id) values (v_id, 'cancelado', auth.uid());
end
$$;

-- La propietaria mueve el pedido por sus estados, en orden.
create or replace function public.cambiar_estado(p_pedido bigint, p_estado text)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_actual text;
begin
  if not public.es_admin() then
    raise exception 'Sólo la administración cambia el estado de un pedido';
  end if;
  select estado into v_actual from public.pedidos where id = p_pedido for update;
  if not found then
    raise exception 'Pedido no encontrado';
  end if;
  if not (
    (v_actual = 'pagado' and p_estado in ('en_preparacion', 'cancelado')) or
    (v_actual = 'en_preparacion' and p_estado in ('listo', 'cancelado')) or
    (v_actual = 'listo' and p_estado in ('entregado', 'cancelado')) or
    (v_actual = 'pendiente_pago' and p_estado = 'cancelado')
  ) then
    raise exception 'Un pedido % no puede pasar a %', replace(v_actual, '_', ' '), replace(p_estado, '_', ' ');
  end if;
  update public.pedidos set estado = p_estado where id = p_pedido;
  insert into public.historial_estados (pedido_id, estado, usuario_id) values (p_pedido, p_estado, auth.uid());
end
$$;

-- El cliente acepta o rechaza la cotización de su pastel personalizado.
create or replace function public.responder_cotizacion(p_folio text, p_acepta boolean)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  update public.solicitudes
  set estado = case when p_acepta then 'aceptada' else 'rechazada' end
  where folio = p_folio and usuario_id = auth.uid() and estado = 'cotizada';
  if not found then
    raise exception 'La solicitud no tiene una cotización pendiente de respuesta';
  end if;
end
$$;

-- Reportes: cuentan lo cobrado (pedidos pagados que no se cancelaron), por día de pago en hora de México.
create or replace function public.ventas_por_dia(p_desde date, p_hasta date)
returns table (dia date, pedidos int, total numeric)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not public.es_admin() then
    raise exception 'Sólo la administración ve los reportes';
  end if;
  return query
  select (p.pagado_el at time zone 'America/Mexico_City')::date, count(*)::int, sum(p.total)
  from public.pedidos p
  where p.pagado_el is not null and p.estado <> 'cancelado'
    and (p.pagado_el at time zone 'America/Mexico_City')::date between p_desde and p_hasta
  group by 1
  order by 1;
end
$$;

create or replace function public.productos_mas_vendidos(p_desde date, p_hasta date, p_limite int default 5)
returns table (producto text, piezas int, importe numeric)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not public.es_admin() then
    raise exception 'Sólo la administración ve los reportes';
  end if;
  return query
  select i.nombre, sum(i.cantidad)::int, sum(i.importe)
  from public.pedido_items i
  join public.pedidos p on p.id = i.pedido_id
  where p.pagado_el is not null and p.estado <> 'cancelado'
    and (p.pagado_el at time zone 'America/Mexico_City')::date between p_desde and p_hasta
  group by i.nombre
  order by 2 desc, 3 desc
  limit greatest(p_limite, 1);
end
$$;
