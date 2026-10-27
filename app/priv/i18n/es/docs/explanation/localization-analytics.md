%{
  title: "¿Por qué la analítica de localización?",
  summary:
    "Cómo las señales recopiladas se convierten en decisiones de localización y por qué importa la métrica de brecha.",
  category: "explicación",
  section: "analytics",
  order: 2
}
---

Elegir en qué idioma traducir a continuación es una apuesta: cuesta tiempo y dinero, y el retorno depende de la demanda que usualmente no puedes ver. Los análisis de localización hacen visible esa demanda.

## La decisión, no el panel de control

El propósito de recopilar análisis aquí es limitado y deliberado: responder "¿deberíamos localizar al idioma X?". Las señales se eligen para alimentar esa pregunta, no para ser un conjunto de análisis de propósito general.

Tres factores impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes quieren este idioma? Los idiomas del navegador y el país indican dónde está el interés.
2. **La brecha.** ¿Esa demanda ya está cubierta? Comparando los idiomas preferidos contra los idiomas objetivo de tu proyecto, el idioma de la página y sus traducciones anunciadas, se revela la proporción de tráfico que choca contra un muro.
3. **Valor.** ¿Volvería la decisión a la par? El compromiso por la brecha de localización, las páginas a las que aterriza el tráfico subatendido y de dónde proviene ese tráfico indican si una nueva localización convierte.

## Por qué se calcula la brecha en el momento de la ingestión

`served_locale` registra el idioma real de la página declarado en `<html lang>`, no el idioma que asumimos que recibió un visitante. `has_locale_gap` compara una elección explícita y válida de idioma, o las preferencias del navegador cuando no se conoce una elección, contra los objetivos de tu proyecto, el idioma de la página y las traducciones anunciadas a través de enlaces `hreflang`. Una elección indica demanda, no disponibilidad: elegir un idioma sin soporte deja aún una brecha. La preferencia del navegador, la elección y el idioma de la página permanecen como señales separadas.

La decisión de la brecha se almacena por evento como estaba en el momento de la visita. Banderas históricas, incluidos aquellos recopilados antes de que las elecciones explícitas afectaran el cálculo de la brecha, no se recalculan con los objetivos de hoy o elecciones posteriores. La lista completa de preferencias del navegador y las traducciones anunciadas no se retiene, por lo que no se pueden reconstruir de manera fiable. Si agregas el portugués el mes próximo, la brecha del mes pasado no retrocede; mantienes el registro original de la demanda.

## ¿Por qué sin cookies, específicamente

El instinto cuando deseas "visitantes únicos" es establecer una cookie o dar huella digital al navegador. Ambos crean identificadores de larga vida, y dar huella digital es, bajo la mayoría de regímenes de privacidad, más difícil de eliminar que una cookie. Ninguno es necesario aquí.

Los visitantes únicos de un día solo requieren un identificador que sea estable *dentro del día*. Un hash de la IP y del User-Agent, rotado diariamente y limitado al ámbito de cada proyecto, soporta los conteos diarios de visitantes mientras hace imposible vincular a un visitante entre días o entre sitios. Esto no proporciona seguimiento a largo plazo de visitantes recurrentes.

Este diseño limita los identificadores retenidos por los análisis. No establece si un sitio web en particular requiere consentimiento; eso depende de cómo el sitio utiliza los análisis y las reglas que se aplican a él.
