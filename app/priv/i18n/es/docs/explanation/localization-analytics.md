%{
  title: "¿Por qué el análisis de localización",
  summary:
    "Cómo las señales recopiladas se traducen en decisiones de localización y por qué importa la métrica de brecha.",
  category: "explicación",
  section: "análisis",
  order: 2
}
---
Elegir en qué idioma traducir a continuación es una apuesta: cuesta tiempo y dinero, y el retorno depende de la demanda que usualmente no ves.

## La decisión, no el panel.

El propósito de recopilar análisis aquí es estrecho y deliberado: para responder "¿deberíamos localizar en el idioma X?" Las señales se seleccionan para responder a esa pregunta, no para actuar como una suite de análisis de propósito general.

Tres factores impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país te indican dónde está el interés.
2. **La brecha.** ¿Ya se cubre esa demanda? Comparar los idiomas preferidos frente a los idiomas objetivo de tu proyecto revela la proporción de tráfico que choca con una barrera.
3. **Valor.** ¿Vale la pena localizar? La brecha de compromiso por idioma, las páginas donde aterriza el tráfico no atendido y el origen de ese tráfico indican si un nuevo idioma convierte.

## Por qué se calcula la brecha en el momento de la ingestión

`served_locale` y `has_locale_gap` y se almacenan por evento, calculados según tus idiomas objetivo tal como eran en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no un recálculo contra los objetivos de hoy. Si añades portugués el próximo mes, la brecha del mes pasado no se reduce retroactivamente; mantienes un registro honesto de cuánto demanda no estaba siendo atendida.

## Por qué sin cookies, específicamente

El instinto cuando quieres "visitantes únicos" es establecer una cookie o tomar huella digital del navegador. Ambos crean identificadores de larga duración, y la huella digital es, bajo la mayoría de las normativas de privacidad, más difícil de eliminar que una cookie. Ninguno es necesario aquí.

Los visitantes únicos de un día solo requieren un identificador estable *dentro del día*. Un hash de la IP y User-Agent, rotado diariamente y limitado por proyecto, proporciona registros únicos diarios y semanales precisos al tiempo que hace imposible vincular a un visitante a través de distintos días o sitios. Renuncias al seguimiento a largo plazo de visitantes recurrentes, que es exactamente la capacidad que crea la exposición de privacidad que necesitarías de otro modo un banner de consentimiento para operar legalmente.

El equilibrio es intencional: las analíticas de localización deberían ser algo que puedas lanzar en todas partes, para cada visitante, sin fricción legal.