%{
  title: "Analítica de localización",
  summary:
    "Vea qué idiomas y países desean realmente sus visitantes y dónde tiene una brecha de localización antes de invertir en un nuevo idioma.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidad, no vanidad",
      description:
        "Los paneles se basan en la brecha de localización: la cuota de tráfico que desea un idioma que aún no ofrece.",
      icon: "globe"
    },
    %{
      title: "Sin cookies por diseño",
      description:
        "Sin cookies, ni huellas, ni banners de consentimiento. Los visitantes únicos provienen de un hash rotado diariamente que no se puede vincular entre días.",
      icon: "zap"
    },
    %{
      title: "Una sola línea para instalar",
      description:
        "Agregue una etiqueta de script a su sitio y Glossia se medirá a sí misma. Publique vía npm o CDN.",
      icon: "code"
    }
  ]
}
---
## Decide tu próximo idioma de destino con datos

La mayoría de los equipos elige los idiomas de destino por intuición. La analítica de localización reemplaza eso con señales. Añade el web SDK y Glossia te muestra los idiomas que solicitan los navegadores de tus visitantes, los países de procedencia y, crucialmente, la coincidencia con los idiomas que ya soportas.

La métrica principal es la **brecha de localización**: el porcentaje de visitantes cuyos idiomas preferidos no tienen una traducción soportada. Analízala por país, por referente y por página para ver exactamente dónde se concentra la demanda no atendida y qué nuevo idioma de destino marcaría la diferencia.

## Privacidad sin compromisos

La analítica de Glossia no recopila nada que no necesite y no almacena nada identificable. El navegador envía la URL de la página, el referente, los idiomas preferidos, la zona horaria y el tamaño de pantalla. El servidor obtiene el visitante único a partir de un hash rotado diariamente de la IP y el User-Agent, y luego los descarta. No se establecen cookies, no se extraen huellas digitales y ningún visitante puede ser rastreado entre días o entre sitios.

El resultado es una analítica que puedes implementar sin un banner de consentimiento, alineada con las expectativas de privacidad que tus visitantes internacionales ya tienen.

## Instala en segundos

Añade una línea a tu sitio y Glossia comienza a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

¿Prefieres npm? Instala `@glossia/web` y llama `init({ domain })`. De cualquier forma, las vistas de página, la navegación del lado del cliente y los eventos personalizados terminan en el mismo panel que prioriza tus oportunidades de localización.