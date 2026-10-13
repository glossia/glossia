%{
  title: "Analítica de localización",
  summary:
    "Vea qué idiomas y países quieren realmente sus visitantes y dónde tiene una brecha de localización, antes de invertir en un nuevo idioma.",
  order: 6,
  icon: "globo",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidad, no vanidad",
      description:
        "Los paneles de control se centran en la brecha de localización: la parte del tráfico que busca un idioma que aún no ofreces.",
      icon: "globo"
    },
    %{
      title: "Sin cookies por diseño",
      description:
        "Sin cookies, sin huellas digitales, sin avisos de consentimiento. Los visitantes únicos provienen de un hash rotado diariamente que no se puede vincular entre días.",
      icon: "relámpago"
    },
    %{
      title: "Una sola línea para instalar",
      description:
        "Inserte una etiqueta de script en su sitio y Glossia se mide por sí misma. Distribuya vía npm o CDN.",
      icon: "código"
    }
  ]
}
---

## Decide tu próximo idioma con datos

La mayoría de los equipos eligen los idiomas objetivo basándose en la intuición. La analítica de localización reemplaza eso con señales. Añade el SDK web y Glossia te mostrará los idiomas que los navegadores de tus visitantes solicitan, los países desde los que proceden y, crucialmente, la superposición con los idiomas que ya soportas.

El indicador principal es la **brecha de localización**: el porcentaje de tus visitantes cuyo idioma preferido no tiene una traducción soportada. Explóralo por país, por el remitente y por página para ver exactamente dónde se concentra la demanda subatendida y qué nuevo idioma movería la aguja.

## Privacidad sin concesiones

La analítica de Glossia no recopila nada que no necesite y no almacena nada identificable. El navegador envía la URL de la página, el remitente, los idiomas preferidos, la zona horaria y el tamaño de la pantalla. El servidor deriva al visitante único a partir de un hash rotado diariamente de la IP y User-Agent, y luego los descarta. No se establecen cookies, no se extraen huellas digitales, y ningún visitante puede ser rastreado a través de días o entre sitios.

El resultado son analíticas que puedes despliegas sin un banner de consentimiento, alineadas con las expectativas de privacidad que tus visitantes internacionales ya tienen.

## Instalación en segundos

Añade una línea a tu sitio y Glossia comienza a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

¿Prefieres npm? Instala `@glossia/web` y llama `init({ domain })`. De cualquier forma, las vistas de página, la navegación a nivel del cliente y los eventos personalizados fluyen al mismo panel que clasifica tus oportunidades de localización.
