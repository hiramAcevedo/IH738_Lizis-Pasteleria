<script setup lang="ts">
const supabase = useSupabaseClient()

const { data } = await useAsyncData('inicio', async () => {
  const [c, p] = await Promise.all([
    supabase.from('categorias').select('id, nombre, slug, descripcion').order('orden'),
    supabase.from('productos').select('id, nombre, slug, precio, imagen_url, categorias(nombre)').eq('destacado', true).eq('visible', true).order('id')
  ])
  return { categorias: c.data ?? [], destacados: p.data ?? [] }
})
</script>

<template>
  <div>
    <section class="portada">
      <img src="https://images.unsplash.com/photo-1585190775852-3e6bb2b80184?w=1800&q=75&auto=format&fit=crop" alt="Roles de canela recién glaseados">
      <div class="velo" />
      <div class="texto">
        <div class="contenedor pila">
          <h1>Postres al alcance de un clic</h1>
          <p>Roles de canela, brownies, galletas y pasteles personalizados. Elige, programa tu entrega y paga en línea.</p>
          <div class="fila">
            <NuxtLink to="/productos" class="boton">Ver productos</NuxtLink>
            <NuxtLink to="/pastel-personalizado" class="boton secundario">Pedir un pastel personalizado</NuxtLink>
          </div>
        </div>
      </div>
    </section>

    <section class="seccion contenedor">
      <h2>Categorías</h2>
      <div class="rejilla">
        <NuxtLink v-for="c in data?.categorias" :key="c.id" :to="{ path: '/productos', query: { categoria: c.slug } }" class="tarjeta" style="text-decoration: none">
          <h3>{{ c.nombre }}</h3>
          <p class="suave chico" style="margin: 0">{{ c.descripcion }}</p>
        </NuxtLink>
        <NuxtLink to="/pastel-personalizado" class="tarjeta" style="text-decoration: none">
          <h3>Pasteles personalizados</h3>
          <p class="suave chico" style="margin: 0">Cuéntanos la ocasión, el sabor y la decoración; te enviamos la cotización.</p>
        </NuxtLink>
      </div>
    </section>

    <section class="seccion contenedor">
      <div class="fila entre">
        <h2>Los favoritos</h2>
        <NuxtLink to="/productos">Ver todo el catálogo</NuxtLink>
      </div>
      <div class="rejilla">
        <ProductoCard v-for="p in data?.destacados" :key="p.id" :producto="p" />
      </div>
    </section>

    <section class="seccion contenedor">
      <h2>Cómo pedir</h2>
      <div class="rejilla">
        <div class="tarjeta"><h3>1. Elige</h3><p class="suave" style="margin: 0">Agrega al carrito los productos, su presentación y su glaseado.</p></div>
        <div class="tarjeta"><h3>2. Programa</h3><p class="suave" style="margin: 0">Escoge entrega a domicilio o recolección, el día y el horario con lugar.</p></div>
        <div class="tarjeta"><h3>3. Paga en línea</h3><p class="suave" style="margin: 0">El pago va directo a Stripe; sigue el estado de tu pedido en Mis pedidos.</p></div>
      </div>
    </section>
  </div>
</template>
