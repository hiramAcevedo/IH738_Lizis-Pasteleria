# /// script
# requires-python = ">=3.11"
# dependencies = ["pillow>=11"]
# ///
"""Variantes WebP de las fotos y los logotipos de public/, para el srcset de cada imagen.

Por cada imagen de public/fotos y public/marca escribe <carpeta>/webp/<nombre>-<ancho>.webp, en una escalera de anchos
que no pasa del original, y composables/imagenes.json con el ancho, el alto y los anchos de cada una, que lee
composables/useImagen.ts. Los originales se quedan: el favicon y el correo de compra los usan tal cual.

Se corre otra vez al agregar o cambiar una foto de public/:

    uv run scripts/imagenes.py
"""
import json
from pathlib import Path

from PIL import Image, ImageOps

RAIZ = Path(__file__).resolve().parent.parent
PUBLICO = RAIZ / "public"
MANIFIESTO = RAIZ / "composables/imagenes.json"
# Fotos: de la miniatura del carrito a la foto de detalle en pantalla doble. Logotipos: de 41 a 62 px de ancho en pantalla.
ESCALERAS = {"fotos": [160, 240, 320, 480, 640, 800, 960], "marca": [80, 120, 160, 240]}
# Las capas de la portada son semitransparentes en casi todo el plato: el alfa a 60 pesa la mitad y no se distingue.
CALIDAD = {"fotos": dict(quality=78, alpha_quality=60), "marca": dict(quality=90)}
OMITIR = {"icono.png"}  # 170 px y 6 KB: el favicon y el respaldo de un producto sin foto


def anchos_de(ancho: int, escalera: list[int]) -> list[int]:
    """Los peldaños menores que el original (con un 10 % de holgura) y, arriba, el original o el último peldaño."""
    anchos = [w for w in escalera if w < ancho * 0.9]
    tope = min(ancho, escalera[-1])
    if not anchos or anchos[-1] != tope:
        anchos.append(tope)
    return anchos


manifiesto: dict[str, dict] = {}
filas = []
for carpeta, escalera in ESCALERAS.items():
    destino = PUBLICO / carpeta / "webp"
    destino.mkdir(exist_ok=True)
    for viejo in destino.glob("*.webp"):
        viejo.unlink()
    for ruta in sorted((PUBLICO / carpeta).iterdir()):
        if not ruta.is_file() or ruta.suffix.lower() not in {".jpg", ".jpeg", ".png", ".webp"} or ruta.name in OMITIR:
            continue
        with Image.open(ruta) as original:
            icc = original.info.get("icc_profile")
            im = ImageOps.exif_transpose(original)
            im = im.convert("RGBA" if im.has_transparency_data else "RGB")
        ancho, alto = im.size
        anchos = anchos_de(ancho, escalera)
        pesos = []
        for w in anchos:
            h = round(alto * w / ancho)
            chica = im if w == ancho else im.resize((w, h), Image.Resampling.LANCZOS, reducing_gap=3.0)
            salida = destino / f"{ruta.stem}-{w}.webp"
            chica.save(salida, "WEBP", method=6, icc_profile=icc or None, **CALIDAD[carpeta])
            pesos.append(salida.stat().st_size)
        manifiesto[f"/{carpeta}/{ruta.name}"] = {"ancho": ancho, "alto": alto, "anchos": anchos}
        filas.append((f"/{carpeta}/{ruta.name}", ruta.stat().st_size, list(zip(anchos, pesos))))

MANIFIESTO.write_text(
    "{\n" + ",\n".join(f'  "{k}": {json.dumps(v)}' for k, v in sorted(manifiesto.items())) + "\n}\n")
for nombre, peso, variantes in filas:
    print(f"{nombre:38} {peso / 1024:7.1f} KB  →  " + "  ".join(f"{w}: {p / 1024:.1f}" for w, p in variantes))
print(f"\n{sum(len(v) for *_, v in filas)} variantes de {len(filas)} imágenes; manifiesto en {MANIFIESTO.relative_to(RAIZ)}")
