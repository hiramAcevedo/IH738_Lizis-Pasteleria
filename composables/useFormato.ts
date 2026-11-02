const pesos = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' })

export const ESTADOS: Record<string, string> = {
  pendiente_pago: 'Pendiente de pago',
  pagado: 'Pagado',
  en_preparacion: 'En preparación',
  listo: 'Listo',
  entregado: 'Entregado',
  cancelado: 'Cancelado',
  recibida: 'Recibida',
  cotizada: 'Cotizada',
  aceptada: 'Aceptada',
  rechazada: 'Rechazada'
}

export function dinero(n: number | string | null | undefined) {
  return pesos.format(Number(n ?? 0))
}

// Las fechas de la base llegan como 'AAAA-MM-DD'; se leen como fecha local para que no se corran un día.
export function fechaLarga(iso: string | null | undefined) {
  if (!iso) return ''
  const [a, m, d] = iso.slice(0, 10).split('-').map(Number)
  return new Intl.DateTimeFormat('es-MX', { weekday: 'long', day: 'numeric', month: 'long' }).format(new Date(a, m - 1, d))
}

export function fechaCorta(iso: string | null | undefined) {
  if (!iso) return ''
  const [a, m, d] = iso.slice(0, 10).split('-').map(Number)
  return new Intl.DateTimeFormat('es-MX', { day: 'numeric', month: 'short', year: 'numeric' }).format(new Date(a, m - 1, d))
}

export function fechaHora(iso: string | null | undefined) {
  if (!iso) return ''
  return new Intl.DateTimeFormat('es-MX', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'America/Mexico_City' }).format(new Date(iso))
}

export function hoyMx() {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Mexico_City' }).format(new Date())
}

// Los errores de las funciones de la base ya vienen en español; los de Auth se traducen aquí.
export function mensajeDeError(e: any) {
  const m = String(e?.message ?? e ?? 'Algo salió mal')
  if (m.includes('Invalid login credentials')) return 'Correo o contraseña incorrectos'
  if (m.includes('User already registered')) return 'Ya existe una cuenta con ese correo'
  if (m.includes('Password should be')) return 'La contraseña debe tener al menos 8 caracteres'
  if (m.includes('Email not confirmed')) return 'Confirma tu correo antes de entrar'
  if (m.includes('is invalid')) return 'Ese correo no es válido'
  return m
}
