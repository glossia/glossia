%{
  title: "Análisis de localización",
  summary:
    "Descubre qué idiomas y países desean realmente tus visitantes y dónde tienes una brecha de localización antes de invertir en un nuevo idioma.",
  order: 6,
  icon: "Mundo",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidad, no vanidad",
      description:
        "Los tableros se construyen en torno a la brecha de localización: la cuota de tráfico que desea un idioma que aún no ofreces.",
      icon: "Mundo"
    },
    %{
      title: "Sin cookies por diseño",
      description:
        "Sin cookies, ni huella digital, ni banners de consentimiento. Los visitantes únicos provienen de un hash rotado diariamente que no se puede vincular entre días.",
      icon: "Rayo"
    },
    %{
      title: "Una línea para instalar",
      description:
        "Añade una etiqueta script a tu sitio y Glossia mide automáticamente. Despliega vía npm o CDN.",
      icon: "Código"
    }
  ]
}
---

## Decide tu siguiente localización con datos

La mayoría de los equipos elige los idiomas objetivo por intuición. La analítica de localización sustituye eso por señales. Añade el SDK web y Glossia te muestra los idiomas que solicitan los navegadores de tus visitantes, los países de procedencia y, crucialmente, el solapamiento con los idiomas que ya soportas.

La métrica principal es la **brecha de localización**: el porcentaje de tus visitantes cuyo idioma preferido no tiene una traducción soportada. Desglosa esta métrica por país, por referencia y por página para ver exactamente dónde se concentra la demanda no atendida y qué nuevo idioma movería la aguja.

## Privacidad sin compromisos

La analítica de Glossia no recopila nada innecesario ni almacena nada identificable. El navegador envía la URL de la página, la referencia, los idiomas preferidos, la zona horaria y el tamaño de pantalla. El servidor obtiene el visitante único a partir de un hash rotado diariamente de la IP y el User-Agent, luego los descarta. No se establecen cookies, nada es identificado mediante huella digital y ningún visitante puede ser rastreado a través de días o entre sitios.

El resultado es una analítica que puedes implementar sin un banner de consentimiento, alineada con las expectativas de privacidad que tus visitantes internacionales ya tienen.

## Instalar en segundos

Añade una línea a tu sitio y Glossia empieza a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

¿Prefieres npm? Instala `@glossia/web` y llama a `init({ domain })`. De cualquier forma, las vistas de página, la navegación a nivel del cliente y los eventos personalizados fluyen al mismo dashboard que clasifica tus oportunidades de localización.
