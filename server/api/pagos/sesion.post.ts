import { serverSupabaseClient, serverSupabaseUser } from '#supabase/server'

// Abre la página de pago de Stripe (Checkout) para un pedido pendiente del cliente que tiene la sesión.
// Los importes salen del pedido guardado en la base, no de lo que mande el navegador.
export default defineEventHandler(async (event) => {
  const usuario = await serverSupabaseUser(event).catch(() => null)
  if (!usuario) throw createError({ statusCode: 401, statusMessage: 'Inicia sesión para pagar' })
  const { folio } = await readBody<{ folio?: string }>(event)
  if (!folio) throw createError({ statusCode: 400, statusMessage: 'Falta el folio del pedido' })

  const supabase = await serverSupabaseClient(event)
  const { data: pedido } = await supabase
    .from('pedidos')
    .select('folio, estado, usuario_id, envio, total, pedido_items(nombre, detalle, precio_unitario, cantidad)')
    .eq('folio', folio)
    .maybeSingle()
  if (!pedido || pedido.usuario_id !== usuario.sub) throw createError({ statusCode: 404, statusMessage: 'Pedido no encontrado' })
  if (pedido.estado !== 'pendiente_pago') throw createError({ statusCode: 409, statusMessage: 'Este pedido ya no está pendiente de pago' })

  const centavos = (n: number | string) => Math.round(Number(n) * 100)
  const renglones = pedido.pedido_items.map((i: any) => ({
    quantity: i.cantidad,
    price_data: {
      currency: 'mxn',
      unit_amount: centavos(i.precio_unitario),
      product_data: { name: i.nombre, ...(i.detalle ? { description: i.detalle } : {}) }
    }
  }))
  if (Number(pedido.envio) > 0) {
    renglones.push({ quantity: 1, price_data: { currency: 'mxn', unit_amount: centavos(pedido.envio), product_data: { name: 'Envío a domicilio' } } })
  }

  const origen = getRequestURL(event).origin
  const sesion = await useStripe().checkout.sessions.create({
    mode: 'payment',
    locale: 'es-419',
    line_items: renglones,
    client_reference_id: pedido.folio,
    metadata: { folio: pedido.folio },
    customer_email: (usuario as any).email,
    success_url: `${origen}/pedido/${pedido.folio}?pago=exito&session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${origen}/pedido/${pedido.folio}?pago=cancelado`
  })
  return { url: sesion.url }
})
