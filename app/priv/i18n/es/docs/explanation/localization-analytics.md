%{
  title: "¿Por qué el análisis de localización?",
  summary:
    "Cómo las señales recopiladas se traducen en decisiones de localización y por qué la métrica de brecha importa.",
  category: "explicación",
  order: 2
}
---
Seleccionar el siguiente idioma para traducir es una apuesta: cuesta tiempo y dinero, y el retorno depende de la demanda que habitualmente no es visible.

## La decisión, no el panel

El propósito de recopilar analíticas aquí es preciso y deliberado: responder a "¿debemos localizar en el idioma X?". Los indicadores se eligen para servir a esa pregunta, no para ser una suite de analíticas de propósito general.

Tres entradas impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? El idioma del navegador y el país indican dónde radica el interés.
2. **La brecha.** ¿Esa demanda ya está cubierta? Comparar idiomas preferidos frente a los idiomas objetivo de su proyecto revela la proporción de tráfico que encuentra una barrera.
3. **Valor.** ¿Vale la pena localizar? La brecha de compromiso por localización, las páginas donde aterrizó el tráfico subatendido y el origen de tal tráfico indican si una nueva localización convierte.

## Por qué se calcula la brecha en el momento de la ingesta

`served_locale` y `has_locale_gap` se almacenan por evento, calculadas contra tus idiomas objetivo tal como eran en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que entonces enfrentaste, no un recálculo contra los objetivos de hoy. Si agregas portugués el próximo mes, la brecha del mes pasado no se reduce retroactivamente; mantienes un registro honesto de cuánta demanda iba sin atender.

## Por qué sin cookies, específicamente

El instinto cuando deseas "visitantes únicos" es establecer una cookie o realizar una huella digital del navegador. Ambos crean identificadores de larga duración, y la huella digital es, bajo la mayoría de regímenes de privacidad, más difícil de eliminar que una cookie. Ninguno es necesario aquí.

Los visitantes únicos diarios solo requieren un identificador estable. *dentro del día*. Un hash de la IP y el User-Agent, rotado diariamente y delimitado por proyecto, proporciona visitantes únicos diarios y semanales precisos y hace imposible vincular a un visitante entre días o entre sitios. Dejas el seguimiento a largo plazo de visitantes recurrentes, que es exactamente la capacidad que genera la exposición de privacidad para la que necesitarías un banner de consentimiento para operar legalmente de otra manera.

El compromiso es intencional: la analítica de localización debe ser algo que puedas distribuir en todas partes, a cada visitante, sin fricción legal.