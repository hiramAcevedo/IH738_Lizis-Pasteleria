<script setup lang="ts">
import { ESTADOS, dinero, fechaHora, fechaLarga, mensajeDeError } from '~/composables/useFormato'

definePageMeta({ middleware: 'cuenta' })
const supabase = useSupabaseClient()
const route = useRoute()
const router = useRouter()
const folio = route.params.folio as string
const nota = ref<{ tipo: string; texto: string } | null>(null)
const ocupado = ref(false)
const confirmando = ref(false)

const { data: pedido, refresh } = await useAsyncData(`pedido-${folio}`, async () => {
  const { data } = await supabase
    .from('pedidos')
    .select('id, folio, estado, modalidad, fecha_entrega, horario, direccion, telefono, notas, subtotal, envio, total, pagado_el, creado_el, pedido_items(id, nombre, detalle, precio_unitario, cantidad, importe), historial_estados(id, estado, creado_el)')
    .eq('folio', folio)
    .maybeSingle()
  return data
})

// Al volver de Stripe: el servidor comprueba la sesión con Stripe antes de marcar el pedido como pagado.
onMounted(async () => {
  const pago = route.query.pago as string | undefined
  if (pago === 'exito' && route.query.session_id) {
    try {
      const r = await $fetch<{ estado: string }>('/api/pagos/confirmar', { method: 'POST', body: { folio, session_id: route.query.session_id } })
      nota.value = r.estado === 'pagado'
        ? { tipo: 'ok', texto: '¡Pago recibido! Tu pedido ya está en la lista de la pastelería.' }
        : { tipo: '', texto: `Tu pedido está ${ESTADOS[r.estado]?.toLowerCase() ?? r.estado}.` }
    } catch (e: any) {
      nota.value = { tipo: 'mal', texto: e?.data?.statusMessage ?? 'No se pudo confirmar el pago con Stripe' }
    }
    await refresh()
    router.replace({ query: {} })
  } else if (pago === 'cancelado') {
    nota.value = { tipo: '', texto: 'Cancelaste el pago. Tu pedido sigue registrado como pendiente de pago: puedes pagarlo o cancelarlo.' }
    router.replace({ query: {} })
  } else if (pago === 'pendiente') {
    nota.value = { tipo: '', texto: 'Tu pedido quedó registrado. El pago en línea no está disponible en este momento; inténtalo de nuevo más tarde.' }
    router.replace({ query: {} })
  }
})

async function pagar() {
  ocupado.value = true
  try {
    const { url } = await $fetch<{ url: string }>('/api/pagos/sesion', { method: 'POST', body: { folio } })
    window.location.href = url
  } catch (e: any) {
    nota.value = { tipo: 'mal', texto: e?.data?.statusMessage ?? 'No se pudo abrir el pago' }
    ocupado.value = false
  }
}

async function cancelar() {
  confirmando.value = false
  const { error } = await supabase.rpc('cancelar_pedido', { p_folio: folio })
  nota.value = error ? { tipo: 'mal', texto: mensajeDeError(error) } : { tipo: '', texto: 'El pedido se canceló.' }
  await refresh()
}

const historial = computed(() => [...(pedido.value?.historial_estados ?? [])].sort((a: any, b: any) => a.creado_el.localeCompare(b.creado_el)))
useHead({ title: `Pedido ${folio} · Lizis Pastelería` })
</script>

<template>
  <section class="seccion contenedor">
    <div v-if="!pedido" class="tarjeta">No encontramos ese pedido en tu cuenta.</div>
    <template v-else>
      <div class="fila entre">
        <h1 style="margin: 0">Pedido {{ pedido.folio }}</h1>
        <EstadoPedido :estado="pedido.estado" />
      </div>
      <p v-if="nota" class="nota" :class="nota.tipo" style="margin-top: 16px">{{ nota.texto }}</p>
      <div class="dos" style="margin-top: 20px">
        <div class="tarjeta pila">
          <h3>Productos</h3>
          <div v-for="i in pedido.pedido_items" :key="i.id" class="fila entre">
            <div><b>{{ i.cantidad }} × {{ i.nombre }}</b><div class="suave chico">{{ i.detalle }}</div></div>
            <span>{{ dinero(i.importe) }}</span>
          </div>
          <hr style="border: 0; border-top: 1px solid var(--linea)">
          <div class="fila entre"><span>Subtotal</span><span>{{ dinero(pedido.subtotal) }}</span></div>
          <div class="fila entre"><span>Envío</span><span>{{ dinero(pedido.envio) }}</span></div>
          <div class="fila entre"><b>Total</b><b>{{ dinero(pedido.total) }}</b></div>
          <div v-if="pedido.estado === 'pendiente_pago'" class="fila">
            <button class="boton" :disabled="ocupado" @click="pagar">{{ ocupado ? 'Abriendo el pago...' : 'Pagar ahora' }}</button>
            <button v-if="!confirmando" class="boton peligro" @click="confirmando = true">Cancelar pedido</button>
            <template v-else>
              <span class="suave">¿Seguro?</span>
              <button class="boton peligro" @click="cancelar">Sí, cancelar</button>
              <button class="boton secundario" @click="confirmando = false">No</button>
            </template>
          </div>
          <p v-if="pedido.pagado_el" class="suave chico" style="margin: 0">Pagado el {{ fechaHora(pedido.pagado_el) }}</p>
        </div>
        <div class="pila">
          <div class="tarjeta pila">
            <h3>Entrega</h3>
            <div><b>{{ pedido.modalidad === 'entrega' ? 'Entrega a domicilio' : 'Recolección' }}</b>, {{ fechaLarga(pedido.fecha_entrega) }}, de {{ pedido.horario }}</div>
            <div v-if="pedido.direccion">{{ pedido.direccion }}</div>
            <div class="suave">Teléfono: {{ pedido.telefono }}</div>
            <div v-if="pedido.notas" class="suave">Notas: {{ pedido.notas }}</div>
          </div>
          <div class="tarjeta">
            <h3>Seguimiento</h3>
            <ul class="tiempo">
              <li v-for="h in historial" :key="h.id"><b>{{ ESTADOS[h.estado] }}</b><div class="suave chico">{{ fechaHora(h.creado_el) }}</div></li>
            </ul>
          </div>
        </div>
      </div>
      <p style="margin-top: 20px"><NuxtLink to="/mis-pedidos">Ver todos mis pedidos</NuxtLink></p>
    </template>
  </section>
</template>
