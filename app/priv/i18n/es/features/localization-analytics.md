%{
  title: "Análisis de localización",
  summary:
    "Descubre qué idiomas y países desean realmente tus visitantes y dónde tienes una brecha de localización antes de invertir en una nueva localización.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidad, no vanidad",
      description:
        "Los paneles de control se centran en la brecha de localización: la cuota de tráfico que busca un idioma que aún no ofrezcas.",
      icon: "globe"
    },
    %{
      title: "Diseñado sin cookies",
      description:
        "Sin cookies, sin huella digital, sin banners de consentimiento. Los visitantes únicos provienen de un hash de rotación diaria que no puede vincularse entre días.",
      icon: "zap"
    },
    %{
      title: "Una línea para instalar",
      description:
        "Inserta una etiqueta de script en tu sitio y Glossia se mide a sí misma. Despliega mediante npm o CDN.",
      icon: "code"
    }
  ]
}
---
## Decide tu próximo idioma con datos

La mayoría de los equipos elige los idiomas objetivo de instinto. La analítica de localización reemplaza eso con señales. Añade el SDK web y Glossia te muestra los idiomas que los navegadores de tus visitantes solicitan, los países desde donde provienen y, crucialmente, la superposición con los idiomas que ya soportas.

La métrica principal es la **brecha de localización**: el porcentaje de tus visitantes cuyo idioma preferido no tiene traducción soportada. Analízalo por país, por referer y por página para ver exactamente dónde se concentra la demanda no cubierta y qué nuevo idioma movería la aguja.

## Privacidad sin compromisos

Glossia analytics no recoge nada que no necesite y no almacena nada identificable. El navegador envía la URL de la página, el referer, los idiomas preferidos, la zona horaria y el tamaño de pantalla. El servidor deriva el visitante único a partir de un hash rotado diariamente de la IP y del User-Agent, luego los descarta. No se establecen cookies, nada se fingerprintea y ningún visitante puede ser rastreado a través de días o entre sitios.

El resultado es analítica que puedes publicar sin un banner de consentimiento, alineada con las expectativas de privacidad que tus visitantes internacionales ya tienen.

## Instala en segundos

Añade una línea a tu sitio y Glossia comienza a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

¿Prefieres npm? Instala `@glossia/web` y llama a `init({ domain })`. De cualquier manera, las vistas de página, la navegación del lado del cliente y los eventos personalizados fluyen hacia el mismo panel que clasifica tus oportunidades de localización.