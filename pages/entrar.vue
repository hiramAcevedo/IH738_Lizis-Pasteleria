<script setup lang="ts">
import { mensajeDeError } from '~/composables/useFormato'

const supabase = useSupabaseClient()
const route = useRoute()
const { cargar } = usePerfil()
const modo = ref<'entrar' | 'registro'>('entrar')
const forma = reactive({ nombre: '', correo: '', clave: '', clave2: '' })
const error = ref('')
const mensaje = ref('')
const ocupado = ref(false)
const volver = computed(() => (route.query.volver as string) || '/')

async function enviar() {
  error.value = ''
  mensaje.value = ''
  if (modo.value === 'registro') {
    if (forma.nombre.trim().length < 2) return (error.value = 'Escribe tu nombre')
    if (forma.clave.length < 8) return (error.value = 'La contraseña debe tener al menos 8 caracteres')
    if (forma.clave !== forma.clave2) return (error.value = 'Las contraseñas no coinciden')
  }
  ocupado.value = true
  try {
    if (modo.value === 'entrar') {
      const { error: e } = await supabase.auth.signInWithPassword({ email: forma.correo.trim(), password: forma.clave })
      if (e) throw e
    } else {
      const { data, error: e } = await supabase.auth.signUp({
        email: forma.correo.trim(), password: forma.clave, options: { data: { nombre: forma.nombre.trim() } }
      })
      if (e) throw e
      if (!data.session) {
        mensaje.value = 'Te enviamos un correo para confirmar la cuenta; después de confirmarla, inicia sesión.'
        modo.value = 'entrar'
        return
      }
    }
    // El estado del usuario se actualiza con el evento de Supabase; se espera un momento antes de cargar el perfil.
    await new Promise((r) => setTimeout(r, 150))
    await cargar()
    await navigateTo(volver.value)
  } catch (e) {
    error.value = mensajeDeError(e)
  } finally {
    ocupado.value = false
  }
}
useHead({ title: 'Entrar · Lizis Pastelería' })
</script>

<template>
  <section class="seccion contenedor" style="max-width: 480px">
    <h1>{{ modo === 'entrar' ? 'Inicia sesión' : 'Crea tu cuenta' }}</h1>
    <div class="opciones" style="margin-bottom: 16px">
      <button class="opcion" :class="{ activa: modo === 'entrar' }" @click="modo = 'entrar'">Ya tengo cuenta</button>
      <button class="opcion" :class="{ activa: modo === 'registro' }" @click="modo = 'registro'">Soy nuevo</button>
    </div>
    <form class="tarjeta pila" @submit.prevent="enviar">
      <label v-if="modo === 'registro'" class="campo"><span>Nombre</span><input v-model="forma.nombre" autocomplete="name" required></label>
      <label class="campo"><span>Correo</span><input v-model="forma.correo" type="email" autocomplete="email" required></label>
      <label class="campo"><span>Contraseña</span><input v-model="forma.clave" type="password" :autocomplete="modo === 'entrar' ? 'current-password' : 'new-password'" required></label>
      <label v-if="modo === 'registro'" class="campo"><span>Repite la contraseña</span><input v-model="forma.clave2" type="password" autocomplete="new-password" required></label>
      <p v-if="error" class="error" style="margin: 0">{{ error }}</p>
      <p v-if="mensaje" class="nota ok" style="margin: 0">{{ mensaje }}</p>
      <button class="boton bloque" :disabled="ocupado">{{ ocupado ? 'Un momento...' : modo === 'entrar' ? 'Entrar' : 'Crear cuenta' }}</button>
    </form>
  </section>
</template>
