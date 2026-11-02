<script setup lang="ts">
import { ESTADOS } from '~/composables/useFormato'
defineProps<{ estado: string }>()
</script>

<template>
  <span class="estado" :class="estado">{{ ESTADOS[estado] ?? estado }}</span>
</template>
