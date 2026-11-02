<script setup lang="ts">
import { ESTADOS, dinero, fechaHora, fechaLarga, mensajeDeError } from '~/composables/useFormato'

definePageMeta({ layout: 'admin', middleware: 'admin' })
const supabase = useSupabaseClient()
const route = useRoute()
const router = useRouter()
const { avisar } = useAviso()
const abierto = ref<number | null>(null)
const busqueda = ref('')

const { data: pedidos, refresh } = await useAsyncData('admin-pedidos', async () => {
  const { data } = await supabase
    .from('pedidos')
    .select('id, folio, estado, modalidad, fecha_entrega, horario, direccion, telefono, notas, subtotal, envio, total, pagado_el, creado_el, perfiles(nombre), pedido_items(id, nombre, detalle, cantidad, importe), historial_estados(id, estado, creado_el)')
    .order('creado_el', { ascending: false })
    .limit(200)
  return data ?? []
})

const estado = computed(() => (route.query.estado as string) || '')
const visibles = computed(() => {
  const q = busqueda.value.trim().toUpperCase()
  return (pedidos.value ?? []).filter((p: any) => (!estado.value || p.estado === estado.value) && (!q || p.folio.includes(q) || (p.perfiles?.nombre ?? '').toUpperCase().includes(q)))
})

// El siguiente paso de cada estado; la base rechaza cualquier salto que no esté aquí.
const SIGUIENTE: Record<string, { estado: string; texto: string } | undefined> = {
  pagado: { estado: 'en_preparacion', texto: 'Pasar a preparación' },
  en_preparacion: { estado: 'listo', texto: 'Marcar como listo' },
  listo: { estado: 'entregado', texto: 'Marcar como entregado' }
}

async function cambiar(p: any, nuevo: string) {
  const { error } = await supabase.rpc('cambiar_estado', { p_pedido: p.id, p_estado: nuevo })
  avisar(error ? mensajeDeError(error) : `${p.folio}: ${ESTADOS[nuevo]}`)
  await refresh()
}

// El aviso al cliente sale por WhatsApp con el mensaje ya escrito; la propietaria sólo lo envía.
function whatsapp(p: any) {
  const tel = p.telefono.replace(/\D/g, '').slice(-10)
  const texto = `Hola ${p.perfiles?.nombre ?? ''}, te escribimos de Lizis Pastelería. Tu pedido ${p.folio} está: ${ESTADOS[p.estado].toLowerCase()}. ` +
    (p.modalidad === 'entrega' ? `Lo entregamos el ${fechaLarga(p.fecha_entrega)}, de ${p.horario}.` : `Puedes recogerlo el ${fechaLarga(p.fecha_entrega)}, de ${p.horario}.`)
  return `https://wa.me/52${tel}?text=${encodeURIComponent(texto)}`
}

function filtrar(e: string) {
  router.replace({ query: e ? { estado: e } : {} })
}
useHead({ title: 'Pedidos · Administración Lizis' })
</script>

<template>
  <div>
    <h1>Pedidos</h1>
    <div class="filtros">
      <button class="opcion" :class="{ activa: !estado }" @click="filtrar('')">Todos</button>
      <button v-for="e in ['pendiente_pago', 'pagado', 'en_preparacion', 'listo', 'entregado', 'cancelado']" :key="e" class="opcion" :class="{ activa: estado === e }" @click="filtrar(e)">{{ ESTADOS[e] }}</button>
    </div>
    <input v-model="busqueda" type="search" placeholder="Buscar por folio o cliente" style="max-width: 360px; margin-bottom: 16px">
    <div class="tarjeta desliza">
      <table class="tabla">
        <thead><tr><th>Folio</th><th>Cliente</th><th>Entrega</th><th>Estado</th><th class="num">Total</th><th /></tr></thead>
        <tbody>
          <template v-for="p in visibles" :key="p.id">
            <tr>
              <td><b>{{ p.folio }}</b><div class="suave chico">{{ fechaHora(p.creado_el) }}</div></td>
              <td>{{ p.perfiles?.nombre }}<div class="suave chico">{{ p.telefono }}</div></td>
              <td>{{ fechaLarga(p.fecha_entrega) }}<div class="suave chico">{{ p.horario }} · {{ p.modalidad === 'entrega' ? 'a domicilio' : 'recolección' }}</div></td>
              <td><EstadoPedido :estado="p.estado" /></td>
              <td class="num">{{ dinero(p.total) }}</td>
              <td><button class="boton chico secundario" @click="abierto = abierto === p.id ? null : p.id">{{ abierto === p.id ? 'Cerrar' : 'Ver' }}</button></td>
            </tr>
            <tr v-if="abierto === p.id">
              <td colspan="6" style="background: var(--crema)">
                <div class="dos">
                  <div class="pila">
                    <div v-for="i in p.pedido_items" :key="i.id" class="fila entre">
                      <span><b>{{ i.cantidad }} × {{ i.nombre }}</b> <span class="suave chico">{{ i.detalle }}</span></span>
                      <span>{{ dinero(i.importe) }}</span>
                    </div>
                    <div class="fila entre suave"><span>Envío</span><span>{{ dinero(p.envio) }}</span></div>
                    <div v-if="p.direccion"><b>Dirección:</b> {{ p.direccion }}</div>
                    <div v-if="p.notas"><b>Notas:</b> {{ p.notas }}</div>
                  </div>
                  <div class="pila">
                    <div class="fila">
                      <button v-if="SIGUIENTE[p.estado]" class="boton chico" @click="cambiar(p, SIGUIENTE[p.estado]!.estado)">{{ SIGUIENTE[p.estado]!.texto }}</button>
                      <button v-if="!['entregado', 'cancelado'].includes(p.estado)" class="boton chico peligro" @click="cambiar(p, 'cancelado')">Cancelar</button>
                      <a :href="whatsapp(p)" target="_blank" rel="noopener" class="boton chico secundario">Avisar por WhatsApp</a>
                    </div>
                    <ul class="tiempo">
                      <li v-for="h in [...p.historial_estados].sort((a, b) => a.creado_el.localeCompare(b.creado_el))" :key="h.id">
                        <b>{{ ESTADOS[h.estado] }}</b> <span class="suave chico">{{ fechaHora(h.creado_el) }}</span>
                      </li>
                    </ul>
                  </div>
                </div>
              </td>
            </tr>
          </template>
        </tbody>
      </table>
      <p v-if="!visibles.length" class="suave" style="margin: 0">No hay pedidos con ese filtro.</p>
    </div>
  </div>
</template>
