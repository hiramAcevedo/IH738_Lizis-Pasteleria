import { getRequestURL, type H3Event } from 'h3'
import { enviarCorreo, escaparHtml, type ResultadoCorreo } from './correo'

// El correo de confirmación de compra: sale una vez, cuando la ruta que confirma el pago deja el pedido en «pagado».
// Lleva el folio, los productos, el total, el día y la forma de entrega, con la paleta Café de la tienda.

export interface PedidoCorreo {
  folio: string
  modalidad: string
  fecha_entrega: string
  horario: string
  direccion: string | null
  subtotal: number | string
  envio: number | string
  total: number | string
  pedido_items: { nombre: string; detalle: string | null; cantidad: number; importe: number | string }[]
}

const COLOR = {
  crema: '#fcf4e4',
  galleta: '#f6e3c9',
  cafe: '#9a644b',
  cacao: '#542624',
  texto: '#5f544b',
  suave: '#6e6258',
  rotulo: '#85543d',
  linea: '#ecdcc8'
}
const SERIF = "Lora, Georgia, 'Times New Roman', serif"
const SANS = "Jost, 'Helvetica Neue', Arial, sans-serif"

const pesos = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' })
const dinero = (n: number | string) => pesos.format(Number(n ?? 0))

// 'AAAA-MM-DD' es un día del calendario: se lee sin zona horaria para que no se corra un día (igual que en la tienda).
function fechaLarga(iso: string) {
  const [a, m, d] = iso.slice(0, 10).split('-').map(Number)
  return new Intl.DateTimeFormat('es-MX', { weekday: 'long', day: 'numeric', month: 'long', timeZone: 'UTC' }).format(new Date(Date.UTC(a, m - 1, d)))
}

const MODALIDAD: Record<string, string> = { entrega: 'Entrega a domicilio', recoleccion: 'Recolección' }

export function correoPedidoPagado({ pedido, nombre, origen }: { pedido: PedidoCorreo; nombre?: string | null; origen: string }) {
  const e = escaparHtml
  const saludo = nombre?.trim() ? `Gracias por tu pedido, ${nombre.trim()}` : 'Gracias por tu pedido'
  const dia = fechaLarga(pedido.fecha_entrega)
  const modalidad = MODALIDAD[pedido.modalidad] ?? pedido.modalidad
  const envio = Number(pedido.envio) > 0 ? dinero(pedido.envio) : 'Sin costo'
  const liga = `${origen}/pedido/${encodeURIComponent(pedido.folio)}`
  const asunto = `Tu pedido ${pedido.folio} está confirmado`

  const entrega: [string, string][] = [['Día', dia], ['Horario', pedido.horario]]
  if (pedido.modalidad === 'entrega' && pedido.direccion) entrega.push(['Dirección', pedido.direccion])

  const filasEntrega = entrega
    .map(([rotulo, valor]) => `
                <tr>
                  <td style="padding:4px 0;width:92px;vertical-align:top;font-size:13px;color:${COLOR.rotulo};">${rotulo}</td>
                  <td style="padding:4px 0;font-size:15px;color:${COLOR.cacao};">${e(valor)}</td>
                </tr>`)
    .join('')

  const filasProductos = pedido.pedido_items
    .map((i) => `
            <tr>
              <td style="padding:10px 0;border-bottom:1px solid ${COLOR.linea};vertical-align:top;">
                <span style="font-size:15px;font-weight:600;color:${COLOR.cacao};">${i.cantidad} × ${e(i.nombre)}</span>
                ${i.detalle ? `<br><span style="font-size:13px;color:${COLOR.suave};">${e(i.detalle)}</span>` : ''}
              </td>
              <td align="right" style="padding:10px 0 10px 12px;border-bottom:1px solid ${COLOR.linea};vertical-align:top;white-space:nowrap;font-size:15px;color:${COLOR.cacao};">${dinero(i.importe)}</td>
            </tr>`)
    .join('')

  const html = `<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${e(asunto)}</title>
</head>
<body style="margin:0;padding:0;background:${COLOR.crema};font-family:${SANS};color:${COLOR.texto};">
  <span style="display:none;max-height:0;overflow:hidden;opacity:0;">Recibimos tu pago. ${e(modalidad)} el ${e(dia)}, de ${e(pedido.horario)}.</span>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${COLOR.crema};padding:24px 0;">
    <tr><td align="center" style="padding:0 12px;">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="width:100%;max-width:600px;background:#ffffff;border:1px solid ${COLOR.linea};border-radius:14px;overflow:hidden;">
        <tr><td align="center" style="background:${COLOR.cafe};padding:18px 32px;">
          <img src="${origen}/marca/logo-lizis-blanco.png" width="64" height="88" alt="Lizis Pastelería" style="display:block;border:0;width:64px;height:88px;color:#ffffff;font-family:${SERIF};font-size:20px;">
        </td></tr>
        <tr><td style="padding:32px 32px 8px;">
          <p style="margin:0 0 6px;font-size:14px;color:${COLOR.rotulo};">Folio de tu pedido</p>
          <p style="margin:0;font-family:'Courier New',Courier,monospace;font-size:30px;font-weight:bold;letter-spacing:1px;color:${COLOR.cacao};">${e(pedido.folio)}</p>
          <h1 style="margin:24px 0 8px;font-family:${SERIF};font-size:26px;font-weight:500;line-height:1.2;color:${COLOR.cacao};">${e(saludo)}</h1>
          <p style="margin:0;font-size:15px;line-height:1.6;">Recibimos tu pago y tu pedido ya está en la lista de la pastelería. Puedes ver cómo avanza en Mis pedidos.</p>
        </td></tr>
        <tr><td style="padding:16px 32px 4px;">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${COLOR.galleta};border-radius:10px;">
            <tr><td style="padding:16px 20px;">
              <p style="margin:0 0 8px;font-family:${SERIF};font-size:18px;color:${COLOR.cacao};">${e(modalidad)}</p>
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">${filasEntrega}
              </table>
            </td></tr>
          </table>
        </td></tr>
        <tr><td style="padding:12px 32px 8px;">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0">${filasProductos}
            <tr>
              <td style="padding:12px 0 4px;font-size:14px;color:${COLOR.suave};">Subtotal</td>
              <td align="right" style="padding:12px 0 4px;font-size:14px;color:${COLOR.suave};">${dinero(pedido.subtotal)}</td>
            </tr>
            <tr>
              <td style="padding:4px 0 12px;font-size:14px;color:${COLOR.suave};">Envío</td>
              <td align="right" style="padding:4px 0 12px;font-size:14px;color:${COLOR.suave};">${envio}</td>
            </tr>
            <tr>
              <td style="padding:12px 0;border-top:2px solid ${COLOR.cacao};font-size:18px;font-weight:bold;color:${COLOR.cacao};">Total</td>
              <td align="right" style="padding:12px 0;border-top:2px solid ${COLOR.cacao};font-size:18px;font-weight:bold;color:${COLOR.cacao};">${dinero(pedido.total)}</td>
            </tr>
          </table>
        </td></tr>
        <tr><td style="padding:8px 32px 32px;">
          <a href="${e(liga)}" style="display:block;text-align:center;background:${COLOR.cafe};color:#ffffff;text-decoration:none;font-weight:600;font-size:16px;padding:14px;border-radius:10px;">Ver mi pedido</a>
        </td></tr>
        <tr><td style="background:${COLOR.crema};padding:20px 32px;font-size:12px;line-height:1.6;color:${COLOR.suave};">
          Pagos con Stripe en modo de prueba del prototipo: no se hizo ningún cargo real.<br>
          Lizis Pastelería · Guadalajara, Jalisco · <a href="mailto:contacto@lizispasteleria.shop" style="color:${COLOR.rotulo};">contacto@lizispasteleria.shop</a>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`

  const texto = [
    'Lizis Pastelería',
    '',
    `${saludo}.`,
    `Folio: ${pedido.folio}`,
    'Recibimos tu pago y tu pedido ya está en la lista de la pastelería.',
    '',
    modalidad,
    ...entrega.map(([rotulo, valor]) => `${rotulo}: ${valor}`),
    '',
    ...pedido.pedido_items.map((i) => `${i.cantidad} × ${i.nombre}${i.detalle ? ` (${i.detalle})` : ''}: ${dinero(i.importe)}`),
    `Subtotal: ${dinero(pedido.subtotal)}`,
    `Envío: ${envio}`,
    `Total: ${dinero(pedido.total)}`,
    '',
    `Ver mi pedido: ${liga}`,
    '',
    'Pagos con Stripe en modo de prueba del prototipo: no se hizo ningún cargo real.',
    'Lizis Pastelería · Guadalajara, Jalisco · contacto@lizispasteleria.shop'
  ].join('\n')

  return { asunto, html, texto }
}

// Lee el pedido ya pagado y el nombre del perfil con la sesión del cliente y manda el correo.
// Nunca lanza: un correo que no sale no deshace un pago confirmado.
export async function avisarPedidoPagado(
  event: H3Event,
  supabase: any,
  folio: string,
  usuario: { sub: string; email?: string }
): Promise<ResultadoCorreo> {
  try {
    if (!usuario.email) return 'fallo'
    const [{ data: pedido }, { data: perfil }] = await Promise.all([
      supabase
        .from('pedidos')
        .select('folio, modalidad, fecha_entrega, horario, direccion, subtotal, envio, total, pedido_items(id, nombre, detalle, cantidad, importe)')
        .eq('folio', folio)
        .order('id', { referencedTable: 'pedido_items', ascending: true })
        .maybeSingle(),
      supabase.from('perfiles').select('nombre').eq('id', usuario.sub).maybeSingle()
    ])
    if (!pedido) {
      console.error(`[correo] No se encontró el pedido ${folio} para su confirmación`)
      return 'fallo'
    }
    const mensaje = correoPedidoPagado({ pedido: pedido as PedidoCorreo, nombre: perfil?.nombre, origen: getRequestURL(event).origin })
    return await enviarCorreo({ para: usuario.email, ...mensaje, llave: `pedido-pagado-${folio}` })
  } catch (e) {
    console.error(`[correo] La confirmación del pedido ${folio} no salió:`, e)
    return 'fallo'
  }
}
