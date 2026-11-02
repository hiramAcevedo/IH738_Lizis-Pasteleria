// El perfil de la cuenta (nombre, teléfono y rol). Se carga una vez por sesión.
export function usePerfil() {
  const supabase = useSupabaseClient()
  const usuario = useSupabaseUser()
  const perfil = useState<{ id: string; nombre: string; telefono: string | null; rol: string } | null>('perfil', () => null)

  async function cargar() {
    const id = (usuario.value as any)?.sub ?? (usuario.value as any)?.id
    if (!id) {
      perfil.value = null
      return null
    }
    if (perfil.value?.id === id) return perfil.value
    const { data } = await supabase.from('perfiles').select('id, nombre, telefono, rol').eq('id', id).maybeSingle()
    perfil.value = data
    return data
  }

  const esAdmin = computed(() => perfil.value?.rol === 'admin')
  return { perfil, cargar, esAdmin }
}
