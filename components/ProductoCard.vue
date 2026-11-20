<script setup lang="ts">
import { dinero } from '~/composables/useFormato'
import { foto, type Caja } from '~/composables/useImagen'

// nivel: el del título del producto, uno debajo del encabezado de la página (h2 en Productos, h3 bajo una sección).
// prioridad: las primeras tarjetas de Productos, que se ven al abrir la página, se piden primero y sin esperar.
withDefaults(defineProps<{
  producto: { slug: string; nombre: string; precio: number; imagen_url: string | null; categorias?: { nombre: string } | null }
  nivel?: 2 | 3
  prioridad?: boolean
}>(), { nivel: 3, prioridad: false })

// .rejilla-productos: dos columnas en el teléfono y cuatro desde 900 px; la foto llena una caja 4:3
const CAJA: Caja[] = [
  ['(min-width: 1212px)', '277px', 4 / 3],
  ['(min-width: 900px)', 'calc((100vw - 104px) / 4)', 4 / 3],
  ['', 'calc(50vw - 25px)', 4 / 3]
]
</script>

<template>
  <article class="producto">
    <NuxtLink :to="`/productos/${producto.slug}`" class="cubre foto">
      <img v-bind="foto(producto.imagen_url, CAJA)" :alt="producto.nombre" :loading="prioridad ? undefined : 'lazy'" :fetchpriority="prioridad ? 'high' : undefined">
    </NuxtLink>
    <div class="cuerpo">
      <span v-if="producto.categorias" class="cat">{{ producto.categorias.nombre }}</span>
      <NuxtLink :to="`/productos/${producto.slug}`" class="cubre"><component :is="`h${nivel}`" class="nombre">{{ producto.nombre }}</component></NuxtLink>
      <span class="precio">Desde {{ dinero(producto.precio) }}</span>
      <NuxtLink :to="`/productos/${producto.slug}`" class="ver">Ver opciones →</NuxtLink>
    </div>
  </article>
</template>
