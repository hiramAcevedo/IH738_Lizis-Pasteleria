# Lizis Pastelería: tienda en línea y panel de pedidos

**Proyecto VI (IH738) | Universidad de Guadalajara, Sistema de Universidad Virtual**

El prototipo del sistema web de Lizis Pastelería, la repostería artesanal de Lizeth Echeagaray en Guadalajara. El cliente
consulta el catálogo, arma su carrito, programa la entrega, paga en línea y sigue su pedido; la propietaria administra
productos, pedidos, entregas, pasteles personalizados y ventas desde un panel.

Publicado en https://lizispasteleria.shop

## Equipo

| Rol | Integrante |
|-----|------------|
| Product Owner y desarrolladora | Esmeralda del Socorro Orozco Díaz |
| Scrum Master y desarrollador | Hiram Agustín Acevedo López |
| Desarrolladora | Esthephany Alcantar García |

**Asesora:** Rocío Belén Rubio Treviño

## Stack

El que el equipo eligió en Proyecto V.

| Capa | Tecnología |
|------|-----------|
| Vista y lógica | Nuxt 3 (Vue.js) con rutas de servidor |
| Datos | PostgreSQL en Supabase, con Row Level Security |
| Cuentas | Supabase Auth (correo y contraseña) |
| Fotos | Supabase Storage |
| Pagos | Stripe Checkout en modo de prueba |
| Correo | Resend, desde el dominio de la tienda |
| Despliegue | Vercel |

## Lo que hace

| Quién | Qué |
|-------|-----|
| Cliente | Catálogo por categorías con búsqueda; detalle con variantes (presentación, glaseado), ingredientes y alérgenos; carrito; registro con confirmación por correo, inicio de sesión y recuperación de la contraseña; correo de confirmación al pagar; pedido con entrega a domicilio o recolección, día con lugar y horario; pago con Stripe; seguimiento del estado en Mis pedidos; solicitud de pastel personalizado con imagen de referencia y respuesta a la cotización |
| Propietaria | Resumen del día; pedidos por estado con su avance (pagado, en preparación, listo, entregado o cancelado) y aviso al cliente por WhatsApp; agenda de entregas por día; cotización de pasteles personalizados; alta, edición y ocultamiento de productos con foto y variantes; reportes de ventas por periodo y productos más vendidos; ajustes de anticipación, cupo diario, horarios y envío |

Las reglas que no pueden quedar en el navegador viven en la base (`supabase/migrations/`): el precio de cada renglón se
calcula con el catálogo, el cupo del día se revisa al registrar el pedido, los estados sólo avanzan en orden y cada
cliente ve sólo sus pedidos. El pago se confirma en el servidor consultando la sesión en Stripe; la tienda no guarda
datos de tarjetas.

## Cómo se corre

```bash
pnpm install
cp .env.example .env    # URL y llave publicable de Supabase, clave del servidor y llave de prueba de Stripe
pnpm dev                # http://localhost:3738
```

La base se arma con los archivos de `supabase/migrations/` en orden y el catálogo de prueba con `supabase/seed.sql`.
La paleta de color se prueba en `/paletas` (o con `?paleta=coral`, `cafe`, `cacao` o `galleta`) y cambia todo el
sitio, también la cuenta del cliente y el panel de administración: la lista está en `composables/usePaleta.ts` y los
valores en `assets/css/main.css`.
Las fotos del catálogo son de la pastelería en los productos que ya las tienen y de Unsplash (licencia libre) en los
demás; los precios son provisionales: los definitivos, con sus fotos, los carga la propietaria desde el panel.
Las fotos y los logotipos de `public/` se sirven en WebP con `srcset`, del ancho que muestra cada pantalla: al agregar o
cambiar una, `uv run scripts/imagenes.py` rehace sus variantes y `composables/imagenes.json`. Lora y Jost se sirven desde
el sitio (`assets/fonts/`), sin pedirlas a Google Fonts.

## Correos

Salen de `lizispasteleria.shop`, verificado en Resend.

- **Confirmación de compra.** La manda la ruta que confirma el pago (`server/api/pagos/confirmar.post.ts`) cuando el pedido
  queda pagado, con el folio, los productos, el total, el día y la forma de entrega. Necesita `RESEND_API_KEY` en las
  variables del entorno; sin ella el pago se confirma igual y el correo no sale. El remitente es
  `Lizis Pastelería <pedidos@lizispasteleria.shop>` (se cambia con `CORREO_REMITENTE`).
- **Confirmar la cuenta y recuperar la contraseña.** Los manda Supabase Auth por el SMTP de Resend. Las plantillas están
  en `supabase/plantillas/` y se pegan en Authentication > Emails:

  | Plantilla | Asunto | Archivo |
  |---|---|---|
  | Confirm signup | Confirma tu cuenta de Lizis Pastelería | `confirmar-cuenta.html` |
  | Reset password | Restablece tu contraseña de Lizis Pastelería | `recuperar-contrasena.html` |

  Sus enlaces llevan a `/entrar?token_hash=…`, que confirma la cuenta o pide la contraseña nueva, y funcionan aunque el
  correo se abra en otro dispositivo. En Supabase: Site URL `https://lizispasteleria.shop` y, en las URL de regreso,
  `https://lizispasteleria.shop/**` y `http://localhost:3738/**`. SMTP: `smtp.resend.com`, puerto 465, usuario `resend`
  y la llave de Resend como contraseña; remitente `pedidos@lizispasteleria.shop`, nombre "Lizis Pastelería".

## Estructura

```
pages/            tienda (inicio, productos, carrito, pedido, mis pedidos, pastel personalizado) y admin/
layouts/          la tienda y el panel
middleware/       cuenta (cliente con sesión) y admin (rol de administración)
composables/      carrito, perfil, formatos, avisos e imágenes con srcset
server/api/pagos/ abrir la sesión de Stripe y confirmar el pago al volver, con el correo de confirmación
server/utils/     Stripe y el envío de correos con Resend
supabase/         tablas, reglas de negocio, seguridad, catálogo de prueba y plantillas de correo de Auth
scripts/          variantes WebP de las fotos y los logotipos de public/
```
