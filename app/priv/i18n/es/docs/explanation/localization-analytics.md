%{
  title: "¿Por qué el análisis de localización?",
  summary:
    "Cómo las señales recopiladas se convierten en decisiones de localización y por qué importa la métrica de brecha.",
  category: "explicación",
  section: "analytics",
  order: 2
}
---

Elegir en qué idioma traducir a continuación es una apuesta: cuesta tiempo y dinero, y el retorno depende de una demanda que normalmente no puedes ver. El análisis de localización hace visible esa demanda.

## La decisión, no el dashboard

El propósito de recopilar análisis aquí es estrecho y deliberado: responder "¿debemos localizar al idioma X?". Las señales se eligen para alimentar esa pregunta, no para ser un conjunto de análisis de propósito general.

Tres entradas impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país le indican dónde está el interés.
2. **La brecha.** ¿Esa demanda ya está atendida? Comparar los idiomas preferidos con los idiomas objetivo de su proyecto, el idioma de la página y sus traducciones anunciadas revela la proporción de tráfico que choca contra una pared.
3. **Valor.** ¿Sería rentable la localización? La interacción por brecha de localización, las páginas en las que aterriza el tráfico desatendido y de dónde proviene ese tráfico indican si una nueva localización convierte.

## Por qué se calcula la brecha al momento de la ingestión

`served_locale` registra el idioma real de la página declarado en `<html lang>`, no el idioma que asumimos que recibió un visitante. `has_locale_gap` compara las preferencias del navegador contra los objetivos del proyecto, el idioma de la página y las traducciones anunciadas a través de `hreflang` enlaces. Ambos se almacenan por evento tal como estaban en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no una recomputación contra los objetivos de hoy. Si agregas portugués el próximo mes, la brecha del mes anterior no se reduce retroactivamente; mantienes un registro honesto de cuánta demanda no estaba siendo atendida.

## Por qué sin cookies, específicamente

El instinto cuando deseas "visitantes únicos" es establecer una cookie o tomar una huella digital del navegador. Ambas crean identificadores de larga duración, y la toma de huella digital es, bajo la mayoría de los regímenes de privacidad, más difícil de borrar que una cookie. Ninguna de ellas es necesaria aquí.

Los visitantes únicos para un día solo requieren un identificador que sea estable *dentro del día*. Un hash de la IP y User-Agent, rotado diariamente y acotado por proyecto, soporta los conteos de visitantes diarios mientras hace imposible vincular a un visitante entre días o entre sitios. Esto no proporciona un rastreo de visitantes recurrentes a largo plazo.

Este diseño limita los identificadores retenidos por el análisis. No establece si un sitio web particular requiere consentimiento; eso depende de cómo el sitio utiliza el análisis y las reglas que se aplican a él.
