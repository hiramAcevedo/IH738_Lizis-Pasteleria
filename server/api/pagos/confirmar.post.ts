import { serverSupabaseClient, serverSupabaseUser } from '#supabase/server'

// Al volver de Stripe: se consulta la sesión en Stripe y sólo si está pagada, es de este pedido y cobra su total,
// el pedido pasa a «pagado» con la clave del servidor.
export default defineEventHandler(async (event) => {
  const usuario = await serverSupabaseUser(event).catch(() => null)
  if (!usuario) throw createError({ statusCode: 401, statusMessage: 'Inicia sesión' })
  const { folio, session_id } = await readBody<{ folio?: string; session_id?: string }>(event)
  if (!folio || !session_id) throw createError({ statusCode: 400, statusMessage: 'Faltan datos del pago' })

  const supabase = await serverSupabaseClient<any>(event)
  const { data: pedido } = await supabase.from('pedidos').select('folio, estado, usuario_id, total').eq('folio', folio).maybeSingle()
  if (!pedido || pedido.usuario_id !== usuario.sub) throw createError({ statusCode: 404, statusMessage: 'Pedido no encontrado' })
  if (pedido.estado !== 'pendiente_pago') return { estado: pedido.estado }

  const sesion = await useStripe().checkout.sessions.retrieve(session_id)
  if (sesion.client_reference_id !== folio) throw createError({ statusCode: 400, statusMessage: 'El pago no corresponde a este pedido' })
  if (sesion.payment_status !== 'paid') return { estado: pedido.estado }
  if (sesion.amount_total !== Math.round(Number(pedido.total) * 100)) {
    throw createError({ statusCode: 400, statusMessage: 'El importe cobrado no coincide con el pedido' })
  }

  const { claveServidor } = useRuntimeConfig()
  const { data: estado, error } = await supabase.rpc('confirmar_pago', { p_folio: folio, p_sesion: session_id, p_clave: claveServidor })
  if (error) throw createError({ statusCode: 500, statusMessage: error.message })
  return { estado }
})
