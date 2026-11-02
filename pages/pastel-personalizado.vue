<script setup lang="ts">
import { hoyMx, mensajeDeError } from '~/composables/useFormato'

const supabase = useSupabaseClient()
const usuario = useSupabaseUser()
const { perfil } = usePerfil()

const { data: ajustes } = await useAsyncData('ajustes-personalizado', async () => {
  const { data } = await supabase.from('ajustes').select('dias_anticipacion').eq('id', 1).single()
  return data
})
// La fecha mínima sigue la misma regla de anticipación que fija la propietaria en Ajustes.
const minimo = computed(() => {
  const [a, m, d] = hoyMx().split('-').map(Number)
  const f = new Date(a, m - 1, d + (ajustes.value?.dias_anticipacion ?? 2))
  return `${f.getFullYear()}-${String(f.getMonth() + 1).padStart(2, '0')}-${String(f.getDate()).padStart(2, '0')}`
})

const forma = reactive({ ocasion: 'Cumpleaños', tamano: '', sabor: '', decoracion: '', mensaje: '', fecha: '', telefono: perfil.value?.telefono ?? '' })
const archivo = ref<File | null>(null)
const error = ref('')
const listo = ref<string | null>(null)
const ocupado = ref(false)

function elegirArchivo(e: Event) {
  const f = (e.target as HTMLInputElement).files?.[0] ?? null
  error.value = ''
  if (f && f.size > 5 * 1024 * 1024) {
    error.value = 'La imagen pesa más de 5 MB'
    archivo.value = null
    return
  }
  archivo.value = f
}

async function enviar() {
  error.value = ''
  const id = (usuario.value as any)?.sub
  if (!id) return navigateTo({ path: '/entrar', query: { volver: '/pastel-personalizado' } })
  if (forma.fecha < minimo.value) return (error.value = 'Elige una fecha a partir de la mínima')
  ocupado.value = true
  try {
    let ruta: string | null = null
    if (archivo.value) {
      const ext = archivo.value.name.split('.').pop()?.toLowerCase() || 'jpg'
      ruta = `${id}/${Date.now()}.${ext}`
      const { error: e } = await supabase.storage.from('referencias').upload(ruta, archivo.value, { contentType: archivo.value.type })
      if (e) throw e
    }
    const { data, error: e } = await supabase.from('solicitudes').insert({
      usuario_id: id, ocasion: forma.ocasion, tamano: forma.tamano, sabor: forma.sabor, decoracion: forma.decoracion.trim(),
      mensaje: forma.mensaje.trim(), imagen_ref: ruta, fecha_deseada: forma.fecha, telefono: forma.telefono.trim()
    }).select('folio').single()
    if (e) throw e
    listo.value = data.folio
  } catch (e) {
    error.value = mensajeDeError(e)
  } finally {
    ocupado.value = false
  }
}
useHead({ title: 'Pastel personalizado · Lizis Pastelería' })
</script>

<template>
  <section class="seccion contenedor" style="max-width: 760px">
    <h1>Pastel personalizado</h1>
    <p class="suave">Cuéntanos qué necesitas. La pastelería revisa la solicitud y te envía la cotización a Mis pedidos.</p>
    <div v-if="listo" class="tarjeta pila">
      <p class="nota ok" style="margin: 0">Recibimos tu solicitud <b>{{ listo }}</b>. Verás la cotización en Mis pedidos.</p>
      <NuxtLink to="/mis-pedidos" class="boton">Ir a Mis pedidos</NuxtLink>
    </div>
    <div v-else-if="!usuario" class="tarjeta pila">
      <p style="margin: 0">Para solicitar un pastel personalizado inicia sesión o crea tu cuenta.</p>
      <NuxtLink :to="{ path: '/entrar', query: { volver: '/pastel-personalizado' } }" class="boton">Entrar</NuxtLink>
    </div>
    <form v-else class="tarjeta pila" @submit.prevent="enviar">
      <div class="dos" style="gap: 14px">
        <label class="campo"><span>Ocasión</span>
          <select v-model="forma.ocasion"><option>Cumpleaños</option><option>Boda</option><option>Bautizo</option><option>Graduación</option><option>Otra</option></select>
        </label>
        <label class="campo"><span>Tamaño</span>
          <select v-model="forma.tamano" required>
            <option value="" disabled>Elige</option><option>10 personas</option><option>20 personas</option><option>30 personas</option><option>50 personas</option>
          </select>
        </label>
        <label class="campo"><span>Sabor</span>
          <select v-model="forma.sabor" required>
            <option value="" disabled>Elige</option><option>Vainilla</option><option>Chocolate</option><option>Tres leches</option><option>Red velvet</option><option>Zanahoria</option>
          </select>
        </label>
        <label class="campo"><span>Fecha</span><input v-model="forma.fecha" type="date" :min="minimo" required></label>
      </div>
      <label class="campo"><span>Decoración</span><textarea v-model="forma.decoracion" placeholder="Colores, figuras, tema, betún o fondant" required /></label>
      <label class="campo"><span>Mensaje en el pastel <small>(opcional)</small></span><input v-model="forma.mensaje" maxlength="60" placeholder="Feliz cumpleaños, Ana"></label>
      <label class="campo"><span>Imagen de referencia <small>(opcional, hasta 5 MB)</small></span><input type="file" accept="image/jpeg,image/png,image/webp" @change="elegirArchivo"></label>
      <label class="campo"><span>Teléfono</span><input v-model="forma.telefono" type="tel" placeholder="10 dígitos" required pattern="[0-9 +()-]{10,20}"></label>
      <p v-if="error" class="error" style="margin: 0">{{ error }}</p>
      <button class="boton bloque" :disabled="ocupado">{{ ocupado ? 'Enviando...' : 'Enviar solicitud' }}</button>
    </form>
  </section>
</template>
