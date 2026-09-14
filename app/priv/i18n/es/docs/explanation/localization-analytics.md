%{
  title: "¿Por qué el análisis de localización?",
  summary:
    "Cómo las señales recopiladas se traducen en decisiones de localización, y por qué la métrica de brecha importa.",
  category: "explicación",
  order: 2
}
---
Elegir a qué idioma traducir a continuación es una apuesta: cuesta tiempo y dinero, y el retorno depende de una demanda que habitualmente no puedes ver. La analítica de localización hace que esa demanda sea visible.

## La decisión, no el panel

El objetivo de recopilar analíticas aquí es estrecho y deliberado: para responder "¿debemos localizar al idioma X?" Las señales se eligen para responder a esa pregunta, no para ser una suite de analíticas de propósito general.

Tres insumos impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país te indican dónde está el interés.
2. **La brecha.** ¿Ya se atiende esa demanda? Comparar los idiomas preferidos contra los idiomas objetivo de tu proyecto revela la proporción de tráfico que choca contra un muro.
3. **Valor.** ¿Valdría la pena localizar? La brecha de compromiso por localización, las páginas en las que aterriza el tráfico desatendido y el origen de ese tráfico indican si una nueva localización convierte.

## Por qué se calcula la brecha en el momento de ingestión

`served_locale` y `has_locale_gap` se almacenan por evento, calculadas contra tus idiomas objetivo tal como eran en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no una recomputación contra los objetivos de hoy. Si añades portugués el mes siguiente, la brecha del mes pasado no se reduce retroactivamente; mantienes un registro honesto de cuánto demanda iba desatendida.

## Por qué sin cookies, específicamente

El instinto cuando deseas "visitantes únicos" es configurar una cookie o realizar fingerprinting en el navegador. Ambos generan identificadores de larga duración, y el fingerprinting es, bajo la mayoría de regímenes de privacidad, más difícil de borrar que una cookie. Ninguno es necesario aquí.

Los visitantes únicos para un día solo requieren un identificador que sea estable *dentro del día*. Un hash de la IP y el User-Agent, rotado diariamente y limitado por proyecto, proporciona únicos diarios y semanales precisos mientras hace imposible vincular a un visitante a través de días o sitios. Se renuncia al seguimiento a largo plazo de visitantes recurrentes, que es exactamente la capacidad que genera la exposición de privacidad que, de otro modo, requeriría un banner de consentimiento para operar legalmente.

El compromiso es intencional: la analítica de localización debería ser algo que puedas desplegar en todas partes, a cada visitante, sin fricción legal.