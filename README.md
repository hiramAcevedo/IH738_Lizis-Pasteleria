# Lizis Pastelería: tienda en línea y panel de pedidos

**Proyecto VI (IH738) | Universidad de Guadalajara, Sistema de Universidad Virtual**

El prototipo del sistema web de Lizis Pastelería, la repostería artesanal de Lizeth Echeagaray en Guadalajara. El cliente
consulta el catálogo, arma su carrito, programa la entrega, paga en línea y sigue su pedido; la propietaria administra
productos, pedidos, entregas, pasteles personalizados y ventas desde un panel.

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
| Despliegue | Vercel |

## Lo que hace

| Quién | Qué |
|-------|-----|
| Cliente | Catálogo por categorías con búsqueda; detalle con variantes (presentación, glaseado), ingredientes y alérgenos; carrito; registro e inicio de sesión; pedido con entrega a domicilio o recolección, día con lugar y horario; pago con Stripe; seguimiento del estado en Mis pedidos; solicitud de pastel personalizado con imagen de referencia y respuesta a la cotización |
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
Las fotos del catálogo de prueba son de Unsplash (licencia libre) y los precios son provisionales: los definitivos los
carga la propietaria desde el panel.

## Estructura

```
pages/            tienda (inicio, productos, carrito, pedido, mis pedidos, pastel personalizado) y admin/
layouts/          la tienda y el panel
middleware/       cuenta (cliente con sesión) y admin (rol de administración)
composables/      carrito, perfil, formatos y avisos
server/api/pagos/ abrir la sesión de Stripe y confirmar el pago al volver
supabase/         tablas, reglas de negocio, seguridad y catálogo de prueba
```
