<script setup lang="ts">
// Comparación de paletas: /?paleta=flores o /?paleta=durazno la deja puesta en una cookie mientras se navega;
// /?paleta= vuelve a la de siempre (lavanda).
const route = useRoute()
const paleta = useCookie<string | null>('paleta', { maxAge: 60 * 60 * 24 * 30, sameSite: 'lax' })
watch(() => route.query.paleta, (q) => { if (typeof q === 'string') paleta.value = q || null }, { immediate: true })
useHead({ htmlAttrs: { 'data-paleta': computed(() => paleta.value || undefined) } })
</script>

<template>
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
  <Aviso />
</template>
