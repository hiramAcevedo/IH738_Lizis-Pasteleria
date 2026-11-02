export interface Linea {
  clave: string
  producto_id: number
  slug: string
  nombre: string
  imagen: string | null
  variantes: { id: number; grupo: string; nombre: string; precio_extra: number }[]
  precio_unitario: number
  cantidad: number
}

// El carrito vive en el navegador (localStorage). Los precios que se cobran los vuelve a calcular la base al
// crear el pedido; los de aquí sólo sirven para mostrar.
export function useCarrito() {
  const lineas = useState<Linea[]>('carrito', () => [])
  const listo = useState('carrito-listo', () => false)

  if (import.meta.client && !listo.value) {
    listo.value = true
    try {
      lineas.value = JSON.parse(localStorage.getItem('lizis-carrito') || '[]')
    } catch {
      lineas.value = []
    }
    watch(lineas, (v) => {
      try {
        localStorage.setItem('lizis-carrito', JSON.stringify(v))
      } catch {}
    }, { deep: true })
  }

  const piezas = computed(() => lineas.value.reduce((s, l) => s + l.cantidad, 0))
  const subtotal = computed(() => lineas.value.reduce((s, l) => s + l.precio_unitario * l.cantidad, 0))

  function agregar(linea: Omit<Linea, 'clave'>) {
    const clave = `${linea.producto_id}-${linea.variantes.map((v) => v.id).sort((a, b) => a - b).join('.')}`
    const existente = lineas.value.find((l) => l.clave === clave)
    if (existente) existente.cantidad = Math.min(50, existente.cantidad + linea.cantidad)
    else lineas.value.push({ ...linea, clave })
  }
  function cambiar(clave: string, cantidad: number) {
    const l = lineas.value.find((x) => x.clave === clave)
    if (l) l.cantidad = Math.max(1, Math.min(50, cantidad))
  }
  function quitar(clave: string) {
    lineas.value = lineas.value.filter((l) => l.clave !== clave)
  }
  function vaciar() {
    lineas.value = []
  }
  return { lineas, piezas, subtotal, agregar, cambiar, quitar, vaciar }
}
