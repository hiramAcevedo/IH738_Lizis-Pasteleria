<script setup lang="ts">
const { texto } = useAviso()
</script>

<template>
  <div v-if="texto" class="aviso" role="status">{{ texto }}</div>
</template>
