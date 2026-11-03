<script setup lang="ts">
import { dinero } from '~/composables/useFormato'

const supabase = useSupabaseClient()
const route = useRoute()
const { agregar } = useCarrito()
const { avisar } = useAviso()

const { data: producto } = await useAsyncData(`producto-${route.params.slug}`, async () => {
  const { data } = await supabase
    .from('productos')
    .select('id, nombre, slug, descripcion, ingredientes, alergenos, precio, imagen_url, categoria_id, categorias(nombre, slug), variantes(id, grupo, nombre, precio_extra, orden)')
    .eq('slug', route.params.slug as string)
    .eq('visible', true)
    .maybeSingle()
  return data
})
if (!producto.value) throw createError({ statusCode: 404, statusMessage: 'Ese producto no existe o ya no está disponible' })

const { data: relacionados } = await useAsyncData(`relacionados-${route.params.slug}`, async () => {
  const { data } = await supabase.from('productos').select('id, nombre, slug, precio, imagen_url, categorias(nombre)')
    .eq('visible', true).eq('categoria_id', producto.value!.categoria_id).neq('id', producto.value!.id).limit(3)
  return data ?? []
})

// Las variantes por grupo, cada grupo con su primera opción elegida.
const grupos = computed(() => {
  const m = new Map<string, any[]>()
  for (const v of [...(producto.value?.variantes ?? [])].sort((a: any, b: any) => a.orden - b.orden)) {
    if (!m.has(v.grupo)) m.set(v.grupo, [])
    m.get(v.grupo)!.push(v)
  }
  return [...m.entries()]
})
const elegidas = reactive<Record<string, number>>({})
for (const [g, opciones] of grupos.value) elegidas[g] = opciones[0].id
const cantidad = ref(1)

const variantesElegidas = computed(() => grupos.value.map(([g, ops]) => ops.find((o: any) => o.id === elegidas[g])))
const unitario = computed(() => Number(producto.value!.precio) + variantesElegidas.value.reduce((s, v: any) => s + Number(v.precio_extra), 0))

function alCarrito() {
  const p = producto.value!
  agregar({
    producto_id: p.id, slug: p.slug, nombre: p.nombre, imagen: p.imagen_url,
    variantes: variantesElegidas.value.map((v: any) => ({ id: v.id, grupo: v.grupo, nombre: v.nombre, precio_extra: Number(v.precio_extra) })),
    precio_unitario: unitario.value, cantidad: cantidad.value
  })
  avisar(`${p.nombre} se agregó al carrito`)
  cantidad.value = 1
}
useHead({ title: `${producto.value.nombre} · Lizis Pastelería` })
</script>

<template>
  <section v-if="producto" class="seccion contenedor">
    <p class="chico"><NuxtLink to="/productos">Productos</NuxtLink> / <NuxtLink :to="{ path: '/productos', query: { categoria: producto.categorias?.slug } }">{{ producto.categorias?.nombre }}</NuxtLink></p>
    <div class="dos">
      <img :src="producto.imagen_url || '/marca/icono.png'" :alt="producto.nombre" class="foto-detalle">
      <div class="pila">
        <h1>{{ producto.nombre }}</h1>
        <div class="precio-grande">{{ dinero(unitario) }}</div>
        <p>{{ producto.descripcion }}</p>
        <div v-for="[grupo, opciones] in grupos" :key="grupo" class="campo">
          <span>{{ grupo }}</span>
          <div class="opciones">
            <label v-for="o in opciones" :key="o.id" class="opcion" :class="{ activa: elegidas[grupo] === o.id }">
              <input v-model="elegidas[grupo]" type="radio" :name="grupo" :value="o.id">
              {{ o.nombre }}<span v-if="Number(o.precio_extra)" class="suave">+{{ dinero(o.precio_extra) }}</span>
            </label>
          </div>
        </div>
        <div class="fila">
          <div class="cantidad">
            <button aria-label="Menos" @click="cantidad = Math.max(1, cantidad - 1)">−</button>
            <span>{{ cantidad }}</span>
            <button aria-label="Más" @click="cantidad = Math.min(50, cantidad + 1)">+</button>
          </div>
          <button class="boton" @click="alCarrito">Agregar al carrito · {{ dinero(unitario * cantidad) }}</button>
        </div>
        <div class="tarjeta pila">
          <div><b>Ingredientes.</b> {{ producto.ingredientes }}</div>
          <div><b>Alérgenos.</b> {{ producto.alergenos }}</div>
        </div>
      </div>
    </div>
    <div v-if="relacionados?.length" style="margin-top: 40px">
      <h2>También de {{ producto.categorias?.nombre?.toLowerCase() }}</h2>
      <div class="rejilla-productos">
        <ProductoCard v-for="r in relacionados" :key="r.id" :producto="r" />
      </div>
    </div>
  </section>
</template>
