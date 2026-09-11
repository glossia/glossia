%{
  title: "Analítica de localización",
  summary:
    "Descubre qué idiomas y países realmente quieren tus visitantes, y dónde tienes una brecha de localización, antes de invertir en un nuevo idioma.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidad, no vanidad",
      description:
        "Los tableros se basan en la brecha de localización: la parte del tráfico que desea un idioma que aún no servimos.",
      icon: "globe"
    },
    %{
      title: "Sin cookies por diseño",
      description:
        "Sin cookies, sin huella digital, sin banners de consentimiento. Los visitantes únicos provienen de un hash rotado diariamente que no se puede vincular entre días.",
      icon: "zap"
    },
    %{
      title: "Una sola línea para instalar",
      description:
        "Inserta una etiqueta script única en tu sitio y Glossia se mide por sí misma. Distribuye vía npm o CDN.",
      icon: "code"
    }
  ]
}
---
## Define tu próxima localización con datos

La mayoría de los equipos elige los idiomas objetivo basándose en la intuición. La analítica de localización reemplaza eso con señales. Añade el SDK web y Glossia te muestra los idiomas que solicitan los navegadores de tus visitantes, los países de origen y, lo más importante, la solapación con los idiomas que ya soportas.

La métrica principal es la **brecha de localización**: el porcentaje de tus visitantes cuyo idioma preferido no tiene traducción compatible. Analízalo por país, por referente y por página para ver exactamente dónde se concentra la demanda no atendida y qué nueva localización tendría un impacto.

## Privacidad sin compromisos

La analítica de Glossia no recopila nada que no necesite y no almacena nada identificable. El navegador envía la URL de la página, el referente, los idiomas preferidos, la zona horaria y el tamaño de pantalla. El servidor deduce el visitante único a partir de un hash rotativo diario de la IP y el user-agent, y luego los descarta. No se establecen cookies, no se realiza huella digital y ningún visitante puede ser rastreado entre días o entre sitios.

El resultado es analítica que puedes desplegar sin un banner de consentimiento, alineada con las expectativas de privacidad que ya tienen tus visitantes internacionales.

## Instala en segundos

Añade una línea a tu sitio y Glossia comienza a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

¿Prefieres npm? Instala `@glossia/web` y llama `init({ domain })`. De cualquier forma, las vistas de página, la navegación del lado del cliente y los eventos personalizados convergen en el mismo tablero que ordena tus oportunidades de localización.