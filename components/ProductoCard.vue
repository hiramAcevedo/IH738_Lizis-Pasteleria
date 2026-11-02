<script setup lang="ts">
import { dinero } from '~/composables/useFormato'
defineProps<{ producto: { slug: string; nombre: string; precio: number; imagen_url: string | null; categorias?: { nombre: string } | null } }>()
</script>

<template>
  <article class="tarjeta producto">
    <NuxtLink :to="`/productos/${producto.slug}`" class="cubre">
      <img :src="producto.imagen_url || '/favicon.svg'" :alt="producto.nombre" loading="lazy">
    </NuxtLink>
    <div class="cuerpo">
      <span v-if="producto.categorias" class="cat">{{ producto.categorias.nombre }}</span>
      <NuxtLink :to="`/productos/${producto.slug}`" class="cubre"><h3>{{ producto.nombre }}</h3></NuxtLink>
      <span class="precio">Desde {{ dinero(producto.precio) }}</span>
      <NuxtLink :to="`/productos/${producto.slug}`" class="boton chico secundario">Ver opciones</NuxtLink>
    </div>
  </article>
</template>
