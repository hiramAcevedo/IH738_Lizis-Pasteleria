<script setup lang="ts">
import { dinero } from '~/composables/useFormato'
const { lineas, subtotal, cambiar, quitar } = useCarrito()
useHead({ title: 'Carrito · Lizis Pastelería' })
</script>

<template>
  <section class="seccion contenedor">
    <h1>Carrito</h1>
    <ClientOnly>
      <div v-if="!lineas.length" class="tarjeta centro pila">
        <p>Tu carrito está vacío.</p>
        <NuxtLink to="/productos" class="boton">Ver productos</NuxtLink>
      </div>
      <div v-else class="dos">
        <div class="tarjeta desliza">
          <table class="tabla">
            <thead><tr><th>Producto</th><th>Cantidad</th><th class="num">Importe</th><th /></tr></thead>
            <tbody>
              <tr v-for="l in lineas" :key="l.clave">
                <td>
                  <div class="fila" style="flex-wrap: nowrap">
                    <img :src="l.imagen || '/favicon.svg'" :alt="l.nombre" class="miniatura">
                    <div>
                      <NuxtLink :to="`/productos/${l.slug}`"><b>{{ l.nombre }}</b></NuxtLink>
                      <div class="suave chico">{{ l.variantes.map((v) => `${v.grupo}: ${v.nombre}`).join(' · ') }}</div>
                      <div class="suave chico">{{ dinero(l.precio_unitario) }} c/u</div>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="cantidad">
                    <button aria-label="Menos" @click="cambiar(l.clave, l.cantidad - 1)">−</button>
                    <span>{{ l.cantidad }}</span>
                    <button aria-label="Más" @click="cambiar(l.clave, l.cantidad + 1)">+</button>
                  </div>
                </td>
                <td class="num">{{ dinero(l.precio_unitario * l.cantidad) }}</td>
                <td><button class="boton chico peligro" @click="quitar(l.clave)">Quitar</button></td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="tarjeta pila">
          <div class="fila entre"><span>Subtotal</span><b>{{ dinero(subtotal) }}</b></div>
          <p class="suave chico" style="margin: 0">El envío se calcula al elegir entrega a domicilio o recolección.</p>
          <NuxtLink to="/pedido/nuevo" class="boton bloque">Continuar con el pedido</NuxtLink>
          <NuxtLink to="/productos" class="boton secundario bloque">Seguir comprando</NuxtLink>
        </div>
      </div>
    </ClientOnly>
  </section>
</template>
