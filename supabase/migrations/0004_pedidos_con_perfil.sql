-- El panel muestra el nombre del cliente junto a su pedido: pedidos y solicitudes apuntan también al perfil.
alter table public.pedidos
  add constraint pedidos_perfil_fk foreign key (usuario_id) references public.perfiles (id);
alter table public.solicitudes
  add constraint solicitudes_perfil_fk foreign key (usuario_id) references public.perfiles (id);
