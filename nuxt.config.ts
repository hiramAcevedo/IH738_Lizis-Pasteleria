// Lizis Pastelería · prototipo de Proyecto VI
// Nuxt 3 (Vue) con rutas de servidor en Vercel; datos, cuentas y fotos en Supabase; pagos de prueba con Stripe.
export default defineNuxtConfig({
  compatibilityDate: '2026-11-01',
  devtools: { enabled: false },
  modules: ['@nuxtjs/supabase'],
  css: ['~/assets/css/main.css'],
  app: {
    head: {
      htmlAttrs: { lang: 'es-MX' },
      title: 'Lizis Pastelería',
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: 'Roles de canela, brownies, galletas, tartaletas y pasteles personalizados en Guadalajara, con pedido y pago en línea.' }
      ],
      link: [
        { rel: 'icon', type: 'image/svg+xml', href: '/favicon.svg' },
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Playfair+Display:wght@600;700&display=swap' }
      ]
    }
  },
  // Las rutas protegidas las cuida middleware/ (cuenta y administración), no la redirección del módulo.
  supabase: { redirect: false, types: false },
  runtimeConfig: {
    claveServidor: '',
    stripeSecretKey: ''
  }
})
