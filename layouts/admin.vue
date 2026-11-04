<script setup lang="ts">
const supabase = useSupabaseClient()
const { perfil } = usePerfil()
const { paleta } = usePaleta()

async function salir() {
  await supabase.auth.signOut()
  perfil.value = null
  await navigateTo('/')
}
</script>

<template>
  <div class="panel">
    <aside class="lateral">
      <NuxtLink to="/admin" class="logo" aria-label="Administración de Lizis Pastelería"><img :src="paleta.logoPie" alt="Lizis Pastelería" width="440" height="600"></NuxtLink>
      <div class="papel">Administración</div>
      <nav>
        <NuxtLink to="/admin">Resumen</NuxtLink>
        <NuxtLink to="/admin/pedidos">Pedidos</NuxtLink>
        <NuxtLink to="/admin/agenda">Agenda de entregas</NuxtLink>
        <NuxtLink to="/admin/personalizados">Pasteles personalizados</NuxtLink>
        <NuxtLink to="/admin/productos">Productos</NuxtLink>
        <NuxtLink to="/admin/reportes">Reportes de ventas</NuxtLink>
        <NuxtLink to="/admin/ajustes">Ajustes</NuxtLink>
        <NuxtLink to="/">Ver la tienda</NuxtLink>
      </nav>
      <div class="salir">{{ perfil?.nombre }} · <a href="#" style="color: inherit" @click.prevent="salir">Salir</a></div>
    </aside>
    <section class="trabajo">
      <slot />
    </section>
  </div>
</template>
