<script setup lang="ts">
import { dinero, fechaLarga, hoyMx } from '~/composables/useFormato'

definePageMeta({ layout: 'admin', middleware: 'admin' })
const supabase = useSupabaseClient()
const hoy = hoyMx()

const { data } = await useAsyncData('admin-resumen', async () => {
  const inicioMes = `${hoy.slice(0, 8)}01`
  const [p, v, s] = await Promise.all([
    supabase.from('pedidos').select('id, folio, estado, fecha_entrega, horario, modalidad, total, perfiles(nombre)').neq('estado', 'cancelado').gte('fecha_entrega', hoy).order('fecha_entrega').order('horario'),
    supabase.rpc('ventas_por_dia', { p_desde: inicioMes, p_hasta: hoy }),
    supabase.from('solicitudes').select('id', { count: 'exact', head: true }).eq('estado', 'recibida')
  ])
  const pedidos = p.data ?? []
  return {
    porPreparar: pedidos.filter((x: any) => x.estado === 'pagado').length,
    enPreparacion: pedidos.filter((x: any) => x.estado === 'en_preparacion').length,
    listos: pedidos.filter((x: any) => x.estado === 'listo').length,
    hoy: pedidos.filter((x: any) => x.fecha_entrega === hoy && x.estado !== 'pendiente_pago').length,
    ventasMes: (v.data ?? []).reduce((t: number, d: any) => t + Number(d.total), 0),
    solicitudes: s.count ?? 0,
    proximos: pedidos.filter((x: any) => x.estado !== 'pendiente_pago' && x.estado !== 'entregado').slice(0, 8)
  }
})
useHead({ title: 'Resumen · Administración Lizis' })
</script>

<template>
  <div class="pila">
    <h1>Resumen</h1>
    <div class="cifras">
      <NuxtLink to="/admin/pedidos?estado=pagado" class="tarjeta cifra" style="text-decoration: none"><b>{{ data?.porPreparar }}</b><span>Pagados por preparar</span></NuxtLink>
      <NuxtLink to="/admin/pedidos?estado=en_preparacion" class="tarjeta cifra" style="text-decoration: none"><b>{{ data?.enPreparacion }}</b><span>En preparación</span></NuxtLink>
      <NuxtLink to="/admin/pedidos?estado=listo" class="tarjeta cifra" style="text-decoration: none"><b>{{ data?.listos }}</b><span>Listos para entregar</span></NuxtLink>
      <NuxtLink to="/admin/agenda" class="tarjeta cifra" style="text-decoration: none"><b>{{ data?.hoy }}</b><span>Entregas de hoy</span></NuxtLink>
      <NuxtLink to="/admin/personalizados" class="tarjeta cifra" style="text-decoration: none"><b>{{ data?.solicitudes }}</b><span>Solicitudes sin cotizar</span></NuxtLink>
      <NuxtLink to="/admin/reportes" class="tarjeta cifra" style="text-decoration: none"><b style="font-size: 1.5rem">{{ dinero(data?.ventasMes) }}</b><span>Cobrado este mes</span></NuxtLink>
    </div>
    <div class="tarjeta desliza">
      <h3>Próximas entregas</h3>
      <table v-if="data?.proximos.length" class="tabla">
        <thead><tr><th>Día</th><th>Folio</th><th>Cliente</th><th>Estado</th><th class="num">Total</th></tr></thead>
        <tbody>
          <tr v-for="p in data.proximos" :key="p.id">
            <td>{{ fechaLarga(p.fecha_entrega) }}<div class="suave chico">{{ p.horario }} · {{ p.modalidad === 'entrega' ? 'a domicilio' : 'recolección' }}</div></td>
            <td>{{ p.folio }}</td>
            <td>{{ p.perfiles?.nombre }}</td>
            <td><EstadoPedido :estado="p.estado" /></td>
            <td class="num">{{ dinero(p.total) }}</td>
          </tr>
        </tbody>
      </table>
      <p v-else class="suave" style="margin: 0">No hay entregas programadas.</p>
    </div>
  </div>
</template>
