%{
  title: "¿Por qué el análisis de localización",
  summary:
    "Cómo las señales recopiladas se traducen en decisiones de localización y por qué importa la métrica de brecha.",
  category: "explicación",
  order: 2
}
---
Elegir en qué idioma traducir a continuación es una apuesta: cuesta tiempo y dinero, y el beneficio depende de una demanda que usualmente no se puede ver. Los análisis de localización hacen visible esa demanda.

## La decisión, no el panel.

El propósito de recopilar análisis aquí es estrecho y deliberado: para responder "¿deberíamos traducir al idioma X?" Las señales se eligen para abordar esa pregunta, no para ser una suite de análisis de propósito general.

Tres entradas impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes quieren este idioma? Los idiomas de los navegadores y el país indican dónde está el interés.
2. **La brecha.** ¿Esa demanda ya está atendida? Comparar los idiomas preferidos contra los idiomas objetivo de tu proyecto revela la proporción de tráfico que choca contra un muro.
3. **Valor.** ¿Vale la pena localizar? La brecha de compromiso por idioma, las páginas donde aterriza el tráfico no atendido y el origen de ese tráfico indican si un nuevo idioma convierte.

## Por qué se calcula la brecha en el momento de ingestión

`served_locale` y `has_locale_gap` y se almacenan por evento, calculadas en función de tus idiomas objetivo según fueran en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no un recálculo frente a los objetivos de hoy. Si añades portugués el mes próximo, la brecha del mes pasado no se reduce retroactivamente; mantienes un registro honesto de cuánta demanda iba sin atender.

## Por qué sin cookies, específicamente

El instinto cuando quieres "visitantes únicos" es configurar una cookie o generar una huella digital del navegador. Ambas crean identificadores de larga duración, y la huella digital es, bajo la mayoría de regímenes de privacidad, más difícil de borrar que una cookie. Ninguna es necesaria aquí.

Los visitantes únicos de un día solo requieren un identificador estable *dentro del día*. Un hash de la dirección IP y User-Agent, rotado diariamente y delimitado por proyecto, proporciona únicos diarios y semanales precisos al tiempo que hace imposible vincular a un visitante entre días o entre sitios. Se renuncia al seguimiento de visitantes recurrentes a largo plazo, que es exactamente la capacidad que genera la exposición de privacidad para la que necesitarías un banner de consentimiento para operar legalmente.

La compensación es intencional: la analítica de localización debe ser algo que puedas desplegar en todas partes, para cada visitante, sin fricción legal.