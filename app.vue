<script setup lang="ts">
const route = useRoute()
const { paleta, elegir } = usePaleta()
watch(() => route.query.paleta, (q) => { if (typeof q === 'string') elegir(q || null) }, { immediate: true })
useHead({ htmlAttrs: { 'data-paleta': computed(() => paleta.value.id) } })
</script>

<template>
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
  <Aviso />
</template>
