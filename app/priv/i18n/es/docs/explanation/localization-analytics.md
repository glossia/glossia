%{
  title: "¿Por qué los análisis de localización?",
  summary:
    "Cómo las señales recopiladas se convierten en decisiones de localización y por qué importa la métrica de brecha.",
  category: "explicación",
  order: 2
}
---
Elegir en qué idioma traducir a continuación es una apuesta: cuesta tiempo y dinero, y el retorno depende de una demanda que generalmente no puedes ver. La analítica de localización hace visible esa demanda.

## La decisión, no el panel

El propósito de recopilar analítica aquí es preciso y deliberado: para responder "¿deberíamos localizar en el idioma X?" Las señales se eligen para alimentar esa pregunta, no para ser un conjunto de analítica de propósito general.

Tres entradas impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país te indican dónde está el interés.
2. **La brecha.** ¿Esa demanda ya está atendida? Comparar los idiomas preferidos contra los idiomas objetivo de tu proyecto revela el porcentaje de tráfico que choca contra una pared.
3. **Valor.** ¿Vale la pena localizar? La brecha de participación por localización, las páginas en las que aterrizan los accesos no atendidos y el origen de ese tráfico indican si una nueva localización convierte.

## Por qué se calcula la brecha en el momento de la ingestión

`served_locale` y `has_locale_gap` se almacenan por evento, calculados contra tus idiomas objetivo como estaban en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no una recomputación contra los objetivos de hoy. Si añades portugués el próximo mes, la brecha del mes pasado no se reduce retroactivamente; mantienes un registro honesto de cuánta demanda no estaba siendo atendida.

## Por qué sin cookies, específicamente

El instinto cuando deseas "visitantes únicos" es configurar una cookie o crear una huella digital del navegador. Ambos crean identificadores de larga duración y la huella digital es, bajo la mayoría de los regímenes de privacidad, más difícil de borrar que una cookie. Ninguna es necesaria aquí.

Los visitantes únicos por día solo requieren un identificador que sea estable *dentro del día*. Un hash de la IP y User-Agent, rotado diariamente y acotado por proyecto, proporciona registros únicos diarios y semanales precisos al tiempo que hace imposible vincular a un visitante entre días o entre sitios. Se renuncia al seguimiento a largo plazo de visitantes recurrentes, lo cual es exactamente la capacidad que genera la exposición de privacidad que, de otro modo, necesitaría un banner de consentimiento para operar legalmente.

La compensación es intencional: el análisis de localización debería ser algo que puedas implementar en todas partes, para cada visitante, sin fricción legal.