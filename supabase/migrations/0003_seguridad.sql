-- Lizis Pastelería · quién ve y quién cambia qué (Row Level Security y Storage)
-- El catálogo es público; cada cliente ve sólo lo suyo; la administración ve y cambia todo.
-- Los pedidos no se escriben directo: sólo por las funciones de 0002, que calculan precios y validan.

alter table public.perfiles enable row level security;
alter table public.categorias enable row level security;
alter table public.productos enable row level security;
alter table public.variantes enable row level security;
alter table public.ajustes enable row level security;
alter table public.pedidos enable row level security;
alter table public.pedido_items enable row level security;
alter table public.historial_estados enable row level security;
alter table public.solicitudes enable row level security;

-- Perfiles: el propio y, para la administración, todos. El rol no lo cambia el cliente.
create policy "perfil propio o administración" on public.perfiles
  for select to authenticated using (id = (select auth.uid()) or public.es_admin());
create policy "editar perfil propio" on public.perfiles
  for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
revoke update on public.perfiles from anon, authenticated;
grant update (nombre, telefono) on public.perfiles to authenticated;

-- Catálogo.
create policy "categorías públicas" on public.categorias
  for select to anon, authenticated using (true);
create policy "administración de categorías" on public.categorias
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

create policy "productos visibles" on public.productos
  for select to anon, authenticated using (visible or public.es_admin());
create policy "administración de productos" on public.productos
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

create policy "variantes públicas" on public.variantes
  for select to anon, authenticated using (true);
create policy "administración de variantes" on public.variantes
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

create policy "ajustes públicos" on public.ajustes
  for select to anon, authenticated using (true);
create policy "administración de ajustes" on public.ajustes
  for update to authenticated using (public.es_admin()) with check (public.es_admin());

-- Pedidos: lectura del propio o de la administración; la escritura va por funciones.
create policy "pedido propio o administración" on public.pedidos
  for select to authenticated using (usuario_id = (select auth.uid()) or public.es_admin());
create policy "renglones del pedido propio o administración" on public.pedido_items
  for select to authenticated using (
    exists (select 1 from public.pedidos p where p.id = pedido_id and (p.usuario_id = (select auth.uid()) or public.es_admin()))
  );
create policy "historial del pedido propio o administración" on public.historial_estados
  for select to authenticated using (
    exists (select 1 from public.pedidos p where p.id = pedido_id and (p.usuario_id = (select auth.uid()) or public.es_admin()))
  );

-- Pasteles personalizados: el cliente registra y ve los suyos; la administración cotiza.
create policy "registrar solicitud propia" on public.solicitudes
  for insert to authenticated with check (usuario_id = (select auth.uid()) and estado = 'recibida' and cotizacion is null);
create policy "solicitud propia o administración" on public.solicitudes
  for select to authenticated using (usuario_id = (select auth.uid()) or public.es_admin());
create policy "administración cotiza" on public.solicitudes
  for update to authenticated using (public.es_admin()) with check (public.es_admin());

-- La clave del servidor sólo se valida dentro de confirmar_pago.
revoke execute on function public.confirmar_pago(text, text, text) from public, anon;
grant execute on function public.confirmar_pago(text, text, text) to authenticated;

-- Storage: fotos del catálogo (públicas, las sube la administración) e imágenes de referencia (privadas,
-- cada cliente en su carpeta).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('productos', 'productos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('referencias', 'referencias', false, 5242880, array['image/jpeg', 'image/png', 'image/webp']);

create policy "administración sube fotos" on storage.objects
  for insert to authenticated with check (bucket_id = 'productos' and public.es_admin());
create policy "administración cambia fotos" on storage.objects
  for update to authenticated using (bucket_id = 'productos' and public.es_admin());
create policy "administración borra fotos" on storage.objects
  for delete to authenticated using (bucket_id = 'productos' and public.es_admin());
create policy "cliente sube su referencia" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'referencias' and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "referencia propia o administración" on storage.objects
  for select to authenticated using (
    bucket_id = 'referencias' and ((storage.foldername(name))[1] = (select auth.uid())::text or public.es_admin())
  );
