%{
  title: "Análisis de localización",
  summary:
    "Vea qué idiomas y países desean realmente sus visitantes, y dónde tiene una brecha de localización, antes de invertir en una nueva localización.",
  order: 6,
  icon: "Mundo",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidad, no vanidad",
      description:
        "Los tableros de control se estructuran en torno a la brecha de localización: la parte del tráfico que quiere un idioma que aún no ofrece.",
      icon: "Mundo"
    },
    %{
      title: "Sin cookies por diseño",
      description:
        "Sin cookies, sin huella digital, sin banners de consentimiento. Los visitantes únicos provienen de un hash que rota diariamente y no se puede vincular entre días.",
      icon: "Rápido"
    },
    %{
      title: "Una sola línea para instalar",
      description:
        "Inserte una etiqueta script en su sitio y Glossia se mide a sí misma. Distribuya vía npm o CDN.",
      icon: "Código"
    }
  ]
}
---
## Decide tu próxima localización con datos

La mayoría de los equipos eligen idiomas objetivo por intuición. El análisis de localización reemplaza eso por señales. Añade el SDK web y Glossia te muestra los idiomas que los navegadores de tus visitantes solicitan, los países de los que provienen y, crucialmente, la superposición con los idiomas que ya apoyas.

La métrica principal es el **brecha de localización**: el porcentaje de tus visitantes cuyo idioma preferido no tiene traducción soportada. Analízalo por país, por referrer y por página para ver exactamente dónde se concentra la demanda insatisfecha y cuál nueva localización haría mover la aguja.

## Privacidad sin compromiso

El análisis de Glossia no recopila nada de lo que no necesite y no almacena nada identificable. El navegador envía la URL de la página, el referrer, los idiomas preferidos, la zona horaria y el tamaño de la pantalla. El servidor obtiene el visitante único de un hash rotado diariamente de la IP y el User-Agent, y luego los descarta. No se establecen cookies, nada se fingerprintea y ningún visitante puede ser rastreado a través de días o entre sitios.

El resultado son análisis que puedes publicar sin un banner de consentimiento, alineado con las expectativas de privacidad que tus visitantes internacionales ya tienen.

## Instala en segundos

Añade una línea a tu sitio y Glossia empieza a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

¿Prefieres npm? Instala `@glossia/web` y llama `init({ domain })`. En cualquier caso, las vistas de página, la navegación del lado del cliente y los eventos personalizados fluyen hacia el mismo panel de control que clasifica tus oportunidades de localización.