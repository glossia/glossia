%{
  title: "Por qué análisis de localización",
  summary:
    "Cómo las señales recopiladas se convierten en decisiones de localización y por qué importa la métrica de la brecha.",
  category: "explicación",
  order: 2
}
---
Elegir en qué idioma traducir a continuación es una apuesta: conlleva tiempo y dinero, y el rendimiento depende de la demanda que normalmente no puedes ver. La analítica de localización hace visible esa demanda.

## La decisión, no el panel

El propósito de recopilar analíticas aquí es estrecho y deliberado: responder "¿deberíamos localizar al idioma X?" Las señales se eligen para responder a esa pregunta, no para ser un conjunto de analítica de propósito general.

Tres factores impulsan la decisión:

1. **Demanda.**»¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país te indican dónde está el interés.
2. **La brecha.**»¿Esa demanda ya está satisfecha? Comparar los idiomas preferidos contra los idiomas objetivo del proyecto revela la proporción de tráfico que encuentra una barrera.
3. **Valor.**»¿La localización compensa? El rendimiento por brecha de ubicación, las páginas donde el tráfico subatendido aterriza y de dónde proviene ese tráfico indican si una nueva ubicación convierte.

## Por qué la brecha se calcula en la ingesta

`served_locale` and `has_locale_gap` se almacenan por evento, calculadas contra tus idiomas objetivo según fueron en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no un recálculo contra los objetivos de hoy. Si añades portugués el próximo mes, la brecha del mes pasado no se reduce retroactivamente; mantienes un registro honesto de cuánto demanda quedaba sin atender.

## Por qué sin cookies, específicamente

El instinto cuando quieres "visitantes únicos" es establecer una cookie o obtener huella digital del navegador. Ambos generan identificadores de larga duración, y la huella digital bajo la mayoría de regímenes de privacidad es más difícil de limpiar que una cookie. Ninguna es necesaria aquí.

Los visitantes únicos para un día solo requieren un identificador que sea estable *dentro del día*. Un hash de la IP y el User-Agent, rotado diariamente y limitado por proyecto, proporciona únicos diarios y semanales precisos haciendo imposible vincular a un visitante entre días o entre sitios. Te arriesgas al seguimiento a largo plazo de visitantes recurrentes, que es exactamente la capacidad que crea la exposición de privacidad que necesitarías un aviso de consentimiento para operar legalmente.

El intercambio es intencional: la analítica de localización debería ser algo que puedas enviar a todos, a cada visitante, sin fricción legal.