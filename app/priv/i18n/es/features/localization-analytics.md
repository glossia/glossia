%{
  title: "Análisis de localización",
  summary:
    "Descubra qué idiomas y países desean realmente sus visitantes y dónde tiene una brecha de localización antes de invertir en un nuevo idioma.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidad, no vanidad",
      description:
        "Los paneles de control se construyen en torno a la brecha de localización: el porcentaje de tráfico que desea un idioma que aún no ofrece.",
      icon: "globe"
    },
    %{
      title: "Diseñado sin cookies",
      description:
        "Sin cookies, sin huellas digitales, sin banners de consentimiento. Los visitantes únicos provienen de un hash que se rota diariamente y no se puede vincular entre días.",
      icon: "zap"
    },
    %{
      title: "Una sola línea para instalar",
      description:
        "Inserte una etiqueta de script en su sitio y que Glossia recopile las métricas por sí misma. Despliegue vía npm o CDN.",
      icon: "code"
    }
  ]
}
---
## Decide tu próximo idioma con datos

La mayoría de los equipos elige idiomas objetivo basándose en intuición. El análisis de localización reemplaza eso con señales. Agrega el SDK web y Glossia te muestra los idiomas que solicitan los navegadores de tus visitantes, los países de origen, y, crucialmente, la superposición con los idiomas que ya soportas.

La métrica principal es la **brecha de localización**: el porcentaje de tus visitantes cuyo idioma preferido no tiene traducción soportada. Examínalo por país, por referidor y por página para ver exactamente dónde se concentra la demanda no atendida y qué nuevo idioma marcaría la diferencia.

## Privacidad sin compromisos

Las analíticas de Glossia no recopilan nada que no sea necesario y no almacenan nada identificable. El navegador envía la URL de la página, el referidor, los idiomas preferidos, la zona horaria y el tamaño de pantalla. El servidor deduce el visitante único a partir de un hash rotado diariamente de la IP y el User-Agent, y luego los descarta. No se establecen cookies, no se registra ninguna huella digital, y ningún visitante puede ser rastreado entre días o entre sitios.

El resultado son analíticas que puedes lanzar sin un banner de consentimiento, alineadas con las expectativas de privacidad que ya tienen tus visitantes internacionales.

## Instala en segundos

Agrega una línea a tu sitio y Glossia comienza a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

¿Prefieres npm? Instala `@glossia/web` y llama a `init({ domain })`. De cualquier manera, las vistas de página, la navegación del lado del cliente y los eventos personalizados fluyen hacia el mismo panel que prioriza tus oportunidades de localización.