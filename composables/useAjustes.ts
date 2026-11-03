// Los ajustes que la tienda muestra en todas las páginas: anticipación, cupo, horarios, envío y los contactos de la pastelería.
export function useAjustes() {
  const supabase = useSupabaseClient()
  return useAsyncData('ajustes-tienda', async () => {
    const { data } = await supabase
      .from('ajustes')
      .select('dias_anticipacion, capacidad_diaria, horarios, costo_envio, whatsapp, instagram, facebook')
      .eq('id', 1)
      .single()
    return data
  })
}

// Ligas de contacto a partir de lo que la administración escribe en Ajustes (teléfono de 10 dígitos, usuario o dirección completa).
export function ligasDeContacto(a: { whatsapp?: string | null; instagram?: string | null; facebook?: string | null } | null) {
  const digitos = (a?.whatsapp ?? '').replace(/\D/g, '')
  const usuario = (v?: string | null) => (v ?? '').trim().replace(/^@/, '')
  const red = (v: string | null | undefined, base: string) => {
    const u = usuario(v)
    if (!u) return ''
    return /^https?:\/\//.test(u) ? u : `${base}${u}`
  }
  return {
    whatsapp: digitos ? `https://wa.me/${digitos.length === 10 ? '52' + digitos : digitos}` : '',
    instagram: red(a?.instagram, 'https://www.instagram.com/'),
    facebook: red(a?.facebook, 'https://www.facebook.com/')
  }
}
