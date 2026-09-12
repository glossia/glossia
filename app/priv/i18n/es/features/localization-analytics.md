%{
  title: "Analítica de localización",
  summary:
    "Descubre qué idiomas y países realmente desean tus visitantes, y dónde tienes una brecha de localización, antes de invertir en un nuevo idioma.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidad, no vanidad",
      description:
        "Los tableros están construidos en torno a la brecha de localización: la parte del tráfico que desea un idioma que aún no ofreces.",
      icon: "globe"
    },
    %{
      title: "Sin cookies por diseño",
      description:
        "Sin cookies, sin huella digital, sin avisos de consentimiento. Los visitantes únicos provienen de un hash rotado diariamente que no puede vincularse entre días.",
      icon: "zap"
    },
    %{
      title: "Una sola línea para instalar",
      description:
        "Añade una etiqueta script a tu sitio y Glossia se mide solo. Despliega vía npm o CDN.",
      icon: "code"
    }
  ]
}
---
## Define tu próxima localización con datos

La mayoría de los equipos elige los idiomas objetivo basándose en la intuición. La analítica de localización reemplaza eso con datos. Añade el SDK web y Glossia te muestra los idiomas que piden los navegadores de tus visitantes, los países de los que provienen y, crucialmente, la superposición con los idiomas que ya soportas.

La métrica principal es la **brecha de localización**: el porcentaje de tus visitantes cuya lengua preferida no tiene una traducción soportada. Profundiza en ella por país, por referencia y por página para ver exactamente dónde se concentra la demanda subatendida y qué nueva localización generaría impacto.

## Privacidad sin compromisos

La analítica de Glossia no recopila nada que no necesite y no almacena nada identificable. El navegador envía la URL de la página, la referencia, los idiomas preferidos, la zona horaria y el tamaño de pantalla. El servidor obtiene el visitante único de un hash rotado diariamente de la IP y el User-Agent, y luego los descarta. No se establecen cookies, no se realiza fingerprinting, y ningún visitante puede rastrearse entre días ni entre sitios.

El resultado es una analítica que puedes lanzar sin banner de consentimiento, alineada con las expectativas de privacidad que ya tienen tus visitantes internacionales.

## Instala en segundos

Añade una línea a tu sitio y Glossia empieza a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

¿Prefieres npm? Instala `@glossia/web` y llama a `init({ domain })`. De cualquier forma, las vistas de página, la navegación del lado del cliente y los eventos personalizados fluyen hacia el mismo panel que clasifica las oportunidades de localización.