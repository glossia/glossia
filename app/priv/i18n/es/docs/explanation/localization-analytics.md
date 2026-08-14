%{
  title: "Por qué son importantes las métricas de localización",
  summary: "Cómo las señales recopiladas se convierten en decisiones de localización y por qué importa la métrica de brecha.",
  category: "explanation",
  order: 2
}
---
Elegir a qué idioma traducir a continuación es una apuesta: cuesta tiempo y dinero, y el resultado depende de una demanda que normalmente no puede ver. La analítica de localización hace visible esa demanda.

## La decisión, no el panel

El objetivo de recopilar analítica aquí es específico y deliberado: responder a la pregunta «¿deberíamos localizar al idioma X?». Las señales se eligen para responder a esa pregunta, no para crear una solución de analítica de uso general.

La decisión se basa en tres factores:

1. **Demanda.** ¿Cuántos visitantes quieren este idioma? Los idiomas del navegador y el país indican de dónde procede el interés.
2. **La brecha.** ¿Ya se atiende esa demanda? Comparar los idiomas preferidos con los idiomas de destino de su proyecto revela la proporción del tráfico que no puede avanzar.
3. **Valor.** ¿Sería rentable localizar? La interacción según la brecha de configuración regional, las páginas a las que llega el tráfico desatendido y el origen de ese tráfico indican si una nueva configuración regional genera conversiones.

## Por qué la brecha se calcula en el momento de la ingesta

`served_locale` y `has_locale_gap` se almacenan por evento y se calculan con respecto a los idiomas de destino configurados en el momento de la visita. Esto significa que los datos históricos reflejan la oportunidad que existía entonces, no un nuevo cálculo basado en los destinos actuales. Si añade portugués el próximo mes, la brecha del mes pasado no se reduce retroactivamente. Así conserva un registro fiel de cuánta demanda quedó sin atender.

## Por qué se prescinde específicamente de las cookies

Cuando se quieren identificar «visitantes únicos», lo habitual es establecer una cookie o crear una huella digital del navegador. Ambos métodos generan identificadores persistentes y, en la mayoría de las normativas de privacidad, una huella digital es más difícil de eliminar que una cookie. Ninguno de ellos es necesario en este caso.

Para contabilizar visitantes únicos durante un día solo se necesita un identificador que sea estable *durante ese día*. Un hash de la dirección IP y el User-Agent, renovado a diario y limitado a cada proyecto, permite obtener cifras precisas de visitantes únicos diarios y semanales, a la vez que impide vincular a un visitante entre distintos días o sitios. Se renuncia al seguimiento a largo plazo de los visitantes recurrentes, que es precisamente la capacidad que genera el riesgo para la privacidad por el que, de otro modo, sería necesario mostrar un aviso de consentimiento para operar legalmente.

Esta decisión es deliberada: la analítica de localización debe poder implementarse en cualquier lugar y para todos los visitantes, sin obstáculos legales.