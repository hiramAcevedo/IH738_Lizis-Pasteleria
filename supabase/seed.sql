-- Lizis Pastelería · catálogo de prueba
-- Las familias son las de Proyecto V. Precios y fotografías son provisionales (fotos de Unsplash, licencia libre)
-- hasta que la propietaria entregue los suyos; se reemplazan desde el panel de administración.

insert into public.categorias (nombre, slug, descripcion, orden) values
  ('Roles de canela', 'roles-de-canela', 'La especialidad de la casa: masa suave, canela y glaseado.', 1),
  ('Brownies', 'brownies', 'Brownies de chocolate, húmedos por dentro.', 2),
  ('Galletas', 'galletas', 'Galletas horneadas el día de la entrega.', 3),
  ('Tartaletas', 'tartaletas', 'Base de mantequilla con rellenos de temporada.', 4),
  ('Temporada', 'temporada', 'Lo que se hornea sólo unas semanas al año.', 5);

with p as (
  insert into public.productos (categoria_id, nombre, slug, descripcion, ingredientes, alergenos, precio, imagen_url, destacado)
  select c.id, v.nombre, v.slug, v.descripcion, v.ingredientes, v.alergenos, v.precio,
         'https://images.unsplash.com/photo-' || v.foto || '?w=900&q=75&auto=format&fit=crop', v.destacado
  from (values
    ('roles-de-canela', 'Rol de canela clásico', 'rol-de-canela-clasico',
     'El rol de la casa: masa suave enrollada con canela y azúcar morena, cubierto de glaseado.',
     'Harina de trigo, mantequilla, leche, huevo, azúcar morena, canela, levadura, azúcar glass.', 'Gluten, lácteos, huevo.',
     45.00, '1686207855146-c3ffe2166d40', true),
    ('roles-de-canela', 'Rol de canela con nuez', 'rol-de-canela-con-nuez',
     'El clásico con nuez picada en el relleno y encima del glaseado.',
     'Harina de trigo, mantequilla, leche, huevo, azúcar morena, canela, nuez, levadura, azúcar glass.', 'Gluten, lácteos, huevo, nuez.',
     55.00, '1764281469526-e1c378515e6f', false),
    ('brownies', 'Brownie clásico', 'brownie-clasico',
     'Brownie de chocolate semiamargo, con costra delgada y centro húmedo.',
     'Chocolate semiamargo, mantequilla, azúcar, huevo, harina de trigo, cocoa.', 'Gluten, lácteos, huevo.',
     35.00, '1777647364657-2319b02095de', true),
    ('brownies', 'Brownie con nuez', 'brownie-con-nuez',
     'El brownie clásico con trozos de nuez tostada.',
     'Chocolate semiamargo, mantequilla, azúcar, huevo, harina de trigo, cocoa, nuez.', 'Gluten, lácteos, huevo, nuez.',
     40.00, '1636743715220-d8f8dd900b87', false),
    ('galletas', 'Galleta con chispas de chocolate', 'galleta-chispas-de-chocolate',
     'Galleta grande, dorada por fuera y suave por dentro, con chispas de chocolate.',
     'Harina de trigo, mantequilla, azúcar morena, huevo, chispas de chocolate, vainilla.', 'Gluten, lácteos, huevo.',
     25.00, '1782852232674-64bc7f102866', true),
    ('galletas', 'Galleta de avena', 'galleta-de-avena',
     'Galleta de avena con canela y un toque de piloncillo.',
     'Avena, harina de trigo, mantequilla, piloncillo, huevo, canela.', 'Gluten, lácteos, huevo.',
     22.00, '1600147573971-a2135dbff47e', false),
    ('tartaletas', 'Tartaleta de frutos rojos', 'tartaleta-de-frutos-rojos',
     'Base de mantequilla, crema pastelera y fresas, zarzamoras y moras azules.',
     'Harina de trigo, mantequilla, leche, huevo, azúcar, fresa, zarzamora, mora azul.', 'Gluten, lácteos, huevo.',
     55.00, '1620980776848-84ac10194945', true),
    ('tartaletas', 'Tartaleta de limón', 'tartaleta-de-limon',
     'Base de mantequilla con crema de limón, ácida y dulce a la vez.',
     'Harina de trigo, mantequilla, huevo, azúcar, limón.', 'Gluten, lácteos, huevo.',
     50.00, '1785695797215-4345de8ab06c', false),
    ('temporada', 'Rol de calabaza', 'rol-de-calabaza',
     'Masa con puré de calabaza, especias de otoño y glaseado de queso crema.',
     'Harina de trigo, calabaza, mantequilla, leche, huevo, azúcar morena, canela, nuez moscada, queso crema.', 'Gluten, lácteos, huevo.',
     55.00, '1766186157863-c6f5f55afe3c', false)
  ) as v (categoria, nombre, slug, descripcion, ingredientes, alergenos, precio, foto, destacado)
  join public.categorias c on c.slug = v.categoria
  returning id, slug
)
insert into public.variantes (producto_id, grupo, nombre, precio_extra, orden)
select p.id, v.grupo, v.nombre, v.extra, v.orden
from p
join (values
  ('rol-de-canela-clasico', 'Presentación', 'Pieza', 0, 1),
  ('rol-de-canela-clasico', 'Presentación', 'Caja de 4', 120, 2),
  ('rol-de-canela-clasico', 'Glaseado', 'Clásico', 0, 1),
  ('rol-de-canela-clasico', 'Glaseado', 'Queso crema', 10, 2),
  ('rol-de-canela-con-nuez', 'Presentación', 'Pieza', 0, 1),
  ('rol-de-canela-con-nuez', 'Presentación', 'Caja de 4', 150, 2),
  ('brownie-clasico', 'Presentación', 'Pieza', 0, 1),
  ('brownie-clasico', 'Presentación', 'Caja de 6', 150, 2),
  ('brownie-con-nuez', 'Presentación', 'Pieza', 0, 1),
  ('brownie-con-nuez', 'Presentación', 'Caja de 6', 180, 2),
  ('galleta-chispas-de-chocolate', 'Presentación', 'Pieza', 0, 1),
  ('galleta-chispas-de-chocolate', 'Presentación', 'Caja de 12', 215, 2),
  ('galleta-de-avena', 'Presentación', 'Pieza', 0, 1),
  ('galleta-de-avena', 'Presentación', 'Caja de 12', 190, 2),
  ('rol-de-calabaza', 'Presentación', 'Pieza', 0, 1),
  ('rol-de-calabaza', 'Presentación', 'Caja de 4', 150, 2)
) as v (slug, grupo, nombre, extra, orden) on v.slug = p.slug;
