<script setup lang="ts">
import { dinero } from '~/composables/useFormato'
defineProps<{ producto: { slug: string; nombre: string; precio: number; imagen_url: string | null; categorias?: { nombre: string } | null } }>()
</script>

<template>
  <article class="producto">
    <NuxtLink :to="`/productos/${producto.slug}`" class="cubre foto">
      <img :src="producto.imagen_url || '/marca/icono.png'" :alt="producto.nombre" loading="lazy">
    </NuxtLink>
    <div class="cuerpo">
      <span v-if="producto.categorias" class="cat">{{ producto.categorias.nombre }}</span>
      <NuxtLink :to="`/productos/${producto.slug}`" class="cubre"><h3>{{ producto.nombre }}</h3></NuxtLink>
      <span class="precio">Desde {{ dinero(producto.precio) }}</span>
      <NuxtLink :to="`/productos/${producto.slug}`" class="ver">Ver opciones →</NuxtLink>
    </div>
  </article>
</template>
