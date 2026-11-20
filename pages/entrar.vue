<script setup lang="ts">
import { mensajeDeError } from '~/composables/useFormato'

// Entrar, crear cuenta, confirmar el correo y recuperar la contraseña, todo en /entrar.
// Los enlaces de los correos de Supabase llegan aquí con ?token_hash=…&type=email (cuenta nueva) o &type=recovery.
type Modo = 'entrar' | 'registro' | 'recuperar' | 'nueva' | 'verificando' | 'listo'
type TipoEnlace = 'email' | 'signup' | 'recovery' | 'invite' | 'magiclink' | 'email_change'
const TIPOS: TipoEnlace[] = ['email', 'signup', 'recovery', 'invite', 'magiclink', 'email_change']

const supabase = useSupabaseClient()
const route = useRoute()
const router = useRouter()
const { cargar } = usePerfil()
// Con un enlace de correo en la dirección, la página abre ya en «revisando» para no mostrar el formulario un instante.
const modo = ref<Modo>(route.query.token_hash ? 'verificando' : 'entrar')
const forma = reactive({ nombre: '', correo: '', clave: '', clave2: '' })
const error = ref('')
const mensaje = ref('')
const ocupado = ref(false)
// El correo al que se puede volver a mandar la confirmación (cuenta recién creada o sin confirmar).
const porConfirmar = ref('')
const listo = ref({ titulo: '', texto: '' })
const volver = computed(() => (route.query.volver as string) || '/')
const regreso = () => `${window.location.origin}/entrar`

const titulos: Record<Modo, string> = {
  entrar: 'Inicia sesión',
  registro: 'Crea tu cuenta',
  recuperar: 'Recupera tu contraseña',
  nueva: 'Elige tu nueva contraseña',
  verificando: 'Un momento...',
  listo: ''
}
const titulo = computed(() => (modo.value === 'listo' ? listo.value.titulo : titulos[modo.value]))

function cambiar(m: Modo) {
  modo.value = m
  error.value = ''
  mensaje.value = ''
}

// El estado del usuario se actualiza con el evento de Supabase; se espera un momento antes de cargar el perfil.
async function sesionLista() {
  await new Promise((r) => setTimeout(r, 150))
  await cargar()
}

onMounted(async () => {
  const tokenHash = route.query.token_hash as string | undefined
  const tipo = route.query.type as TipoEnlace | undefined
  if (!tokenHash) return
  if (!tipo || !TIPOS.includes(tipo)) {
    modo.value = 'entrar'
    return
  }
  modo.value = 'verificando'
  // El enlace sirve una sola vez: se quita de la barra de direcciones en cuanto se lee.
  router.replace({ query: route.query.volver ? { volver: route.query.volver } : {} })
  const { error: e } = await supabase.auth.verifyOtp({ token_hash: tokenHash, type: tipo })
  if (e) {
    modo.value = tipo === 'recovery' ? 'recuperar' : 'entrar'
    error.value = mensajeDeError(e)
    return
  }
  await sesionLista()
  if (tipo === 'recovery') {
    modo.value = 'nueva'
  } else {
    listo.value = { titulo: 'Tu cuenta quedó confirmada', texto: 'Ya entraste con tu correo. Tu pedido y tus cotizaciones quedarán guardados en tu cuenta.' }
    modo.value = 'listo'
  }
})

async function enviar() {
  error.value = ''
  mensaje.value = ''
  if (modo.value === 'registro') {
    if (forma.nombre.trim().length < 2) return (error.value = 'Escribe tu nombre')
    if (forma.clave.length < 8) return (error.value = 'La contraseña debe tener al menos 8 caracteres')
    if (forma.clave !== forma.clave2) return (error.value = 'Las contraseñas no coinciden')
  }
  ocupado.value = true
  const correo = forma.correo.trim()
  try {
    if (modo.value === 'entrar') {
      const { error: e } = await supabase.auth.signInWithPassword({ email: correo, password: forma.clave })
      if (e) {
        if (e.message.includes('Email not confirmed')) porConfirmar.value = correo
        throw e
      }
    } else {
      const { data, error: e } = await supabase.auth.signUp({
        email: correo,
        password: forma.clave,
        options: { data: { nombre: forma.nombre.trim() }, emailRedirectTo: regreso() }
      })
      if (e) throw e
      if (!data.session) {
        porConfirmar.value = correo
        modo.value = 'entrar'
        mensaje.value = `Te enviamos un correo a ${correo} para confirmar tu cuenta. Abre el enlace del correo y quedarás dentro.`
        return
      }
    }
    await sesionLista()
    await navigateTo(volver.value)
  } catch (e) {
    error.value = mensajeDeError(e)
  } finally {
    ocupado.value = false
  }
}

async function reenviar() {
  error.value = ''
  mensaje.value = ''
  ocupado.value = true
  const { error: e } = await supabase.auth.resend({ type: 'signup', email: porConfirmar.value, options: { emailRedirectTo: regreso() } })
  ocupado.value = false
  if (e) error.value = mensajeDeError(e)
  else mensaje.value = `Te enviamos otra vez el correo de confirmación a ${porConfirmar.value}.`
}

async function recuperar() {
  error.value = ''
  mensaje.value = ''
  ocupado.value = true
  const { error: e } = await supabase.auth.resetPasswordForEmail(forma.correo.trim(), { redirectTo: regreso() })
  ocupado.value = false
  // No se dice si el correo tiene cuenta: la respuesta es la misma en los dos casos.
  if (e) error.value = mensajeDeError(e)
  else mensaje.value = 'Si hay una cuenta con ese correo, te enviamos un enlace para elegir una contraseña nueva.'
}

async function guardarClave() {
  error.value = ''
  if (forma.clave.length < 8) return (error.value = 'La contraseña debe tener al menos 8 caracteres')
  if (forma.clave !== forma.clave2) return (error.value = 'Las contraseñas no coinciden')
  ocupado.value = true
  const { error: e } = await supabase.auth.updateUser({ password: forma.clave })
  ocupado.value = false
  if (e) return (error.value = mensajeDeError(e))
  forma.clave = ''
  forma.clave2 = ''
  listo.value = { titulo: 'Tu contraseña cambió', texto: 'Ya entraste con tu nueva contraseña. La próxima vez, úsala para iniciar sesión.' }
  modo.value = 'listo'
}

useHead({ title: computed(() => `${titulo.value || 'Entrar'} · Lizis Pastelería`) })
</script>

<template>
  <section class="seccion contenedor" style="max-width: 480px">
    <h1>{{ titulo }}</h1>

    <div v-if="modo === 'verificando'" class="tarjeta">Estamos revisando tu enlace.</div>

    <div v-else-if="modo === 'listo'" class="tarjeta pila">
      <p class="nota ok" style="margin: 0">{{ listo.texto }}</p>
      <div class="fila">
        <NuxtLink to="/productos" class="boton">Ver productos</NuxtLink>
        <NuxtLink to="/mis-pedidos" class="boton secundario">Mis pedidos</NuxtLink>
      </div>
    </div>

    <template v-else-if="modo === 'recuperar'">
      <p class="suave">Escribe el correo de tu cuenta y te enviaremos un enlace para elegir una contraseña nueva.</p>
      <form class="tarjeta pila" @submit.prevent="recuperar">
        <label class="campo"><span>Correo</span><input v-model="forma.correo" type="email" autocomplete="email" required></label>
        <p v-if="error" class="error" style="margin: 0">{{ error }}</p>
        <p v-if="mensaje" class="nota ok" style="margin: 0">{{ mensaje }}</p>
        <button class="boton bloque" :disabled="ocupado">{{ ocupado ? 'Un momento...' : 'Enviar enlace' }}</button>
      </form>
      <p class="centro"><button type="button" class="boton-texto" @click="cambiar('entrar')">Volver a iniciar sesión</button></p>
    </template>

    <form v-else-if="modo === 'nueva'" class="tarjeta pila" @submit.prevent="guardarClave">
      <label class="campo"><span>Contraseña nueva</span><input v-model="forma.clave" type="password" autocomplete="new-password" required></label>
      <label class="campo"><span>Repite la contraseña</span><input v-model="forma.clave2" type="password" autocomplete="new-password" required></label>
      <p v-if="error" class="error" style="margin: 0">{{ error }}</p>
      <button class="boton bloque" :disabled="ocupado">{{ ocupado ? 'Un momento...' : 'Guardar contraseña' }}</button>
    </form>

    <template v-else>
      <div class="opciones" style="margin-bottom: 16px">
        <button class="opcion" :class="{ activa: modo === 'entrar' }" @click="cambiar('entrar')">Ya tengo cuenta</button>
        <button class="opcion" :class="{ activa: modo === 'registro' }" @click="cambiar('registro')">Soy nuevo</button>
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
      <p v-if="modo === 'entrar'" class="fila entre" style="margin-top: 14px">
        <button type="button" class="boton-texto" @click="cambiar('recuperar')">¿Olvidaste tu contraseña?</button>
        <button v-if="porConfirmar" type="button" class="boton-texto" :disabled="ocupado" @click="reenviar">Reenviar el correo de confirmación</button>
      </p>
    </template>
  </section>
</template>
