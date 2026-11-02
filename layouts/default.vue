<script setup lang="ts">
const supabase = useSupabaseClient()
const usuario = useSupabaseUser()
const { perfil, cargar, esAdmin } = usePerfil()
const { piezas } = useCarrito()
const abierto = ref(false)
const route = useRoute()

await cargar()
watch(usuario, () => cargar())
watch(() => route.fullPath, () => (abierto.value = false))

async function salir() {
  await supabase.auth.signOut()
  perfil.value = null
  await navigateTo('/')
}
</script>

<template>
  <div>
    <header class="barra">
      <div class="contenedor">
        <NuxtLink to="/" class="logo"><b>Lizis</b><span>Pastelería</span></NuxtLink>
        <button class="hamburguesa" aria-label="Menú" @click="abierto = !abierto">☰</button>
        <nav class="menu" :class="{ abierto }">
          <NuxtLink to="/productos">Productos</NuxtLink>
          <NuxtLink to="/pastel-personalizado">Pastel personalizado</NuxtLink>
          <NuxtLink v-if="usuario" to="/mis-pedidos">Mis pedidos</NuxtLink>
          <NuxtLink v-if="esAdmin" to="/admin">Administración</NuxtLink>
          <NuxtLink to="/carrito">Carrito<ClientOnly><span v-if="piezas" class="carrito-cuenta">{{ piezas }}</span></ClientOnly></NuxtLink>
          <button v-if="usuario" class="enlace" @click="salir">Salir</button>
          <NuxtLink v-else to="/entrar">Entrar</NuxtLink>
        </nav>
      </div>
    </header>
    <main>
      <slot />
    </main>
    <footer class="pie">
      <div class="contenedor fila entre">
        <div>
          <b>Lizis Pastelería</b> · Repostería artesanal en Guadalajara, Jalisco<br>
          <span class="prueba">Versión de prueba: pagos en modo de prueba de Stripe; fotos y precios provisionales</span>
        </div>
        <div class="chico">Proyecto VI · Licenciatura en Desarrollo de Sistemas Web · UDG Virtual</div>
      </div>
    </footer>
  </div>
</template>
