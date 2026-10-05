%{
  title: "Analíticas de localización",
  summary:
    "Ve qué idiomas y países realmente desean tus visitantes, y dónde tienes una brecha de localización, antes de invertir en una nueva localización.",
  order: 6,
  icon: "Mundo",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidad, no vanidad",
      description:
        "Los paneles de control están construidos en torno a la brecha de localización: la parte del tráfico que desea un idioma que aún no ofreces.",
      icon: "Mundo"
    },
    %{
      title: "Diseñado sin cookies",
      description:
        "Sin cookies, sin huellas, sin banners de consentimiento. Los visitantes únicos provienen de un hash rotado diariamente que no puede vincularse entre días.",
      icon: "Rápido"
    },
    %{
      title: "Una sola línea para instalar",
      description:
        "Inserta una etiqueta de script en tu sitio y Glossia se mide sola. Distribuye vía npm o CDN.",
      icon: "Código"
    }
  ]
}
---
## Decide tu próximo idioma con datos

La mayoría de los equipos elige los idiomas objetivos basándose en la intuición. La analítica de localización reemplaza eso por datos. Añade el SDK web y Glossia te muestra los idiomas que los navegadores de tus visitantes solicitan, los países de origen y, crucialmente, la superposición con los idiomas que ya soportas.

La métrica principal es la **brecha de localización**: el porcentaje de tus visitantes cuyo idioma preferido no tiene traducción soportada. Profundiza en ello por país, por referidor y por página para ver exactamente dónde se concentra la demanda subatendida y qué nuevo idioma marcaría la diferencia.

## Privacidad sin compromisos

La analítica de Glossia no recopila nada que no necesite ni almacene nada identificable. El navegador envía la URL de la página, el referidor, los idiomas preferidos, la zona horaria y el tamaño de la pantalla. El servidor deriva el visitante único a partir de un hash rotado diariamente de la IP y el User-Agent, y los descarta. No se establecen cookies, no se generan huellas digitales y ningún visitante puede ser rastreado entre días o sitios.

El resultado es analítica que puedes lanzar sin un banner de consentimiento, alineada con las expectativas de privacidad que ya tienen tus visitantes internacionales.

## Instalar en segundos

Añade una línea a tu sitio y Glossia empieza a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

¿Prefieres npm? Instala `@glossia/web` y llama `init({ domain })`. En cualquier caso, las vistas de página, la navegación del lado del cliente y los eventos personalizados fluyen hacia el mismo panel de control que prioriza tus oportunidades de localización.