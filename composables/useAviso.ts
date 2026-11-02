export function useAviso() {
  const texto = useState<string>('aviso', () => '')
  let reloj: ReturnType<typeof setTimeout> | undefined
  function avisar(mensaje: string) {
    texto.value = mensaje
    clearTimeout(reloj)
    reloj = setTimeout(() => (texto.value = ''), 2800)
  }
  return { texto, avisar }
}
