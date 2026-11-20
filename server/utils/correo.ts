// Envío de correos con Resend desde el dominio de la tienda (lizispasteleria.shop, verificado en Resend).
// La llave va en la variable de entorno RESEND_API_KEY; sin ella el correo no sale y el resto sigue igual.
const RESEND_URL = 'https://api.resend.com/emails'
export const REMITENTE = 'Lizis Pastelería <pedidos@lizispasteleria.shop>'

export type ResultadoCorreo = 'enviado' | 'repetido' | 'sin-llave' | 'fallo'

export interface Correo {
  para: string
  asunto: string
  html: string
  texto: string
  // Resend descarta un segundo envío con la misma llave durante 24 horas: un reintento no duplica el correo.
  llave: string
}

export async function enviarCorreo(correo: Correo): Promise<ResultadoCorreo> {
  const clave = process.env.RESEND_API_KEY
  if (!clave) {
    console.warn(`[correo] Sin RESEND_API_KEY; no se envió «${correo.asunto}»`)
    return 'sin-llave'
  }
  try {
    const respuesta = await $fetch.raw(RESEND_URL, {
      method: 'POST',
      headers: { Authorization: `Bearer ${clave}`, 'Idempotency-Key': correo.llave },
      body: {
        from: process.env.CORREO_REMITENTE || REMITENTE,
        to: [correo.para],
        subject: correo.asunto,
        html: correo.html,
        text: correo.texto
      },
      timeout: 10000,
      ignoreResponseError: true
    })
    if (respuesta.ok) return 'enviado'
    // 409: otra petición con la misma llave ya lo envió o lo está enviando.
    if (respuesta.status === 409) return 'repetido'
    console.error('[correo] Resend respondió', respuesta.status, JSON.stringify(respuesta._data))
    return 'fallo'
  } catch (e) {
    console.error('[correo] No se pudo llamar a Resend:', e)
    return 'fallo'
  }
}

// Lo que escribe el cliente (nombre, dirección, notas) se escapa antes de ir al HTML del correo.
export function escaparHtml(texto: unknown) {
  return String(texto ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}
