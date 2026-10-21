%{
  title: "¿Por qué el análisis de localización?",
  summary:
    "Cómo las señales recopiladas se traducen en decisiones de localización y por qué importa la métrica de brecha.",
  category: "explicación",
  section: "analytics",
  order: 2
}
---

Elegir en qué idioma traducir a continuación es una apuesta: cuesta tiempo y dinero, y el retorno depende de la demanda que normalmente no puedes ver. El análisis de localización hace visible esa demanda.

## La decisión, no el tablero

El propósito de recopilar métricas aquí es estrecho y deliberado: responder "¿debemos localizar hacia el idioma X?" Las señales se eligen para alimentar esa pregunta, no para ser una suite de análisis de propósito general.

Tres factores impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país indican dónde está el interés.
2. **La brecha.** ¿Está esa demanda ya satisfecha? Comparando los idiomas preferidos con los idiomas objetivo de su proyecto, el idioma de la página y sus traducciones anunciadas revela la cuota de tráfico que choca con un muro.
3. **Valor.** ¿Compensa localizar? El compromiso según la brecha de localización, las páginas en las que aterriza el tráfico subatendido y de dónde proviene ese tráfico indican si una nueva localización convierte.

## Por qué se calcula la brecha en tiempo de ingestión

`served_locale` registra el idioma real de la página declarado en `<html lang>`, no el idioma que asumimos que recibió un visitante. `has_locale_gap` compara las preferencias del navegador con los objetivos de su proyecto, el idioma de la página y las traducciones anunciadas a través de `hreflang` enlaces. Ambos se almacenan por evento tal como estaban en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no una recomputación contra los objetivos de hoy. Si añades portugués el mes que viene, la brecha de este mes no se reduce retroactivamente; mantienes un registro honesto de cómo de la demanda iba sin atender.

## Por qué sin cookies, específicamente

El instinto cuando quieres "visitantes únicos" es establecer una cookie o huella digital del navegador. Ambos crean identificadores de larga duración, y la huella digital es, bajo la mayoría de los regímenes de privacidad, más difícil de borrar que una cookie. Ninguno es necesario aquí.

Los visitantes únicos de un día solo requieren un identificador que sea estable *dentro del día*. Un hash de la IP y el User-Agent, rotado diariamente y delimitado por projecto, permite conteos diarios de visitantes mientras hace imposible vincular un visitante a través de días o sitios. Esto no proporciona seguimiento de visitantes recurrentes a largo plazo.

Este diseño limita los identificadores retenidos por el análisis. No establece si un sitio web particular requiere consentimiento; eso depende de cómo el sitio utiliza el análisis y las reglas que se aplican a él.
