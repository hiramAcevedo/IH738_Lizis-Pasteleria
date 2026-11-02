<script setup lang="ts">
import { dinero, fechaLarga, mensajeDeError } from '~/composables/useFormato'

definePageMeta({ middleware: 'cuenta' })
const supabase = useSupabaseClient()
const { lineas, subtotal, vaciar } = useCarrito()
const { perfil } = usePerfil()

const { data } = await useAsyncData('reglas-entrega', async () => {
  const [a, f] = await Promise.all([
    supabase.from('ajustes').select('dias_anticipacion, capacidad_diaria, horarios, costo_envio').eq('id', 1).single(),
    supabase.rpc('fechas_entrega', { p_dias: 21 })
  ])
  return { ajustes: a.data, fechas: (f.data ?? []) as { fecha: string; ocupados: number; disponible: boolean }[] }
})

const forma = reactive({
  modalidad: 'entrega' as 'entrega' | 'recoleccion',
  fecha: '',
  horario: '',
  direccion: '',
  telefono: perfil.value?.telefono ?? '',
  notas: ''
})
const envio = computed(() => (forma.modalidad === 'entrega' ? Number(data.value?.ajustes?.costo_envio ?? 0) : 0))
const error = ref('')
const ocupado = ref(false)

async function confirmar() {
  error.value = ''
  if (!lineas.value.length) return (error.value = 'El carrito está vacío')
  if (!forma.fecha) return (error.value = 'Elige el día de entrega')
  if (!forma.horario) return (error.value = 'Elige el horario')
  ocupado.value = true
  try {
    // La base recalcula precios, revisa el cupo del día y devuelve el folio.
    const { data: folio, error: e } = await supabase.rpc('crear_pedido', {
      p_items: lineas.value.map((l) => ({ producto_id: l.producto_id, variantes: l.variantes.map((v) => v.id), cantidad: l.cantidad })),
      p_modalidad: forma.modalidad,
      p_fecha: forma.fecha,
      p_horario: forma.horario,
      p_direccion: forma.modalidad === 'entrega' ? forma.direccion : '',
      p_telefono: forma.telefono,
      p_notas: forma.notas
    })
    if (e) throw e
    vaciar()
    try {
      const { url } = await $fetch<{ url: string }>('/api/pagos/sesion', { method: 'POST', body: { folio } })
      window.location.href = url
    } catch {
      // Sin pasarela disponible el pedido queda registrado y se puede pagar después desde su página.
      await navigateTo(`/pedido/${folio}?pago=pendiente`)
    }
  } catch (e) {
    error.value = mensajeDeError(e)
    ocupado.value = false
  }
}
useHead({ title: 'Tu pedido · Lizis Pastelería' })
</script>

<template>
  <section class="seccion contenedor">
    <h1>Tu pedido</h1>
    <ClientOnly>
      <div v-if="!lineas.length" class="tarjeta centro pila">
        <p>Tu carrito está vacío.</p>
        <NuxtLink to="/productos" class="boton">Ver productos</NuxtLink>
      </div>
      <div v-else class="dos">
        <form class="tarjeta pila" @submit.prevent="confirmar">
          <div class="campo">
            <span>¿Cómo lo recibes?</span>
            <div class="opciones">
              <label class="opcion" :class="{ activa: forma.modalidad === 'entrega' }">
                <input v-model="forma.modalidad" type="radio" value="entrega"> Entrega a domicilio · {{ dinero(data?.ajustes?.costo_envio) }}
              </label>
              <label class="opcion" :class="{ activa: forma.modalidad === 'recoleccion' }">
                <input v-model="forma.modalidad" type="radio" value="recoleccion"> Recolección · sin costo
              </label>
            </div>
          </div>
          <label class="campo">
            <span>Día</span>
            <select v-model="forma.fecha" required>
              <option value="" disabled>Elige un día</option>
              <option v-for="f in data?.fechas" :key="f.fecha" :value="f.fecha" :disabled="!f.disponible">
                {{ fechaLarga(f.fecha) }}{{ f.disponible ? '' : ' · sin lugar' }}
              </option>
            </select>
            <small>Pedidos con {{ data?.ajustes?.dias_anticipacion }} días de anticipación; {{ data?.ajustes?.capacidad_diaria }} pedidos por día como máximo.</small>
          </label>
          <div class="campo">
            <span>Horario</span>
            <div class="opciones">
              <label v-for="h in data?.ajustes?.horarios" :key="h" class="opcion" :class="{ activa: forma.horario === h }">
                <input v-model="forma.horario" type="radio" :value="h"> {{ h }}
              </label>
            </div>
          </div>
          <label v-if="forma.modalidad === 'entrega'" class="campo">
            <span>Dirección de entrega</span>
            <textarea v-model="forma.direccion" rows="2" placeholder="Calle, número, colonia y referencias" required />
          </label>
          <label class="campo">
            <span>Teléfono</span>
            <input v-model="forma.telefono" type="tel" inputmode="tel" placeholder="10 dígitos" required>
          </label>
          <label class="campo">
            <span>Notas para la pastelería <small>(opcional)</small></span>
            <textarea v-model="forma.notas" rows="2" placeholder="Por ejemplo: sin nuez en la caja de brownies" />
          </label>
          <p v-if="error" class="error" style="margin: 0">{{ error }}</p>
          <button class="boton bloque" :disabled="ocupado">{{ ocupado ? 'Registrando el pedido...' : `Confirmar y pagar ${dinero(subtotal + envio)}` }}</button>
          <p class="suave chico" style="margin: 0">El pago se hace en la página segura de Stripe; Lizis Pastelería no guarda datos de tarjetas.</p>
        </form>
        <div class="tarjeta pila">
          <h3>Resumen</h3>
          <div v-for="l in lineas" :key="l.clave" class="fila entre">
            <div><b>{{ l.cantidad }} × {{ l.nombre }}</b><div class="suave chico">{{ l.variantes.map((v) => v.nombre).join(' · ') }}</div></div>
            <span>{{ dinero(l.precio_unitario * l.cantidad) }}</span>
          </div>
          <hr style="border: 0; border-top: 1px solid var(--linea)">
          <div class="fila entre"><span>Subtotal</span><span>{{ dinero(subtotal) }}</span></div>
          <div class="fila entre"><span>Envío</span><span>{{ dinero(envio) }}</span></div>
          <div class="fila entre"><b>Total</b><b>{{ dinero(subtotal + envio) }}</b></div>
        </div>
      </div>
    </ClientOnly>
  </section>
</template>
