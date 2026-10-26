%{
  title: "Por qué el análisis de localización",
  summary:
    "Cómo las señales recopiladas se convierten en decisiones de localización y por qué la métrica de brecha importa.",
  category: "explicación",
  section: "analytics",
  order: 2
}
---

Elegir el idioma en el que traducir a continuación es una apuesta: cuesta tiempo y dinero, y el retorno depende de la demanda que habitualmente no puedes ver. La analítica de localización hace que esa demanda sea visible.

## La decisión, no el panel

El propósito de recopilar analíticas aquí es estrecho y deliberado: responder «¿deberíamos localizar al idioma X?». Las señales se eligen para alimentar esa pregunta, no para ser un conjunto de analíticas de propósito general.

Tres insumos impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país te indican dónde está el interés.
2. **La brecha.** ¿Esa demanda ya está atendida? Comparar los idiomas preferidos contra los idiomas objetivo del proyecto, el idioma de la página y sus traducciones anunciadas revela la porción del tráfico que choca con un muro.
3. **Valor.** ¿Importaría la localización? El compromiso por brecha de idioma, las páginas en las que aterriza el tráfico subatendido y de dónde proviene ese tráfico indican si un nuevo idioma convierte.

## Por qué la brecha se calcula en tiempo de ingesta

`served_locale` registra el idioma real de la página declarado en `<html lang>`, no el idioma que asumimos que recibió el visitante. `has_locale_gap` compara las preferencias del navegador contra los objetivos del proyecto, el idioma de la página y las traducciones anunciadas a través de `hreflang` enlaces. Ambos se almacenan por evento como estaban en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no una recomputación contra los objetivos de hoy. Si añades portugués el mes que viene, la brecha del mes pasado no se reduce retroactivamente; mantienes un registro honesto de cuánto la demanda permanecía sin atender.

## ¿Por qué sin cookies, específicamente?

El instinto cuando quieres «visitantes únicos» es establecer una cookie o emprender un registro digital del navegador. Ambas crean identificadores de larga duración, y el fingerprinting es, bajo la mayoría de los marcos de privacidad, más difícil de borrar que una cookie. Ninguna es necesaria aquí.

Los usuarios únicos de un día solo requieren un identificador que sea estable *dentro del día*. Un hash de la IP y el User-Agent, rotado diariamente y limitado por proyecto, soporta los conteos diarios de visitantes mientras hace imposible vincular a un visitante a través de días o sitios. Esto no proporciona rastreo a largo plazo de visitantes recurrentes.

Este diseño limita los identificadores retenidos por analíticas. No establece si un sitio web particular requiere consentimiento; eso depende de cómo el sitio usa las analíticas y las reglas que le aplican.
