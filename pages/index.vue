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
      <img class="portada-flores" src="/fotos/portada-flores.jpg" alt="" aria-hidden="true" width="300" height="1024">
      <div class="portada-texto">
        <span class="rotulo">Repostería artesanal · Guadalajara</span>
        <h1>Roles de canela, brownies y pasteles hechos <em>a mano</em></h1>
        <p class="entrada">Horneamos sobre pedido desde 2020. Elige tus favoritos, programa el día de entrega y paga en línea.</p>
        <div class="fila" style="margin-top: 26px">
          <NuxtLink to="/productos" class="boton">Ver productos</NuxtLink>
          <NuxtLink to="/pastel-personalizado" class="boton secundario">Cotizar un pastel</NuxtLink>
        </div>
        <ul class="datos">
          <li>Entrega a domicilio o recolección</li>
          <li>Pago seguro con Stripe</li>
          <li>Sigue tu pedido en línea</li>
        </ul>
      </div>
      <div class="portada-foto">
        <img class="portada-plato" src="/fotos/portada-plato.jpg" alt="Plato de roles de canela glaseados con canela espolvoreada y una ramita de lavanda" width="976" height="1024">
      </div>
    </section>

    <section class="seccion contenedor">
      <div class="titulo-lineas"><h2>Elige por <em>antojo</em></h2></div>
      <div class="mosaico">
        <NuxtLink v-for="c in losas" :key="c.id" :to="{ path: '/productos', query: { categoria: c.slug } }" class="losa">
          <img :src="c.foto" :alt="c.nombre" loading="lazy">
          <span>{{ c.nombre }}</span>
        </NuxtLink>
        <NuxtLink to="/pastel-personalizado" class="losa">
          <img src="/fotos/pastel-cumpleanos.jpg" alt="Pastel de chocolate con fresas y letrero de cumpleaños" loading="lazy">
          <span>Pasteles personalizados</span>
        </NuxtLink>
      </div>
    </section>

    <section class="seccion banda">
      <div class="contenedor">
        <div class="encabezado-seccion">
          <h2>Los favoritos de la casa</h2>
          <NuxtLink to="/productos" class="mas">Ver todo el menú →</NuxtLink>
        </div>
        <div class="rejilla-productos">
          <ProductoCard v-for="p in data?.destacados" :key="p.id" :producto="p" />
        </div>
      </div>
    </section>

    <section class="seccion contenedor">
      <div class="titulo-linea"><h2>Tu pedido en <em>tres pasos</em></h2></div>
      <div class="pasos">
        <div class="paso"><h3><b>01</b> Elige</h3><p>Agrega al carrito la presentación y el glaseado que quieras.</p></div>
        <div class="paso"><h3><b>02</b> Programa</h3><p>Escoge entrega a domicilio o recolección, el día y el horario.</p></div>
        <div class="paso"><h3><b>03</b> Paga en línea</h3><p>El pago va directo a Stripe y sigues el estado en Mis pedidos.</p></div>
      </div>
      <p class="cupo">Recibimos hasta {{ ajustes?.capacidad_diaria ?? 6 }} pedidos por día, con {{ ajustes?.dias_anticipacion ?? 2 }} días de anticipación.</p>
    </section>

    <section class="seccion banda destacada">
      <div class="contenedor">
        <div>
          <span class="rotulo">Pasteles personalizados</span>
          <h2>Crea el tuyo</h2>
          <p>Cuéntanos la ocasión, el tamaño, el sabor y la decoración. Puedes subir una foto de referencia y te mandamos la cotización para que la aceptes en línea.</p>
          <NuxtLink to="/pastel-personalizado" class="boton" style="margin-top: 8px">Solicitar cotización</NuxtLink>
        </div>
        <div class="pareja">
          <img src="/fotos/pastel-flores.jpg" alt="Pastel semidesnudo con frutos rojos y flores comestibles" loading="lazy">
          <img src="/fotos/pastel-cumpleanos.jpg" alt="Pastel de chocolate con fresas" loading="lazy">
        </div>
      </div>
    </section>

    <section class="seccion historia">
      <div class="contenedor">
        <div class="galeria-historia">
          <img src="/fotos/roles-masa.jpg" alt="Roles de canela recién enrollados, antes de hornear" loading="lazy">
          <img src="/fotos/brownie-caramelo.jpg" alt="Brownie con chocolate de leche" loading="lazy">
          <img src="/fotos/brownies-charola.jpg" alt="Charola de brownies cortados" loading="lazy">
        </div>
        <div>
          <span class="rotulo">Nuestra historia</span>
          <h2>Una cocina de casa que <em>creció</em></h2>
          <p>Lizis Pastelería nació en 2020. Lizeth, estudiante y amante de la repostería, empezó a hornear en casa pasteles llenos de color y sabor, y el boca a boca hizo el resto: llegaron más pedidos y el menú creció.</p>
          <p>Hoy horneamos a diario y cuidamos lo de siempre: procesos artesanales, buenos ingredientes y cada pedido hecho como si fuera para casa.</p>
          <p class="cita">Cada capa de un rol de canela es una pequeña dosis de felicidad.</p>
        </div>
      </div>
    </section>
  </div>
</template>
