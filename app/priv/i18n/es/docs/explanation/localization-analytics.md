%{
  title: "¿Por qué el análisis de localización",
  summary:
    "Cómo las señales recopiladas se traducen en decisiones de localización, y por qué importa la métrica de brecha.",
  category: "explicación",
  order: 2
}
---
Elegir qué idioma traducir a continuación es una apuesta: consume tiempo y dinero, y el retorno depende de una demanda que normalmente no puedes ver.

## La decisión, no el panel

El propósito de recopilar analítica aquí es estrecho y deliberado: responder "¿deberíamos localizar en el idioma X?" Las señales se seleccionan para atender esa pregunta, no para ser una suite de analítica de propósito general.

Tres entradas impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país te indican dónde se encuentra el interés.
2. **La brecha.** ¿Está esa demanda ya atendida? Comparar los idiomas preferidos con los idiomas objetivo de tu proyecto revela la proporción de tráfico que choca con un muro.
3. **Valor.** ¿Vale la pena la localización? La brecha de compromiso por idioma, las páginas en las que aterrizó el tráfico no atendido y el origen de ese tráfico indican si una nueva localización convierte.

## Por qué la brecha se calcula en tiempo de ingestión

`served_locale` y `has_locale_gap` y se almacenan por evento, calculados contra tus idiomas objetivo tal como estaban en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no un recálculo contra los objetivos de hoy. Si agregas portugués el próximo mes, la brecha del mes pasado no se reduce retroactivamente; mantienes un registro honesto de cuánta demanda estaba sin atender.

## Por qué sin cookies, específicamente

El instinto cuando deseas \\"visitantes únicos\\" es establecer una cookie o realizar una huella digital en el navegador. Ambos generan identificadores de larga duración, y la huella digital es, bajo la mayoría de los regímenes de privacidad, más difícil de borrar que una cookie. Ninguno es necesario aquí.

Los visitantes únicos para un día solo requieren un identificador que sea estable. *dentro del día*. Un hash de la IP y el User-Agent, rotado diariamente y limitado por proyecto, proporciona únicos diarios y semanales precisos, haciendo imposible vincular a un visitante entre días o sitios. Se renuncia al seguimiento a largo plazo de visitantes recurrentes, lo cual es exactamente la capacidad que genera la exposición de la privacidad que, de otro modo, requeriría un banner de consentimiento para operar legalmente.

El compromiso es intencional: las analíticas de localización deben ser algo que se pueda distribuir en todas partes, a cada visitante, sin fricción legal.