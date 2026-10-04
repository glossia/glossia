%{
  title: "¿Por qué el análisis de localización?",
  summary:
    "Cómo las señales recopiladas se traducen en decisiones de localización, y por qué importa la métrica de brecha.",
  category: "explicación",
  section: "analytics",
  order: 2
}
---
Elegir en qué idioma traducir a continuación es una apuesta: conlleva tiempo y dinero, y el beneficio depende de una demanda que usualmente no puedes ver. El análisis de localización hace visible esa demanda.

## La decisión, no el panel.

El objetivo de recopilar análisis aquí es estrecho y deliberado: responder "¿Deberíamos localizar al idioma X?" Las señales se eligen para responder a esa pregunta, no para ser un conjunto de análisis de propósito general.

Tres factores impulsan la decisión:

1. **Demanda.** ¿Cuántos visitantes desean este idioma? Los idiomas del navegador y el país te indican dónde reside el interés.
2. **La brecha.** ¿Esa demanda ya está atendida? Comparando los idiomas preferidos con los idiomas objetivo de tu proyecto, el idioma de la página y sus traducciones anunciadas revela la proporción de tráfico que choca con una pared.
3. **Valor.** ¿Vale la pena la localización? La brecha de compromiso por idioma, las páginas en las que aterriza el tráfico no cubierto y el origen de ese tráfico indican si un nuevo idioma convierte.

## Por qué se calcula la brecha en el momento de ingestión

`served_locale` registra el idioma real de la página declarado en `<html lang>`, no el idioma que asumimos que recibió el visitante. `has_locale_gap` compara las preferencias del navegador con los objetivos de tu proyecto, el idioma de la página y las traducciones anunciadas a través `hreflang` enlaces. Ambos se almacenan por evento tal como estaban en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que enfrentaste entonces, no un recálculo frente a los objetivos de hoy. Si añades portugués el próximo mes, la brecha del mes pasado no se reduce retroactivamente; mantienes un registro honesto de cuánto demanda no estaba siendo cubierta.

## Por qué cookieless, específicamente

El instinto al querer "visitas únicas" es configurar una cookie o huellar el navegador. Ambos crean identificadores de larga duración, y el rastreo por huella es, bajo la mayoría de regímenes de privacidad, más difícil de eliminar que una cookie. Ninguno es necesario aquí.

Las visitas únicas de un día solo requieren un identificador que sea estable *dentro del día*. Un hash de la IP y el User-Agent, rotado diariamente y con alcance por proyecto, permite contar visitantes diarios mientras hace imposible vincular un visitante entre días o entre sitios. Esto no proporciona un seguimiento a largo plazo de visitantes recurrentes.

Este diseño limita los identificadores retenidos por el análisis. No establece si un sitio web en particular requiere consentimiento; eso depende de cómo el sitio utiliza el análisis y las normas que le aplican.