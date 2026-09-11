%{
  title: "¿Por qué la analítica de localización?",
  summary:
    "Cómo las señales recopiladas se traducen en decisiones de localización y por qué importa la métrica de brecha.",
  category: "explicación",
  order: 2
}
---
Elegir en qué idioma traducir a continuación es una apuesta: consume tiempo y dinero, y la recompensa depende de una demanda que usualmente no es visible. Las analíticas de localización hacen visible esa demanda.

## La decisión, no el panel

El propósito de recopilar analíticas aquí es estrecho y deliberado: responder "¿debemos localizar en el idioma X?" Las señales se eligen para alimentar esa pregunta, no para ser una suite de analíticas de propósito general.

Tres factores impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país indican dónde está el interés.
2. **La brecha.** ¿Ya está esa demanda atendida? Comparar los idiomas preferidos con los idiomas objetivo del proyecto revela la proporción de tráfico que choca contra un muro.
3. **Valor.** ¿Vale la pena la localización? La brecha de compromiso por idioma, las páginas donde cae el tráfico no atendido y el origen de ese tráfico indican si un nuevo idioma convierte.

## Por qué se calcula la brecha en tiempo de ingestión

`served_locale` y `has_locale_gap` se almacenan por evento, calculados contra los idiomas objetivo tal como eran en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad a la que te enfrentaste entonces, no un recálculo contra los objetivos de hoy. Si añades portugués el próximo mes, la brecha del mes pasado no se reduce retroactivamente; conservas un registro honesto de cuánto de la demanda iba sin atender.

## Por qué sin cookies, específicamente

El instinto cuando deseas "visitantes únicos" es configurar una cookie o generar la huella digital del navegador. Ambos crean identificadores de larga duración y la generación de huellas digitales es, bajo la mayoría de regímenes de privacidad, más difícil de eliminar que una cookie. Ninguno es necesario aquí.

Los visitantes únicos por día solo requieren un identificador que sea estable *dentro del día*. Un hash de la IP y User-Agent, rotado diariamente y delimitado por proyecto, proporciona visitantes únicos diarios y semanales precisos, haciendo imposible vincular a un visitante a través de días o entre sitios. Renuncias al seguimiento a largo plazo de visitantes recurrentes, que es exactamente la capacidad que genera la exposición de privacidad por la que de otro modo necesitarías un banner de consentimiento para operar legalmente.

El compromiso es intencional: las analíticas de localización deberían ser algo que puedas distribuir en todas partes, a cada visitante, sin fricción legal.