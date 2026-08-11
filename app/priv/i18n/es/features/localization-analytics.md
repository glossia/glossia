%{
  title: "Analítica de localización",
  summary: "Descubra qué idiomas y países quieren realmente sus visitantes y dónde existe una brecha de localización antes de invertir en una nueva configuración regional.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Oportunidad, no vanidad", description: "Los paneles se centran en la brecha de localización: el porcentaje de tráfico que quiere un idioma que aún no ofrece.", icon: "globe"},
    %{title: "Sin cookies por diseño", description: "Sin cookies, huellas digitales ni avisos de consentimiento. Los visitantes únicos se identifican mediante un hash que rota a diario y no puede vincularse entre días.", icon: "zap"},
    %{title: "Una línea para instalar", description: "Añada una sola etiqueta de script a su sitio y Glossia se encargará de medirlo. Distribúyalo mediante npm o CDN.", icon: "code"}
  ]
}
---
## Decida su próximo idioma con datos

La mayoría de los equipos eligen los idiomas de destino por intuición. Las analíticas de localización sustituyen esa intuición por datos. Añada el SDK web y Glossia le mostrará los idiomas que solicitan los navegadores de sus visitantes, los países desde los que acceden y, sobre todo, su correspondencia con los idiomas que ya admite.

La métrica principal es la **brecha de localización**: el porcentaje de visitantes cuyo idioma preferido no tiene una traducción disponible. Analícela por país, referente y página para identificar con precisión dónde se concentra la demanda desatendida y qué nuevo idioma tendría mayor impacto.

## Privacidad sin concesiones

Las analíticas de Glossia solo recopilan lo necesario y no almacenan datos identificables. El navegador envía la URL de la página, el referente, los idiomas preferidos, la zona horaria y el tamaño de la pantalla. El servidor obtiene el visitante único mediante un hash de la dirección IP y el User-Agent que cambia a diario, y después los descarta. No se establecen cookies, no se crean huellas digitales y ningún visitante puede ser rastreado entre distintos días o sitios.

El resultado son unas analíticas que puede implementar sin un aviso de consentimiento y que respetan las expectativas de privacidad de sus visitantes internacionales.

## Instalación en segundos

Añada una línea a su sitio y Glossia comenzará a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

¿Prefiere npm? Instale `@glossia/web` y llame a `init({ domain })`. En ambos casos, las vistas de página, la navegación del lado del cliente y los eventos personalizados se envían al mismo panel que clasifica sus oportunidades de localización.