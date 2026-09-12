%{
  title: "¿Por qué el análisis de localización?",
  summary:
    "Cómo las señales recopiladas se traducen en decisiones de localización, y por qué importa la métrica de brecha.",
  category: "explicación",
  order: 2
}
---
Elegir qué idioma traducir a continuación es una apuesta: cuesta tiempo y dinero, y el retorno depende de una demanda que generalmente no puedes ver. La analítica de localización hace que esa demanda sea visible.

## La decisión, no el panel

El propósito de recopilar analíticas aquí es estrecho y deliberado: para responder "¿debemos localizar en el idioma X?". Las señales están seleccionadas para responder a esa pregunta, no para ser una suite de analíticas de propósito general.

Tres entradas impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país te indican dónde está el interés.
2. **La brecha.** ¿Esa demanda ya está atendida? Comparar idiomas preferidos contra los idiomas objetivo del proyecto revela la proporción de tráfico que choca contra un muro.
3. **Valor.** ¿Vale la pena localizar? La brecha de compromiso por idioma, las páginas donde aterriza el tráfico no atendido, y el origen de ese tráfico indican si una nueva localización convierte.

## Por qué el hueco se calcula en el tiempo de ingestión

`served_locale` y `has_locale_gap` se guardan por evento, calculados contra tus idiomas objetivo según fuesen en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no un recálculo contra los objetivos actuales. Si agregas portugués el próximo mes, el hueco del mes pasado no se encoge retroactivamente; mantienes un registro honesto de cuánto demanda estaba sin atender.

## Por qué sin cookies, específicamente

El instinto cuando deseas "visitas únicas" es establecer una cookie o tomar la huella del navegador. Ambos generan identificadores de larga duración, y la identificación por huella es, bajo la mayoría de los regímenes de privacidad, más difícil de borrar que una cookie. Ninguno es necesario aquí.

Las visitas únicas de un día solo requieren un identificador que sea estable *dentro del día*. Un hash de la IP y User-Agent, rotado diariamente y limitado por proyecto, proporciona únicos diarios y semanales precisos y hace imposible vincular un visitante entre días o entre sitios. Se renuncia al seguimiento a largo plazo de visitantes recurrentes, que es exactamente la capacidad que genera la exposición de privacidad para la que necesitarías un banner de consentimiento para operar legalmente.

El compromiso es intencional: las analíticas de localización deberían ser algo que puedas desplegar en cualquier lugar, para cada visitante, sin fricciones legales.