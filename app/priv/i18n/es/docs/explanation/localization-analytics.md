%{
  title: "¿Por qué el análisis de localización?",
  summary:
    "Cómo las señales recopiladas se traducen en decisiones de localización, y por qué la métrica de brecha es importante.",
  category: "explicación",
  order: 2
}
---
Elegir en qué idioma traducir a continuación es una apuesta: cuesta tiempo y dinero, y el retorno depende de la demanda que normalmente no puedes ver. El análisis de localización hace visible esa demanda.

## La decisión, no el panel

El propósito de recopilar analíticas aquí es estrecho y deliberado: responder "¿debemos localizar en el idioma X?" Las señales están seleccionadas para abordar esa pregunta, no para ser una suite de analíticas de propósito general.

Tres entradas impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país indican dónde está el interés.
2. **La brecha.** ¿Ya está esa demanda atendida? Comparar los idiomas preferidos contra los idiomas objetivo de tu proyecto revela la proporción de tráfico que choca contra una pared.
3. **Valor.** ¿Vale la pena localizar? La brecha de participación por localización, las páginas donde aterrizan los usuarios con tráfico subatendido y de dónde proviene ese tráfico indican si una nueva localización convierte.

## Por qué se calcula la brecha en el momento de la ingestión

`served_locale` y `has_locale_gap` se almacenan por evento, calculadas contra tus idiomas objetivo según estuvieran en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no un recálculo contra los objetivos de hoy. Si agregas portugués el próximo mes, la brecha del mes pasado no se reduce retrospectivamente; mantienes un registro honesto de qué tanta demanda no estaba siendo atendida.

## ¿Por qué sin cookies, específicamente

El instinto al querer «visitantes únicos» es establecer una cookie o realizar una huella digital del navegador. Ambos crean identificadores de larga duración, y la huella digital es, bajo la mayoría de los regímenes de privacidad, más difícil de limpiar que una cookie. Ninguno es necesario aquí.

Los visitantes únicos de un día solo requieren un identificador estable *dentro del día*. Un hash de la dirección IP y el User-Agent, rotado diariamente y acotado por proyecto, proporciona registros únicos diarios y semanales precisos, haciendo imposible vincular a un visitante entre días o entre sitios. Renuncias al seguimiento a largo plazo de visitantes recurrentes, que es exactamente la capacidad que genera la exposición de privacidad que necesitarías un banner de consentimiento para operar legalmente.

El compromiso es intencional: las analíticas de localización deberían ser algo que puedas desplegar a todos los visitantes sin fricción legal.