<script setup lang="ts">
const supabase = useSupabaseClient()
const route = useRoute()
const router = useRouter()
const busqueda = ref('')

const { data } = await useAsyncData('catalogo', async () => {
  const [c, p] = await Promise.all([
    supabase.from('categorias').select('id, nombre, slug').order('orden'),
    supabase.from('productos').select('id, nombre, slug, precio, imagen_url, descripcion, categorias(nombre, slug)').eq('visible', true).order('categoria_id').order('id')
  ])
  return { categorias: c.data ?? [], productos: p.data ?? [] }
})

const categoria = computed(() => (route.query.categoria as string) || '')
const visibles = computed(() => {
  const q = busqueda.value.trim().toLowerCase()
  return (data.value?.productos ?? []).filter((p: any) =>
    (!categoria.value || p.categorias?.slug === categoria.value) &&
    (!q || p.nombre.toLowerCase().includes(q) || p.descripcion.toLowerCase().includes(q)))
})

function elegir(slug: string) {
  router.replace({ query: slug ? { categoria: slug } : {} })
}
useHead({ title: 'Productos · Lizis Pastelería' })
</script>

<template>
  <section class="seccion contenedor">
    <h1>Productos</h1>
    <div class="pila">
      <input v-model="busqueda" type="search" placeholder="Buscar: rol, brownie, limón..." aria-label="Buscar productos">
      <div class="opciones">
        <button class="opcion" :class="{ activa: !categoria }" @click="elegir('')">Todo</button>
        <button v-for="c in data?.categorias" :key="c.id" class="opcion" :class="{ activa: categoria === c.slug }" @click="elegir(c.slug)">{{ c.nombre }}</button>
      </div>
    </div>
    <div class="rejilla" style="margin-top: 24px">
      <ProductoCard v-for="p in visibles" :key="p.id" :producto="p" />
    </div>
    <p v-if="!visibles.length" class="suave" style="margin-top: 24px">No hay productos con esa búsqueda.</p>
  </section>
</template>
