%{
  title: "Por qué análisis de localización",
  summary: "Cómo las señales recopiladas se convierten en decisiones de localización, y por qué la métrica de brecha importa.",
  category: "explicación",
  order: 2
}
---
Elegir en qué idioma traducir a continuación es una apuesta: cuesta tiempo y dinero, y el retorno depende de la demanda que usualmente no puedes ver. La analítica de localización hace visible esa demanda.

## La decisión, no el panel

El propósito de recopilar estas analíticas aquí es limitado y deliberado: para responder «¿debemos localizar en el idioma X?». Las señales se seleccionan para alimentar esa pregunta, no para constituir una suite analítica de propósito general.

Tres entradas impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? El idioma del navegador y el país te indican dónde está el interés.
2. **La brecha.** ¿Esa demanda ya está satisfecha? Comparar los idiomas preferidos contra los idiomas objetivo de tu proyecto revela la proporción del tráfico que choca con un obstáculo.
3. **Valor.** ¿Vale la pena localizar? El compromiso en función de la brecha de localización, las páginas donde aterriza el tráfico desatendido, y de dónde proviene ese tráfico indican si una nueva localización convierte.

## Por qué la brecha se calcula en el tiempo de ingestión

`served_locale` y `has_locale_gap` se almacenan por evento, calculados contra tus idiomas objetivo tal como eran en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no una recomputación contra los objetivos de hoy. Si añades portugués el próximo mes, la brecha del mes pasado no se encoge retroactivamente; mantienes un registro honesto de cuánto demanda iba sin atenderse.

## Por qué sin cookies, específicamente

El instinto al desear «visitantes únicos» es establecer una cookie o generar una huella digital en el navegador. Ambos crean identificadores de larga duración, y la identificación por huella digital es, bajo la mayoría de los regímenes de privacidad, más difícil de eliminar que una cookie. Ninguno es necesario aquí.

Los visitantes únicos de un día solo requieren un identificador que sea estable *dentro del día*. Un hash de la IP y el User-Agent, rotado diariamente y delimitado por proyecto, proporciona únicos diarios y semanales precisos mientras hace imposible vincular a un visitante entre días o entre sitios. Renuncias al seguimiento a largo plazo de visitantes recurrentes, que es exactamente la capacidad que genera la exposición de privacidad para la cual necesitarías un banner de consentimiento para operar legalmente.

El compromiso es intencional: la analítica de localización debe ser algo que puedas desplegar en todas partes, a cada visitante, sin fricción legal.