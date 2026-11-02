<script setup lang="ts">
import { dinero, fechaHora, fechaLarga, mensajeDeError } from '~/composables/useFormato'

definePageMeta({ layout: 'admin', middleware: 'admin' })
const supabase = useSupabaseClient()
const { avisar } = useAviso()
const cotizando = reactive<Record<number, { precio: string; respuesta: string }>>({})
const imagenes = reactive<Record<number, string>>({})

const { data: solicitudes, refresh } = await useAsyncData('admin-solicitudes', async () => {
  const { data } = await supabase.from('solicitudes').select('*, perfiles(nombre)').order('creado_el', { ascending: false })
  return data ?? []
})

// Las imágenes de referencia son privadas: se ven con una liga firmada que dura una hora.
onMounted(async () => {
  for (const s of solicitudes.value ?? []) {
    if (!s.imagen_ref) continue
    const { data } = await supabase.storage.from('referencias').createSignedUrl(s.imagen_ref, 3600)
    if (data) imagenes[s.id] = data.signedUrl
  }
})

function abrir(s: any) {
  cotizando[s.id] = { precio: s.cotizacion ?? '', respuesta: s.respuesta ?? '' }
}

async function cotizar(s: any) {
  const c = cotizando[s.id]
  const precio = Number(c.precio)
  if (!(precio > 0)) return avisar('Escribe el precio de la cotización')
  const { error } = await supabase.from('solicitudes').update({ cotizacion: precio, respuesta: c.respuesta.trim() || null, estado: 'cotizada' }).eq('id', s.id)
  avisar(error ? mensajeDeError(error) : `Cotización enviada a ${s.perfiles?.nombre ?? 'el cliente'}`)
  delete cotizando[s.id]
  await refresh()
}
useHead({ title: 'Pasteles personalizados · Administración Lizis' })
</script>

<template>
  <div class="pila">
    <h1>Pasteles personalizados</h1>
    <div v-for="s in solicitudes" :key="s.id" class="tarjeta">
      <div class="dos">
        <div class="pila">
          <div class="fila entre"><h3 style="margin: 0">{{ s.folio }} · {{ s.perfiles?.nombre }}</h3><EstadoPedido :estado="s.estado" /></div>
          <div><b>{{ s.ocasion }}</b> · {{ s.tamano }} · {{ s.sabor }} · para el {{ fechaLarga(s.fecha_deseada) }}</div>
          <div><b>Decoración:</b> {{ s.decoracion }}</div>
          <div v-if="s.mensaje"><b>Mensaje:</b> {{ s.mensaje }}</div>
          <div class="suave chico">Teléfono {{ s.telefono }} · recibida el {{ fechaHora(s.creado_el) }}</div>
          <div v-if="s.cotizacion !== null"><b>Cotización:</b> {{ dinero(s.cotizacion) }} <span v-if="s.respuesta" class="suave">· {{ s.respuesta }}</span></div>
          <template v-if="cotizando[s.id]">
            <div class="fila">
              <input v-model="cotizando[s.id].precio" type="number" min="1" step="1" placeholder="Precio" style="max-width: 140px">
              <input v-model="cotizando[s.id].respuesta" placeholder="Nota para el cliente (anticipo, entrega...)" style="flex: 1; min-width: 200px">
            </div>
            <div class="fila"><button class="boton chico" @click="cotizar(s)">Enviar cotización</button><button class="boton chico secundario" @click="delete cotizando[s.id]">Cancelar</button></div>
          </template>
          <div v-else-if="['recibida', 'cotizada'].includes(s.estado)"><button class="boton chico" @click="abrir(s)">{{ s.estado === 'recibida' ? 'Cotizar' : 'Cambiar cotización' }}</button></div>
        </div>
        <div>
          <img v-if="imagenes[s.id]" :src="imagenes[s.id]" alt="Imagen de referencia" style="border-radius: 12px; max-height: 260px; object-fit: cover">
          <p v-else class="suave chico">Sin imagen de referencia</p>
        </div>
      </div>
    </div>
    <p v-if="!solicitudes?.length" class="tarjeta suave">No hay solicitudes.</p>
  </div>
</template>
