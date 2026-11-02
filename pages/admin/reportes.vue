<script setup lang="ts">
import { dinero, fechaLarga, hoyMx } from '~/composables/useFormato'

definePageMeta({ layout: 'admin', middleware: 'admin' })
const supabase = useSupabaseClient()
const hoy = hoyMx()
const desde = ref(`${hoy.slice(0, 8)}01`)
const hasta = ref(hoy)

const { data, refresh } = await useAsyncData('admin-reportes', async () => {
  const [v, m] = await Promise.all([
    supabase.rpc('ventas_por_dia', { p_desde: desde.value, p_hasta: hasta.value }),
    supabase.rpc('productos_mas_vendidos', { p_desde: desde.value, p_hasta: hasta.value, p_limite: 5 })
  ])
  const dias = (v.data ?? []) as { dia: string; pedidos: number; total: number }[]
  return {
    dias,
    total: dias.reduce((t, d) => t + Number(d.total), 0),
    pedidos: dias.reduce((t, d) => t + d.pedidos, 0),
    top: (m.data ?? []) as { producto: string; piezas: number; importe: number }[]
  }
})
const maximo = computed(() => Math.max(1, ...(data.value?.dias ?? []).map((d) => Number(d.total))))
const maxPiezas = computed(() => Math.max(1, ...(data.value?.top ?? []).map((t) => t.piezas)))
useHead({ title: 'Reportes · Administración Lizis' })
</script>

<template>
  <div class="pila">
    <h1>Reportes de ventas</h1>
    <form class="fila" @submit.prevent="refresh()">
      <label class="campo"><span>Desde</span><input v-model="desde" type="date"></label>
      <label class="campo"><span>Hasta</span><input v-model="hasta" type="date"></label>
      <button class="boton" style="align-self: end">Consultar</button>
    </form>
    <div class="cifras">
      <div class="tarjeta cifra"><b>{{ dinero(data?.total) }}</b><span>Cobrado en el periodo</span></div>
      <div class="tarjeta cifra"><b>{{ data?.pedidos }}</b><span>Pedidos pagados</span></div>
      <div class="tarjeta cifra"><b>{{ dinero(data?.pedidos ? (data.total / data.pedidos) : 0) }}</b><span>Ticket promedio</span></div>
    </div>
    <div class="dos">
      <div class="tarjeta desliza">
        <h3>Ventas por día</h3>
        <table v-if="data?.dias.length" class="tabla">
          <thead><tr><th>Día</th><th>Pedidos</th><th style="width: 40%" /><th class="num">Total</th></tr></thead>
          <tbody>
            <tr v-for="d in data.dias" :key="d.dia">
              <td>{{ fechaLarga(d.dia) }}</td>
              <td>{{ d.pedidos }}</td>
              <td><div class="barra-dato" :style="{ width: `${(Number(d.total) / maximo) * 100}%` }" /></td>
              <td class="num">{{ dinero(d.total) }}</td>
            </tr>
          </tbody>
        </table>
        <p v-else class="suave" style="margin: 0">Sin ventas en el periodo.</p>
      </div>
      <div class="tarjeta desliza">
        <h3>Productos más vendidos</h3>
        <table v-if="data?.top.length" class="tabla">
          <thead><tr><th>Producto</th><th>Piezas</th><th class="num">Importe</th></tr></thead>
          <tbody>
            <tr v-for="t in data.top" :key="t.producto">
              <td>{{ t.producto }}<div class="barra-dato" :style="{ width: `${(t.piezas / maxPiezas) * 100}%`, marginTop: '6px', opacity: 0.7 }" /></td>
              <td>{{ t.piezas }}</td>
              <td class="num">{{ dinero(t.importe) }}</td>
            </tr>
          </tbody>
        </table>
        <p v-else class="suave" style="margin: 0">Sin ventas en el periodo.</p>
      </div>
    </div>
  </div>
</template>
