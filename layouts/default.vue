<script setup lang="ts">
import { dinero } from '~/composables/useFormato'

const supabase = useSupabaseClient()
const usuario = useSupabaseUser()
const { perfil, cargar, esAdmin } = usePerfil()
const { piezas } = useCarrito()
const { data: ajustes } = await useAjustes()
const abierto = ref(false)
const route = useRoute()

await cargar()
watch(usuario, () => cargar())
watch(() => route.fullPath, () => (abierto.value = false))

// En el inicio el encabezado queda transparente sobre la capa de la portada hasta que se baja un poco.
const arriba = ref(true)
const sobrePortada = computed(() => route.path === '/' && arriba.value)
function medir() { arriba.value = window.scrollY < 40 }
onMounted(() => { medir(); window.addEventListener('scroll', medir, { passive: true }) })
onBeforeUnmount(() => window.removeEventListener('scroll', medir))

const contacto = computed(() => ligasDeContacto(ajustes.value))
const horario = computed(() => {
  const h = ajustes.value?.horarios ?? []
  if (!h.length) return ''
  return `${h[0].split(' a ')[0]} a ${h[h.length - 1].split(' a ').pop()}`
})

async function salir() {
  await supabase.auth.signOut()
  perfil.value = null
  await navigateTo('/')
}
</script>

<template>
  <div>
    <div class="franja">
      Pedidos con <b>{{ ajustes?.dias_anticipacion ?? 2 }} días de anticipación</b> · Entrega a domicilio en Guadalajara o recolección · Pago en línea
    </div>
    <header class="barra" :class="{ 'sobre-portada': sobrePortada }">
      <div class="contenedor">
        <nav class="menu" aria-label="Tienda">
          <NuxtLink to="/productos">Productos</NuxtLink>
          <NuxtLink to="/pastel-personalizado">Pasteles personalizados</NuxtLink>
        </nav>
        <NuxtLink to="/" class="logo" aria-label="Lizis Pastelería, inicio">
          <img src="/marca/logo-lizis-coral.png" alt="Lizis Pastelería" width="440" height="600">
        </NuxtLink>
        <nav class="menu derecha" aria-label="Cuenta">
          <NuxtLink v-if="esAdmin" to="/admin">Administración</NuxtLink>
          <NuxtLink v-if="usuario" to="/mis-pedidos">Mis pedidos</NuxtLink>
          <button v-if="usuario" class="enlace" @click="salir">Salir</button>
          <NuxtLink v-else to="/entrar">Entrar</NuxtLink>
          <NuxtLink to="/carrito" class="carrito"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 4h2l2.2 11h10.6L20 8H7" /><circle cx="9.5" cy="19" r="1.3" /><circle cx="17" cy="19" r="1.3" /></svg>Carrito<ClientOnly><span v-if="piezas" class="carrito-cuenta">{{ piezas }}</span></ClientOnly></NuxtLink>
        </nav>
        <div class="acciones-movil">
          <NuxtLink to="/carrito" class="boton chico secundario">Carrito<ClientOnly><span v-if="piezas" class="carrito-cuenta">{{ piezas }}</span></ClientOnly></NuxtLink>
          <button class="hamburguesa" :aria-expanded="abierto" aria-label="Menú" @click="abierto = !abierto">☰</button>
        </div>
      </div>
      <nav v-if="abierto" class="menu-movil" aria-label="Menú">
        <NuxtLink to="/productos">Productos</NuxtLink>
        <NuxtLink to="/pastel-personalizado">Pasteles personalizados</NuxtLink>
        <NuxtLink v-if="usuario" to="/mis-pedidos">Mis pedidos</NuxtLink>
        <NuxtLink v-if="esAdmin" to="/admin">Administración</NuxtLink>
        <button v-if="usuario" class="enlace" @click="salir">Salir</button>
        <NuxtLink v-else to="/entrar">Entrar</NuxtLink>
      </nav>
    </header>
    <main>
      <slot />
    </main>
    <footer class="pie">
      <div class="contenedor">
        <div class="columnas">
          <div class="pila">
            <img class="logo-pie" src="/marca/logo-lizis-blanco.png" alt="Lizis Pastelería" width="440" height="600">
            <p style="margin: 0">Repostería artesanal hecha a mano en Guadalajara, Jalisco.</p>
          </div>
          <div>
            <h4>La tienda</h4>
            <ul>
              <li><NuxtLink to="/productos">Productos</NuxtLink></li>
              <li><NuxtLink to="/pastel-personalizado">Pasteles personalizados</NuxtLink></li>
              <li><NuxtLink to="/carrito">Carrito</NuxtLink></li>
              <li><NuxtLink to="/mis-pedidos">Mis pedidos</NuxtLink></li>
            </ul>
          </div>
          <div>
            <h4>Pedidos</h4>
            <ul>
              <li>Con {{ ajustes?.dias_anticipacion ?? 2 }} días de anticipación</li>
              <li v-if="horario">Entregas de {{ horario }}</li>
              <li>Envío a domicilio: {{ dinero(ajustes?.costo_envio ?? 0) }}</li>
              <li>Recolección sin costo</li>
            </ul>
          </div>
          <div>
            <h4>Contacto</h4>
            <div class="redes">
              <a v-if="contacto.whatsapp" :href="contacto.whatsapp" target="_blank" rel="noopener" class="red">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3.5 20.5l1.3-4.2A8.5 8.5 0 1 1 8 19.6z" /><path d="M9.2 8.8c.3-.6.9-.6 1.2-.1l.7 1.5c.1.3 0 .5-.2.7l-.4.5c.6 1.1 1.5 2 2.6 2.6l.5-.4c.2-.2.5-.3.7-.2l1.5.7c.5.3.5.9-.1 1.2-.8.5-1.9.6-3-.1-1.4-.8-2.6-2-3.4-3.4-.6-1.1-.6-2.2-.1-3z" /></svg>
                WhatsApp
              </a>
              <a v-if="contacto.instagram" :href="contacto.instagram" target="_blank" rel="noopener" class="red">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="5" /><circle cx="12" cy="12" r="4" /><circle cx="17.5" cy="6.5" r="1" fill="currentColor" stroke="none" /></svg>
                Instagram
              </a>
              <a v-if="contacto.facebook" :href="contacto.facebook" target="_blank" rel="noopener" class="red">
                <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M13.5 21v-7.5h2.5l.4-3h-2.9V8.6c0-.9.3-1.5 1.5-1.5h1.5V4.4c-.3 0-1.2-.1-2.2-.1-2.2 0-3.7 1.3-3.7 3.8v2.4H8v3h2.6V21h2.9z" /></svg>
                Facebook
              </a>
            </div>
            <p style="margin: 14px 0 0">Guadalajara, Jalisco</p>
          </div>
        </div>
        <div class="base">
          <span>© {{ new Date().getFullYear() }} Lizis Pastelería</span>
          <span class="prueba"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><rect x="5" y="11" width="14" height="9" rx="2" /><path d="M8 11V8a4 4 0 0 1 8 0v3" /></svg>Pagos seguros con Stripe · modo de prueba del prototipo</span>
        </div>
      </div>
    </footer>
  </div>
</template>
