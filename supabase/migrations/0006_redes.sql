-- Instagram y Facebook de la pastelería para los botones de contacto del sitio (HU-14).
-- El WhatsApp ya estaba en ajustes; la administración los escribe en Ajustes y el pie de la tienda los muestra.
alter table public.ajustes
  add column if not exists instagram text,
  add column if not exists facebook text;
