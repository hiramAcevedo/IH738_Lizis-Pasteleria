<script setup lang="ts">
import { dinero, fechaLarga, hoyMx } from '~/composables/useFormato'

definePageMeta({ layout: 'admin', middleware: 'admin' })
const supabase = useSupabaseClient()
const hoy = hoyMx()

// Los pedidos por día de entrega, para planear la producción. Los pendientes de pago también ocupan lugar.
const { data } = await useAsyncData('admin-agenda', async () => {
  const [p, a] = await Promise.all([
    supabase.from('pedidos').select('id, folio, estado, fecha_entrega, horario, modalidad, direccion, total, perfiles(nombre), pedido_items(id, nombre, detalle, cantidad)')
      .neq('estado', 'cancelado').gte('fecha_entrega', hoy).order('fecha_entrega').order('horario'),
    supabase.from('ajustes').select('capacidad_diaria').eq('id', 1).single()
  ])
  const dias = new Map<string, any[]>()
  for (const x of p.data ?? []) {
    if (!dias.has(x.fecha_entrega)) dias.set(x.fecha_entrega, [])
    dias.get(x.fecha_entrega)!.push(x)
  }
  return { dias: [...dias.entries()], capacidad: a.data?.capacidad_diaria ?? 0 }
})
useHead({ title: 'Agenda · Administración Lizis' })
</script>

<template>
  <div class="pila">
    <h1>Agenda de entregas</h1>
    <p class="suave">Pedidos desde hoy, agrupados por día. Capacidad: {{ data?.capacidad }} pedidos por día.</p>
    <div v-for="[dia, pedidos] in data?.dias" :key="dia" class="tarjeta dia pila">
      <div class="fila entre">
        <h3 style="margin: 0; text-transform: capitalize">{{ fechaLarga(dia) }}</h3>
        <span class="suave">{{ pedidos.length }} de {{ data?.capacidad }} lugares</span>
      </div>
      <div class="desliza">
        <table class="tabla">
          <thead><tr><th>Horario</th><th>Folio y cliente</th><th>Qué lleva</th><th>Estado</th><th class="num">Total</th></tr></thead>
          <tbody>
            <tr v-for="p in pedidos" :key="p.id">
              <td>{{ p.horario }}<div class="suave chico">{{ p.modalidad === 'entrega' ? 'A domicilio' : 'Recolección' }}</div></td>
              <td><b>{{ p.folio }}</b><div class="suave chico">{{ p.perfiles?.nombre }}</div><div v-if="p.direccion" class="suave chico">{{ p.direccion }}</div></td>
              <td><div v-for="i in p.pedido_items" :key="i.id">{{ i.cantidad }} × {{ i.nombre }} <span class="suave chico">{{ i.detalle }}</span></div></td>
              <td><EstadoPedido :estado="p.estado" /></td>
              <td class="num">{{ dinero(p.total) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    <p v-if="!data?.dias.length" class="tarjeta suave">No hay entregas programadas desde hoy.</p>
  </div>
</template>
