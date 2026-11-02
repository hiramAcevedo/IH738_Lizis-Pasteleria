<script setup lang="ts">
import { dinero, fechaCorta, fechaLarga, mensajeDeError } from '~/composables/useFormato'

definePageMeta({ middleware: 'cuenta' })
const supabase = useSupabaseClient()
const { avisar } = useAviso()

const { data, refresh } = await useAsyncData('mis-pedidos', async () => {
  const [p, s] = await Promise.all([
    supabase.from('pedidos').select('id, folio, estado, fecha_entrega, horario, modalidad, total, creado_el').order('creado_el', { ascending: false }),
    supabase.from('solicitudes').select('id, folio, ocasion, tamano, sabor, fecha_deseada, estado, cotizacion, respuesta, creado_el').order('creado_el', { ascending: false })
  ])
  return { pedidos: p.data ?? [], solicitudes: s.data ?? [] }
})

async function responder(folio: string, acepta: boolean) {
  const { error } = await supabase.rpc('responder_cotizacion', { p_folio: folio, p_acepta: acepta })
  avisar(error ? mensajeDeError(error) : acepta ? 'Aceptaste la cotización; la pastelería te contactará' : 'Rechazaste la cotización')
  await refresh()
}
useHead({ title: 'Mis pedidos · Lizis Pastelería' })
</script>

<template>
  <section class="seccion contenedor pila">
    <h1>Mis pedidos</h1>
    <div class="tarjeta desliza">
      <table v-if="data?.pedidos.length" class="tabla">
        <thead><tr><th>Folio</th><th>Entrega</th><th>Estado</th><th class="num">Total</th></tr></thead>
        <tbody>
          <tr v-for="p in data.pedidos" :key="p.id">
            <td><NuxtLink :to="`/pedido/${p.folio}`">{{ p.folio }}</NuxtLink><div class="suave chico">Pedido el {{ fechaCorta(p.creado_el) }}</div></td>
            <td>{{ fechaLarga(p.fecha_entrega) }}<div class="suave chico">{{ p.modalidad === 'entrega' ? 'A domicilio' : 'Recolección' }}, {{ p.horario }}</div></td>
            <td><EstadoPedido :estado="p.estado" /></td>
            <td class="num">{{ dinero(p.total) }}</td>
          </tr>
        </tbody>
      </table>
      <p v-else class="suave" style="margin: 0">Todavía no tienes pedidos. <NuxtLink to="/productos">Ver productos</NuxtLink></p>
    </div>

    <h2 style="margin-top: 28px">Pasteles personalizados</h2>
    <div class="tarjeta desliza">
      <table v-if="data?.solicitudes.length" class="tabla">
        <thead><tr><th>Folio</th><th>Pastel</th><th>Estado</th><th>Cotización</th></tr></thead>
        <tbody>
          <tr v-for="s in data.solicitudes" :key="s.id">
            <td>{{ s.folio }}<div class="suave chico">Para el {{ fechaLarga(s.fecha_deseada) }}</div></td>
            <td>{{ s.ocasion || 'Pastel' }} · {{ s.tamano }} · {{ s.sabor }}</td>
            <td><EstadoPedido :estado="s.estado" /></td>
            <td>
              <template v-if="s.cotizacion !== null">
                <b>{{ dinero(s.cotizacion) }}</b>
                <div v-if="s.respuesta" class="suave chico">{{ s.respuesta }}</div>
                <div v-if="s.estado === 'cotizada'" class="fila" style="margin-top: 8px">
                  <button class="boton chico" @click="responder(s.folio, true)">Aceptar</button>
                  <button class="boton chico secundario" @click="responder(s.folio, false)">Rechazar</button>
                </div>
              </template>
              <span v-else class="suave">En revisión</span>
            </td>
          </tr>
        </tbody>
      </table>
      <p v-else class="suave" style="margin: 0">No has pedido pasteles personalizados. <NuxtLink to="/pastel-personalizado">Solicitar uno</NuxtLink></p>
    </div>
  </section>
</template>
