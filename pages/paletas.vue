<script setup lang="ts">
import { PALETAS } from '~/composables/usePaleta'

// Las combinaciones de color para decidir con el equipo: al elegir una, toda la tienda cambia en este navegador.
const { paleta, elegir } = usePaleta()
useHead({ title: 'Paletas · Lizis Pastelería', meta: [{ name: 'robots', content: 'noindex' }] })
</script>

<template>
  <section class="cabecera contenedor">
    <span class="rotulo">Para decidir el color</span>
    <h1>Paletas de la tienda</h1>
    <p>Elige una y la tienda completa cambia en este navegador. Recorre las páginas con ella y vuelve aquí para probar otra.</p>
  </section>
  <section class="seccion contenedor" style="padding-top: 24px">
    <div class="paletas">
      <article v-for="p in PALETAS" :key="p.id" class="tarjeta paleta" :class="{ elegida: p.id === paleta.id }">
        <div class="muestras">
          <span v-for="c in p.muestras" :key="c" :style="{ background: c }" />
        </div>
        <h3>{{ p.nombre }}</h3>
        <p class="suave">{{ p.detalle }}</p>
        <div class="fila">
          <button v-if="p.id !== paleta.id" class="boton chico" @click="elegir(p.id)">Usar esta</button>
          <span v-else class="estado listo">En uso</span>
          <NuxtLink class="mas" :to="{ path: '/', query: { paleta: p.id } }">Ver el inicio así</NuxtLink>
        </div>
      </article>
    </div>
  </section>
</template>
