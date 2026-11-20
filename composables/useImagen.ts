// Fotos con srcset para que cada pantalla baje sólo el ancho que muestra. Las de public/ tienen variantes WebP
// (scripts/imagenes.py, que escribe imagenes.json); las de Unsplash del catálogo de prueba cambian su parámetro w; las
// que se suben desde el panel (Supabase Storage) van tal cual.
import variantes from './imagenes.json'

type Variante = { ancho: number; alto: number; anchos: number[] }
const locales: Record<string, Variante> = variantes
const UNSPLASH = [160, 240, 320, 480, 640, 800, 960]
export const SIN_FOTO = '/marca/icono.png'

/** src y srcset de una imagen; el sizes lo pone quien sabe cuánto mide en la página. */
export function imagen(url?: string | null): { src: string; srcset?: string } {
  if (!url) return { src: SIN_FOTO }
  const v = locales[url]
  if (v) {
    const base = url.replace(/^\/(fotos|marca)\/(.+)\.\w+$/, '/$1/webp/$2')
    const media = v.anchos.find((w) => w >= 640) ?? v.anchos[v.anchos.length - 1]
    return { src: `${base}-${media}.webp`, srcset: v.anchos.map((w) => `${base}-${w}.webp ${w}w`).join(', ') }
  }
  if (url.startsWith('https://images.unsplash.com/') && /[?&]w=\d+/.test(url)) {
    const con = (w: number) => url.replace(/([?&])w=\d+/, `$1w=${w}`)
    return { src: con(640), srcset: UNSPLASH.map((w) => `${con(w)} ${w}w`).join(', ') }
  }
  return { src: url }
}

/** Una caja de la página: la condición de media (vacía en la última), su ancho en CSS y su proporción ancho / alto. */
export type Caja = [media: string, ancho: string, proporcion: number]

/**
 * src, srcset y sizes de una foto que llena su caja con object-fit: cover. Si la foto es más apaisada que la caja se
 * recorta por los lados y hace falta más ancho que el de la caja. Las de Unsplash del catálogo de prueba son 4:3.
 */
export function foto(url: string | null | undefined, cajas: Caja[]) {
  const { src, srcset } = imagen(url)
  if (!srcset) return { src }
  const v = url ? locales[url] : undefined
  const proporcion = v ? v.ancho / v.alto : 4 / 3
  const sizes = cajas.map(([media, ancho, caja]) => {
    const f = proporcion / caja
    const valor = f > 1.05 ? `calc(${ancho} * ${f.toFixed(2)})` : ancho
    return media ? `${media} ${valor}` : valor
  }).join(', ')
  return { src, srcset, sizes }
}
