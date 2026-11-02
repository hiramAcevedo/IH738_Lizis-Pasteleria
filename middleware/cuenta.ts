// Páginas del cliente: sin sesión, a iniciar sesión y de regreso a donde iba.
export default defineNuxtRouteMiddleware((to) => {
  const usuario = useSupabaseUser()
  if (!usuario.value) return navigateTo({ path: '/entrar', query: { volver: to.fullPath } })
})
