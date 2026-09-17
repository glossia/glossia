%{
  title: "¿Por qué los análisis de localización?",
  summary:
    "¿Cómo las señales recopiladas se traducen en decisiones de localización y por qué importa la métrica de brecha?",
  category: "explicación",
  order: 2
}
---
Elegir en qué idioma traducir a continuación es una apuesta: conlleva tiempo y dinero, y el retorno depende de una demanda que usualmente no puedes ver. La analítica de localización hace visible esa demanda.

## La decisión, no el panel

El propósito de recopilar análisis aquí es limitado y deliberado: para responder "¿deberíamos localizar en el idioma X?" Las señales se eligen para abordar esa pregunta, no para ser una suite de análisis de propósito general.

Tres entradas impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país te indican dónde está el interés.
2. **La brecha.** ¿Esa demanda ya está cubierta? Comparar los idiomas preferidos contra los idiomas objetivo del proyecto revela la porción de tráfico que encuentra obstáculos.
3. **Valor.** ¿Vale la pena localizar? La brecha de compromiso por idioma, las páginas donde aterriza el tráfico no atendido, y el origen de ese tráfico, indican si un nuevo idioma convierte.

## Por qué la brecha se calcula en el tiempo de ingestión

`served_locale` y `has_locale_gap` se almacenan por evento, calculadas contra tus idiomas objetivo según su estado en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que afrontaste entonces, no un recálculo contra las metas de hoy. Si añades portugués el próximo mes, la brecha del mes pasado no se reduce retroactivamente; mantienes un registro honesto de cuánta demanda no estaba siendo atendida.

## Por qué sin cookies, específicamente

El instinto al buscar "visitantes únicos" es crear una cookie o huellar el navegador. Ambas crean identificadores de larga duración, y la huella es, bajo la mayoría de los regímenes de privacidad, más difícil de borrar que una cookie. Ninguna es necesaria aquí.

Los visitantes únicos en un día solo requieren un identificador que sea estable *dentro del día*. Un hash de la IP y User-Agent, rotado diariamente y acotado por proyecto, proporciona conteos precisos de visitantes únicos diarios y semanales, haciendo imposible vincular a un visitante a través de días o entre sitios. Se renuncia al seguimiento a largo plazo de visitantes recurrentes, que es exactamente la capacidad que genera una exposición de privacidad que, de otro modo, necesitarías un banner de consentimiento para operar legalmente.

La compensación es intencional: las analíticas de localización deberían ser algo que puedas implementar en cualquier lugar, a cada visitante, sin fricciones legales.