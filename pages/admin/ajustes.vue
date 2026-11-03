<script setup lang="ts">
import { mensajeDeError } from '~/composables/useFormato'

definePageMeta({ layout: 'admin', middleware: 'admin' })
const supabase = useSupabaseClient()
const { avisar } = useAviso()

const { data: ajustes } = await useAsyncData('admin-ajustes', async () => {
  const { data } = await supabase.from('ajustes').select('*').eq('id', 1).single()
  return data
})
const forma = reactive({
  dias_anticipacion: ajustes.value?.dias_anticipacion ?? 2,
  capacidad_diaria: ajustes.value?.capacidad_diaria ?? 6,
  horarios: (ajustes.value?.horarios ?? []).join('\n'),
  costo_envio: ajustes.value?.costo_envio ?? 0,
  whatsapp: ajustes.value?.whatsapp ?? '',
  instagram: ajustes.value?.instagram ?? '',
  facebook: ajustes.value?.facebook ?? ''
})

async function guardar() {
  const horarios = forma.horarios.split('\n').map((h) => h.trim()).filter(Boolean)
  if (!horarios.length) return avisar('Escribe al menos un horario')
  const { error } = await supabase.from('ajustes').update({
    dias_anticipacion: Number(forma.dias_anticipacion), capacidad_diaria: Number(forma.capacidad_diaria), horarios, costo_envio: Number(forma.costo_envio),
    whatsapp: forma.whatsapp.trim() || null, instagram: forma.instagram.trim() || null, facebook: forma.facebook.trim() || null
  }).eq('id', 1)
  avisar(error ? mensajeDeError(error) : 'Ajustes guardados')
}
useHead({ title: 'Ajustes · Administración Lizis' })
</script>

<template>
  <div class="pila" style="max-width: 640px">
    <h1>Ajustes de la tienda</h1>
    <p class="suave">Las reglas con las que la tienda ofrece fechas y horarios. Los valores de esta versión de prueba son provisionales hasta que la propietaria los confirme.</p>
    <form class="tarjeta pila" @submit.prevent="guardar">
      <label class="campo"><span>Días de anticipación</span><input v-model="forma.dias_anticipacion" type="number" min="0" max="30"><small>Un pedido hecho hoy se entrega a partir de hoy más estos días.</small></label>
      <label class="campo"><span>Pedidos por día</span><input v-model="forma.capacidad_diaria" type="number" min="1" max="100"><small>Al llenarse, el día ya no se ofrece.</small></label>
      <label class="campo"><span>Horarios de entrega</span><textarea v-model="forma.horarios" rows="4" /><small>Uno por renglón.</small></label>
      <label class="campo"><span>Costo de envío a domicilio (MXN)</span><input v-model="forma.costo_envio" type="number" min="0" step="1"></label>
      <label class="campo"><span>WhatsApp de la pastelería</span><input v-model="forma.whatsapp" type="tel" placeholder="10 dígitos"><small>Aparece en el pie de la tienda como botón para escribir.</small></label>
      <label class="campo"><span>Instagram</span><input v-model="forma.instagram" placeholder="usuario o dirección completa"></label>
      <label class="campo"><span>Facebook</span><input v-model="forma.facebook" placeholder="página o dirección completa"><small>Lo que quede vacío no se muestra en la tienda.</small></label>
      <button class="boton">Guardar</button>
    </form>
  </div>
</template>
