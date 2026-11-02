// El panel sólo abre con una cuenta de rol admin. La base lo vuelve a comprobar en cada consulta (RLS).
export default defineNuxtRouteMiddleware(async (to) => {
  const usuario = useSupabaseUser()
  if (!usuario.value) return navigateTo({ path: '/entrar', query: { volver: to.fullPath } })
  const { cargar } = usePerfil()
  const perfil = await cargar()
  if (perfil?.rol !== 'admin') return navigateTo('/')
})
