<script setup lang="ts">
const supabase = useSupabaseClient()
const { data: ajustes } = await useAjustes()

const { data } = await useAsyncData('inicio', async () => {
  const [c, p] = await Promise.all([
    supabase.from('categorias').select('id, nombre, slug, descripcion').order('orden'),
    supabase.from('productos').select('id, nombre, slug, precio, imagen_url, destacado, categorias(nombre, slug)').eq('visible', true).order('id')
  ])
  const productos = (p.data ?? []) as any[]
  return { categorias: c.data ?? [], productos, destacados: productos.filter((x) => x.destacado) }
})

// Las fotos reales de Lizis van en las categorías que las tienen; las demás toman la foto de su primer producto.
const fotosReales: Record<string, string> = {
  'roles-de-canela': '/fotos/roles-toppings.jpg',
  brownies: '/fotos/brownies-fresa-nuez.jpg',
  tartaletas: '/fotos/tartaletas.jpg'
}
const losas = computed(() => (data.value?.categorias ?? []).map((c: any) => {
  const suyos = (data.value?.productos ?? []).filter((p) => p.categorias?.slug === c.slug)
  return { ...c, foto: fotosReales[c.slug] ?? suyos[0]?.imagen_url, cuantos: suyos.length }
}).filter((c: any) => c.cuantos))

useHead({ title: 'Lizis Pastelería · Repostería artesanal en Guadalajara' })
</script>

<template>
  <div>
    <section class="portada">
      <div class="portada-capa" role="img" aria-label="Plato de roles de canela glaseados con lavanda junto a ramas de flores, con luz de ventana" />
      <div class="contenedor portada-contenido">
        <div class="portada-texto">
          <span class="rotulo">Repostería artesanal · Guadalajara</span>
          <h1>Roles de canela, brownies y pasteles hechos <em>a mano</em></h1>
          <p class="entrada">Horneamos sobre pedido desde 2020. Elige tus favoritos, programa el día de entrega y paga en línea.</p>
          <hr class="raya">
          <div class="fila">
            <NuxtLink to="/productos" class="boton">Ver productos</NuxtLink>
            <NuxtLink to="/pastel-personalizado" class="boton secundario">Cotizar un pastel</NuxtLink>
          </div>
        </div>
      </div>
    </section>

    <section class="seccion contenedor">
      <div class="titulo-lineas"><h2>Elige por antojo</h2></div>
      <div class="mosaico">
        <NuxtLink v-for="c in losas" :key="c.id" :to="{ path: '/productos', query: { categoria: c.slug } }" class="losa">
          <img :src="c.foto" :alt="c.nombre" loading="lazy">
          <span>{{ c.nombre }}<small>{{ c.descripcion }}</small></span>
        </NuxtLink>
        <NuxtLink to="/pastel-personalizado" class="losa">
          <img src="/fotos/pastel-cumpleanos.jpg" alt="Pastel de chocolate con fresas y letrero de cumpleaños" loading="lazy">
          <span>Pasteles personalizados<small>Para tus eventos más especiales.</small></span>
        </NuxtLink>
      </div>
    </section>

    <section class="contenedor" style="padding-bottom: clamp(36px, 5vw, 56px)">
      <span class="rotulo">Lo más pedido</span>
      <div class="encabezado-seccion">
        <h2>Los favoritos de la casa</h2>
        <NuxtLink to="/productos" class="mas">Ver todo el menú →</NuxtLink>
      </div>
      <div class="rejilla-productos">
        <ProductoCard v-for="p in data?.destacados" :key="p.id" :producto="p" />
      </div>
    </section>

    <section class="contenedor">
      <div class="panel-durazno panel-pasos">
        <div>
          <span class="rotulo">Pedir es sencillo</span>
          <h2>Tu pedido en <em>tres pasos</em></h2>
        </div>
        <div class="pasos">
          <div class="paso">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 8h14l-1.2 12H6.2z" /><path d="M9 8V6a3 3 0 0 1 6 0v2" /></svg>
            <h3><b>01</b>Elige</h3>
            <p>Agrega al carrito tus productos y elige sus opciones.</p>
          </div>
          <div class="paso">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3.5" y="5" width="17" height="15" rx="2" /><path d="M3.5 10h17M8 3v4M16 3v4" /></svg>
            <h3><b>02</b>Programa</h3>
            <p>Elige entrega o recolección, con {{ ajustes?.dias_anticipacion ?? 2 }} días de anticipación.</p>
          </div>
          <div class="paso">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="6" width="18" height="13" rx="2" /><path d="M3 10h18M7 15h4" /></svg>
            <h3><b>03</b>Paga en línea</h3>
            <p>Finaliza tu pedido de forma segura con Stripe.</p>
          </div>
        </div>
      </div>
    </section>

    <section class="contenedor" style="padding-top: 20px">
      <div class="panel-durazno destacada">
        <div>
          <span class="rotulo">Pasteles personalizados</span>
          <h2>Crea el tuyo</h2>
          <p>Cuéntanos la ocasión, el tamaño, el sabor y la decoración. Puedes subir una foto de referencia y te mandamos la cotización para que la aceptes en línea.</p>
          <NuxtLink to="/pastel-personalizado" class="boton" style="margin-top: 6px">Solicitar cotización</NuxtLink>
        </div>
        <div class="pareja">
          <img src="/fotos/pastel-flores.jpg" alt="Pastel semidesnudo con frutos rojos y flores comestibles" loading="lazy">
          <img src="/fotos/pastel-cumpleanos.jpg" alt="Pastel de chocolate con fresas" loading="lazy">
          <svg class="trazos" viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><path d="M7 17 2 15M11 9 8 3M19 10l3-6" /></svg>
        </div>
      </div>
    </section>

    <section class="seccion contenedor">
      <div class="historia">
        <div>
          <span class="rotulo">Nuestra historia</span>
          <h2>Una cocina de casa que creció</h2>
          <p>Lizis Pastelería nació en 2020. Lizeth, estudiante y amante de la repostería, empezó a hornear en casa pasteles llenos de color y sabor, y el boca a boca hizo el resto.</p>
          <p style="margin: 0">Hoy horneamos a diario y cuidamos lo de siempre: procesos artesanales, buenos ingredientes y cada pedido hecho como si fuera para casa.</p>
        </div>
        <div class="galeria-historia">
          <img src="/fotos/roles-masa.jpg" alt="Roles de canela recién enrollados, antes de hornear" loading="lazy">
          <img src="/fotos/brownie-caramelo.jpg" alt="Brownie con chocolate de leche" loading="lazy">
          <img src="/fotos/brownies-charola.jpg" alt="Charola de brownies cortados" loading="lazy">
        </div>
        <p class="cita">Cada capa de un rol de canela es una pequeña dosis de felicidad.</p>
      </div>
    </section>
  </div>
</template>
