<script setup lang="ts">
import { dinero, mensajeDeError } from '~/composables/useFormato'

definePageMeta({ layout: 'admin', middleware: 'admin' })
const supabase = useSupabaseClient()
const { avisar } = useAviso()

const { data, refresh } = await useAsyncData('admin-productos', async () => {
  const [p, c] = await Promise.all([
    supabase.from('productos').select('*, categorias(nombre), variantes(id, grupo, nombre, precio_extra, orden)').order('categoria_id').order('id'),
    supabase.from('categorias').select('id, nombre').order('orden')
  ])
  return { productos: p.data ?? [], categorias: c.data ?? [] }
})

const vacio = () => ({ id: null as number | null, nombre: '', slug: '', categoria_id: null as number | null, precio: '', descripcion: '', ingredientes: '', alergenos: '', imagen_url: '', destacado: false, visible: true })
const forma = ref<ReturnType<typeof vacio> | null>(null)
const variantes = ref<{ id?: number; grupo: string; nombre: string; precio_extra: string | number }[]>([])
const borradas = ref<number[]>([])
const foto = ref<File | null>(null)
const ocupado = ref(false)

function nuevo() {
  forma.value = vacio()
  forma.value.categoria_id = data.value?.categorias[0]?.id ?? null
  variantes.value = []
  borradas.value = []
  foto.value = null
}
function editar(p: any) {
  forma.value = { id: p.id, nombre: p.nombre, slug: p.slug, categoria_id: p.categoria_id, precio: p.precio, descripcion: p.descripcion, ingredientes: p.ingredientes, alergenos: p.alergenos, imagen_url: p.imagen_url ?? '', destacado: p.destacado, visible: p.visible }
  variantes.value = [...p.variantes].sort((a: any, b: any) => a.grupo.localeCompare(b.grupo) || a.orden - b.orden).map((v: any) => ({ ...v }))
  borradas.value = []
  foto.value = null
}
function slugDe(texto: string) {
  return texto.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')
}

async function guardar() {
  const f = forma.value!
  if (!f.nombre.trim() || !(Number(f.precio) >= 0) || !f.categoria_id) return avisar('Nombre, categoría y precio son obligatorios')
  ocupado.value = true
  try {
    let imagen = f.imagen_url || null
    if (foto.value) {
      const ext = foto.value.name.split('.').pop()?.toLowerCase() || 'jpg'
      const ruta = `${slugDe(f.nombre)}-${Date.now()}.${ext}`
      const { error } = await supabase.storage.from('productos').upload(ruta, foto.value, { contentType: foto.value.type })
      if (error) throw error
      imagen = supabase.storage.from('productos').getPublicUrl(ruta).data.publicUrl
    }
    const fila = {
      nombre: f.nombre.trim(), slug: f.slug || slugDe(f.nombre), categoria_id: f.categoria_id, precio: Number(f.precio),
      descripcion: f.descripcion.trim(), ingredientes: f.ingredientes.trim(), alergenos: f.alergenos.trim(),
      imagen_url: imagen, destacado: f.destacado, visible: f.visible
    }
    const r = f.id
      ? await supabase.from('productos').update(fila).eq('id', f.id).select('id').single()
      : await supabase.from('productos').insert(fila).select('id').single()
    if (r.error) throw r.error
    const id = r.data.id
    if (borradas.value.length) await supabase.from('variantes').delete().in('id', borradas.value)
    for (const [i, v] of variantes.value.entries()) {
      if (!v.grupo.trim() || !v.nombre.trim()) continue
      const datos = { producto_id: id, grupo: v.grupo.trim(), nombre: v.nombre.trim(), precio_extra: Number(v.precio_extra) || 0, orden: i + 1 }
      const e = v.id ? (await supabase.from('variantes').update(datos).eq('id', v.id)).error : (await supabase.from('variantes').insert(datos)).error
      if (e) throw e
    }
    avisar(f.id ? 'Producto actualizado' : 'Producto creado')
    forma.value = null
    await refresh()
  } catch (e) {
    avisar(mensajeDeError(e))
  } finally {
    ocupado.value = false
  }
}

async function alternar(p: any) {
  const { error } = await supabase.from('productos').update({ visible: !p.visible }).eq('id', p.id)
  avisar(error ? mensajeDeError(error) : p.visible ? `${p.nombre} quedó oculto en la tienda` : `${p.nombre} vuelve a la tienda`)
  await refresh()
}
useHead({ title: 'Productos · Administración Lizis' })
</script>

<template>
  <div class="pila">
    <div class="fila entre"><h1 style="margin: 0">Productos</h1><button class="boton" @click="nuevo">Nuevo producto</button></div>

    <form v-if="forma" class="tarjeta pila" @submit.prevent="guardar">
      <h3>{{ forma.id ? `Editar: ${forma.nombre}` : 'Nuevo producto' }}</h3>
      <div class="dos" style="gap: 14px">
        <label class="campo"><span>Nombre</span><input v-model="forma.nombre" required></label>
        <label class="campo"><span>Categoría</span>
          <select v-model="forma.categoria_id"><option v-for="c in data?.categorias" :key="c.id" :value="c.id">{{ c.nombre }}</option></select>
        </label>
        <label class="campo"><span>Precio base (MXN)</span><input v-model="forma.precio" type="number" min="0" step="0.5" required></label>
        <label class="campo"><span>Foto</span><input type="file" accept="image/jpeg,image/png,image/webp" @change="foto = ($event.target as HTMLInputElement).files?.[0] ?? null"></label>
      </div>
      <label class="campo"><span>Descripción</span><textarea v-model="forma.descripcion" rows="2" /></label>
      <div class="dos" style="gap: 14px">
        <label class="campo"><span>Ingredientes</span><textarea v-model="forma.ingredientes" rows="2" /></label>
        <label class="campo"><span>Alérgenos</span><textarea v-model="forma.alergenos" rows="2" /></label>
      </div>
      <div class="fila">
        <label class="opcion"><input v-model="forma.visible" type="checkbox"> Visible en la tienda</label>
        <label class="opcion"><input v-model="forma.destacado" type="checkbox"> Destacado en el inicio</label>
      </div>
      <div class="campo">
        <span>Variantes (una opción por grupo; el precio extra se suma al precio base)</span>
        <div v-for="(v, i) in variantes" :key="i" class="fila">
          <input v-model="v.grupo" placeholder="Grupo: Presentación" style="max-width: 200px">
          <input v-model="v.nombre" placeholder="Opción: Caja de 4" style="max-width: 200px">
          <input v-model="v.precio_extra" type="number" min="0" step="0.5" placeholder="Extra" style="max-width: 110px">
          <button type="button" class="boton chico peligro" @click="v.id && borradas.push(v.id); variantes.splice(i, 1)">Quitar</button>
        </div>
        <div><button type="button" class="boton chico secundario" @click="variantes.push({ grupo: variantes.at(-1)?.grupo ?? 'Presentación', nombre: '', precio_extra: 0 })">Agregar opción</button></div>
      </div>
      <div class="fila">
        <button class="boton" :disabled="ocupado">{{ ocupado ? 'Guardando...' : 'Guardar' }}</button>
        <button type="button" class="boton secundario" @click="forma = null">Cancelar</button>
      </div>
    </form>

    <div class="tarjeta desliza">
      <table class="tabla">
        <thead><tr><th>Producto</th><th>Categoría</th><th>Opciones</th><th class="num">Precio</th><th>En la tienda</th><th /></tr></thead>
        <tbody>
          <tr v-for="p in data?.productos" :key="p.id" :style="p.visible ? '' : 'opacity: 0.55'">
            <td><div class="fila" style="flex-wrap: nowrap"><img :src="p.imagen_url || '/favicon.svg'" alt="" class="miniatura"><b>{{ p.nombre }}</b></div></td>
            <td>{{ p.categorias?.nombre }}</td>
            <td class="suave chico">{{ p.variantes.map((v: any) => v.nombre).join(', ') || 'Sin opciones' }}</td>
            <td class="num">{{ dinero(p.precio) }}</td>
            <td>{{ p.visible ? 'Visible' : 'Oculto' }}{{ p.destacado ? ' · destacado' : '' }}</td>
            <td><div class="fila" style="flex-wrap: nowrap"><button class="boton chico secundario" @click="editar(p)">Editar</button><button class="boton chico secundario" @click="alternar(p)">{{ p.visible ? 'Ocultar' : 'Mostrar' }}</button></div></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
