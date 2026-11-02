import Stripe from 'stripe'

let cliente: Stripe | null = null

// Stripe en modo de prueba: sin llave sk_test_ configurada, el pago en línea responde 503 y el pedido queda pendiente.
export function useStripe() {
  const { stripeSecretKey } = useRuntimeConfig()
  if (!stripeSecretKey) throw createError({ statusCode: 503, statusMessage: 'El pago en línea no está configurado' })
  if (!stripeSecretKey.startsWith('sk_test_')) throw createError({ statusCode: 500, statusMessage: 'El prototipo sólo acepta llaves de prueba de Stripe' })
  cliente ??= new Stripe(stripeSecretKey)
  return cliente
}
