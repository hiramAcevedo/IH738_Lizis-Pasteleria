<script setup lang="ts">
import jost from '~/assets/fonts/jost-latin.woff2?url'
import lora from '~/assets/fonts/lora-latin.woff2?url'

const route = useRoute()
const { paleta, elegir } = usePaleta()
watch(() => route.query.paleta, (q) => { if (typeof q === 'string') elegir(q || null) }, { immediate: true })
// Jost y Lora se piden desde el <head>: llegan antes del primer pintado y el texto no salta al cambiar de fuente
useHead({
  htmlAttrs: { 'data-paleta': computed(() => paleta.value.id) },
  link: [jost, lora].map((href) => ({ rel: 'preload', as: 'font', type: 'font/woff2', href, crossorigin: '' }))
})
</script>

<template>
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
  <Aviso />
</template>
