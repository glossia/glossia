%{
  title: "Por qué el análisis de localización",
  summary:
    "Cómo las señales recopiladas se traducen en decisiones de localización y por qué importa la métrica de brecha.",
  category: "explicación",
  order: 2
}
---
Elige qué idioma traducir a continuación: es una apuesta que cuesta tiempo y dinero, cuyo retorno depende de la demanda que normalmente no es visible.

## La decisión, no el tablero

El propósito de recopilar análisis aquí es estrecho y deliberado: responder «¿debemos traducir al idioma X?» Las señales se seleccionan para informar esa pregunta, no para ser una suite de análisis general.

Tres entradas impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país le indican dónde está el interés.
2. **La brecha.** ¿Esa demanda ya está atendida? Comparar los idiomas preferidos contra los idiomas objetivo de su proyecto revela la proporción del tráfico que choca contra un muro.
3. **Valor.** ¿Vale la pena la localización? La brecha de compromiso por idioma, las páginas a las que llega el tráfico no atendido y el origen de ese tráfico indican si un nuevo idioma convierte.

## Por qué la brecha se calcula en el momento de la ingestión

`served_locale` y `has_locale_gap` se almacenan por evento, calculadas contra tus idiomas objetivo según lo que eran en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no un recálculo contra los objetivos actuales. Si agregas el portugués el próximo mes, la brecha del mes pasado no se reduce retroactivamente; mantienes un registro honesto de cuánta demanda quedaba sin atender.

## Por qué sin cookies, específicamente

El instinto cuando deseas "visitas únicas" es configurar una cookie o realizar una huella digital del navegador. Ambos crean identificadores de larga duración, y la huella digital es, bajo la mayoría de regímenes de privacidad, más difícil de borrar que una cookie. Ninguno es necesario aquí.

Las visitas únicas de un día solo requieren un identificador que sea estable *dentro del día*. Una hash de la IP y el User-Agent, rotada diariamente y limitada por proyecto, proporciona visitantes únicos diarios y semanales precisos, haciendo imposible vincular a un visitante entre días o entre sitios. Renuncias al seguimiento a largo plazo de visitantes recurrentes, que es exactamente la capacidad que genera la exposición de privacidad por la que necesitarías un banner de consentimiento para operar legalmente.

La contrapartida es intencional: las analíticas de localización deben ser algo que puedas desplegar en todas partes, a cada visitante, sin fricción legal.