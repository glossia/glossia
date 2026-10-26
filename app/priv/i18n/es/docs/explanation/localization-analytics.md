%{
  title: "Por qué la analítica de localización",
  summary:
    "Cómo las señales recopiladas se traducen en decisiones de localización, y por qué importa la métrica de la brecha.",
  category: "explicación",
  section: "analytics",
  order: 2
}
---

Elegir el siguiente idioma al que localizar es una apuesta: consume tiempo y dinero, y el retorno depende de la demanda que usualmente no puedes ver. El análisis de localización hace que esa demanda sea visible.

## La decisión, no el panel.

El propósito de recopilar análisis aquí es estrecho y deliberado: responder "¿debemos realizar localización hacia el idioma X?". Las señales se eligen para alimentar esa pregunta, no para constituir una suite de análisis de propósito general.

Tres entradas impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes quieren este idioma? Los idiomas del navegador y el país te indican dónde se encuentra el interés.
2. **La brecha.** ¿Esa demanda ya está atendida? Comparar los idiomas preferidos contra los idiomas objetivo del proyecto, el idioma de la página y sus traducciones anunciadas revela qué proporción del tráfico encuentra una pared.
3. **Valor.** ¿La localización merece la pena? La interacción por brecha de idioma, las páginas donde aterriza el tráfico no atendido y de dónde proviene ese tráfico indican si una nueva localización convierte.

## Por qué la brecha se calcula en el momento de la ingesta

`served_locale` registra el idioma real de la página declarado en `<html lang>` de forma declarativa, no el idioma que asumimos que recibió el visitante. `has_locale_gap` compara las preferencias del navegador contra los objetivos de tu proyecto, el idioma de la página y las traducciones anunciadas a través de `hreflang` enlaces. Ambos se almacenan por evento tal como eran en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no un recálculo contra los objetivos de hoy. Si añades portugués el próximo mes, la brecha del mes pasado no se reduce retroactivamente; mantienes un registro veraz de cuánta demanda no estaba siendo atendida.

## Por qué, específicamente, sin cookies

El instinto cuando ves "visitantes únicos" es configurar una cookie o tomar la huella del navegador. Ambas crean identificadores de larga duración y, en la mayoría de los regímenes de privacidad, la huella es más difícil de borrar que una cookie. Ninguna es necesaria aquí.

Los visitantes únicos para un día solo requieren un identificador que sea estable *dentro del día*. Un hash de la IP y User-Agent, rotado a diario y delimitado por proyecto, soporta recuentos diarios de visitantes mientras hace imposible vincular un visitante entre días o entre sitios. Esto no proporciona seguimiento de retorno a largo plazo.

Este diseño limita los identificadores retidos por el análisis. No establece si un sitio web en particular requiere consentimiento; eso depende de cómo el sitio usa el análisis y de las reglas que le aplican.
