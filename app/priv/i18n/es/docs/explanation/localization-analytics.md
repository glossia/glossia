%{
  title: "¿Por qué la analítica de localización?",
  summary:
    "Cómo las señales recopiladas se traducen en decisiones de localización y por qué la métrica de brecha importa.",
  category: "explicación",
  order: 2
}
---
Elegir el siguiente idioma al que traducir es una apuesta: conlleva tiempo y dinero, y el retorno depende de la demanda que generalmente no puedes ver. El análisis de localización hace visible esa demanda.

## La decisión, no el panel

El propósito de recopilar análisis aquí es estrecho y deliberado: responder "¿deberíamos localizar al idioma X?". Las señales se eligen para alimentar esa pregunta, no para ser una suite de análisis de propósito general.

Tres inputs impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país indican dónde se concentra el interés.
2. **La brecha.** ¿Ya está atendida esa demanda? Comparar los idiomas preferidos contra los idiomas objetivo de tu proyecto revela la proporción de tráfico que choca con un muro.
3. **Valor.** ¿Vale la pena localizar? La brecha de engagement por idioma, las páginas donde aterrizan los usuarios no atendidos y el origen de ese tráfico indican si un nuevo idioma convierte.

## ¿Por qué se calcula la brecha en el momento de la ingesta?

`served_locale` y `has_locale_gap` y se almacenan por evento, calculados contra tus idiomas objetivo según lo eran en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no una recomputación contra los objetivos de hoy. Si añades portugués el próximo mes, la brecha del mes pasado no se reduce retrospectivamente; conservas un registro honesto de cuánta demanda iba sin atender.

## ¿Por qué sin cookies, específicamente?

El instinto cuando buscas "usuarios únicos" es generar una cookie o crear una huella digital del navegador. Ambos crean identificadores de larga duración, y la huella digital es, en la mayoría de regímenes de privacidad, más difícil de eliminar que una cookie. Ninguno es necesario aquí.

Los usuarios únicos de un día solo requieren un identificador que sea estable. *dentro del día*. Un hash de la IP y el User-Agent, rotado diariamente y limitado por proyecto, proporciona visitantes únicos diarios y semanales precisos al tiempo que hace imposible vincular a un visitante entre días o entre sitios. Renuncias al seguimiento a largo plazo de visitantes recurrentes, que es exactamente la capacidad que genera la exposición de privacidad para la que de otro modo necesitarías un banner de consentimiento para operar legalmente.

El compromiso es intencional: las analíticas de localización deberían ser algo que puedas desplegar en todas partes, a cada visitante, sin fricción legal.