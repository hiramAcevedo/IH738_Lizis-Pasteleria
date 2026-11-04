export interface Paleta {
  id: string
  nombre: string
  detalle: string
  muestras: string[]
  logo: string
  logoPie: string
}

// Las combinaciones de color que se exploraron al implementar la tienda, para que la propietaria elija la definitiva.
// La primera, Coral, es la que propone el equipo. Todas conservan la página blanca; cambian la barra de aviso, el pie,
// los botones, los títulos y el logo. Los valores viven en main.css.
export const PALETAS: Paleta[] = [
  {
    id: 'coral',
    nombre: 'Coral',
    detalle: 'Barra de aviso, pie y botones en coral; títulos en vino y paneles en galleta.',
    muestras: ['#be514c', '#752a32', '#f6e3c9', '#ffffff'],
    logo: '/marca/logo-lizis-coral.png',
    logoPie: '/marca/logo-lizis-blanco.png',
  },
  {
    id: 'cafe',
    nombre: 'Café',
    detalle: 'Barra de aviso, pie y botones en café; títulos en cacao y paneles en galleta.',
    muestras: ['#9a644b', '#542624', '#f6e3c9', '#ffffff'],
    logo: '/marca/logo-lizis.png',
    logoPie: '/marca/logo-lizis-blanco.png',
  },
  {
    id: 'cacao',
    nombre: 'Cacao',
    detalle: 'Barra de aviso y pie en cacao con letras crema; botones en café y paneles en galleta.',
    muestras: ['#542624', '#9a644b', '#f6e3c9', '#ffffff'],
    logo: '/marca/logo-lizis.png',
    logoPie: '/marca/logo-lizis-crema.png',
  },
  {
    id: 'galleta',
    nombre: 'Galleta',
    detalle: 'Barra de aviso y pie en galleta con letras cacao; botones en café.',
    muestras: ['#f6e3c9', '#542624', '#9a644b', '#ffffff'],
    logo: '/marca/logo-lizis.png',
    logoPie: '/marca/logo-lizis.png',
  },
]

// /?paleta=cacao deja la paleta puesta en una cookie mientras se navega; /?paleta= vuelve a la primera de la lista.
export function usePaleta() {
  const cookie = useCookie<string | null>('paleta', { maxAge: 60 * 60 * 24 * 30, sameSite: 'lax' })
  const elegida = useState<string | null>('paleta', () => cookie.value ?? null)
  const paleta = computed(() => PALETAS.find((p) => p.id === elegida.value) ?? PALETAS[0])

  function elegir(id: string | null) {
    const valida = PALETAS.some((p) => p.id === id) ? id : null
    elegida.value = valida
    cookie.value = valida
  }

  return { paleta, elegir }
}
