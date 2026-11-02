-- Lizis Pastelería · tablas del prototipo (Proyecto VI, 4.2)
-- Modelo de Proyecto V: perfiles de usuario, categorías, productos con variantes, pedidos con sus renglones,
-- solicitudes de pastel personalizado y los ajustes de producción que define la propietaria.

create table public.perfiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nombre text not null default '',
  telefono text,
  rol text not null default 'cliente' check (rol in ('cliente', 'admin')),
  creado_el timestamptz not null default now()
);

create table public.categorias (
  id bigint generated always as identity primary key,
  nombre text not null unique,
  slug text not null unique,
  descripcion text not null default '',
  orden int not null default 0
);

create table public.productos (
  id bigint generated always as identity primary key,
  categoria_id bigint not null references public.categorias (id),
  nombre text not null,
  slug text not null unique,
  descripcion text not null default '',
  ingredientes text not null default '',
  alergenos text not null default '',
  precio numeric(10, 2) not null check (precio >= 0),
  imagen_url text,
  visible boolean not null default true,
  destacado boolean not null default false,
  creado_el timestamptz not null default now()
);
create index productos_categoria_idx on public.productos (categoria_id);

-- Una variante pertenece a un grupo (Presentación, Glaseado...): el cliente elige una por grupo.
create table public.variantes (
  id bigint generated always as identity primary key,
  producto_id bigint not null references public.productos (id) on delete cascade,
  grupo text not null,
  nombre text not null,
  precio_extra numeric(10, 2) not null default 0 check (precio_extra >= 0),
  orden int not null default 0
);
create index variantes_producto_idx on public.variantes (producto_id);

-- Las reglas de producción: días de anticipación, pedidos por día, horarios y costo de envío.
create table public.ajustes (
  id int primary key default 1 check (id = 1),
  dias_anticipacion int not null default 2 check (dias_anticipacion between 0 and 30),
  capacidad_diaria int not null default 6 check (capacidad_diaria between 1 and 100),
  horarios text[] not null default array['10:00 a 12:00', '12:00 a 14:00', '16:00 a 18:00'],
  costo_envio numeric(10, 2) not null default 60 check (costo_envio >= 0),
  whatsapp text
);
insert into public.ajustes (id) values (1);

create table public.pedidos (
  id bigint generated always as identity primary key,
  folio text not null unique default (
    'LZ-' || to_char(now() at time zone 'America/Mexico_City', 'YYMMDD') || '-' ||
    upper(substr(md5(gen_random_uuid()::text), 1, 4))
  ),
  usuario_id uuid not null references auth.users (id),
  estado text not null default 'pendiente_pago'
    check (estado in ('pendiente_pago', 'pagado', 'en_preparacion', 'listo', 'entregado', 'cancelado')),
  modalidad text not null check (modalidad in ('entrega', 'recoleccion')),
  fecha_entrega date not null,
  horario text not null,
  direccion text,
  telefono text not null,
  notas text,
  subtotal numeric(10, 2) not null default 0,
  envio numeric(10, 2) not null default 0,
  total numeric(10, 2) not null default 0,
  stripe_sesion text,
  pagado_el timestamptz,
  creado_el timestamptz not null default now()
);
create index pedidos_usuario_idx on public.pedidos (usuario_id);
create index pedidos_fecha_idx on public.pedidos (fecha_entrega);
create index pedidos_estado_idx on public.pedidos (estado);

-- El renglón guarda nombre y precio del momento de la compra: si el catálogo cambia, el pedido no.
create table public.pedido_items (
  id bigint generated always as identity primary key,
  pedido_id bigint not null references public.pedidos (id) on delete cascade,
  producto_id bigint references public.productos (id) on delete set null,
  nombre text not null,
  detalle text not null default '',
  precio_unitario numeric(10, 2) not null,
  cantidad int not null check (cantidad between 1 and 50),
  importe numeric(10, 2) not null
);
create index pedido_items_pedido_idx on public.pedido_items (pedido_id);

create table public.historial_estados (
  id bigint generated always as identity primary key,
  pedido_id bigint not null references public.pedidos (id) on delete cascade,
  estado text not null,
  usuario_id uuid references auth.users (id) on delete set null,
  creado_el timestamptz not null default now()
);
create index historial_pedido_idx on public.historial_estados (pedido_id);

create table public.solicitudes (
  id bigint generated always as identity primary key,
  folio text not null unique default (
    'PP-' || to_char(now() at time zone 'America/Mexico_City', 'YYMMDD') || '-' ||
    upper(substr(md5(gen_random_uuid()::text), 1, 4))
  ),
  usuario_id uuid not null default auth.uid() references auth.users (id),
  ocasion text not null default '',
  tamano text not null,
  sabor text not null,
  decoracion text not null,
  mensaje text not null default '',
  imagen_ref text,
  fecha_deseada date not null,
  telefono text not null,
  estado text not null default 'recibida' check (estado in ('recibida', 'cotizada', 'aceptada', 'rechazada')),
  cotizacion numeric(10, 2) check (cotizacion >= 0),
  respuesta text,
  creado_el timestamptz not null default now()
);
create index solicitudes_usuario_idx on public.solicitudes (usuario_id);
