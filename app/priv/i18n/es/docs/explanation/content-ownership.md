%{
  title: "Propiedad y portabilidad del contenido",
  summary:
    "Por qué importa el contenido de propiedad del repositorio, y qué dependencias la fuente pública elimina y cuáles no.",
  category: "explicación",
  section: "translation",
  order: 3
}
---

Una empresa debe poder cambiar sus herramientas de idioma sin perder el contenido que ya ha producido ni la capacidad de lanzar ese contenido.

## La propiedad es más que un botón de exportación

Exportar archivos traducidos es útil, pero la portabilidad también incluye el historial de revisiones, las guías de idioma, la terminología y la configuración necesarias para continuar el trabajo. Si estos viven solo dentro de un espacio de trabajo propietario, la empresa podría conservar su producción mientras pierde el proceso que la generó.

El flujo de trabajo de repositorio de Glossia mantiene los archivos fuente publicados y los archivos traducidos en Git. El historial de solicitudes de extracción permanece en el repositorio, y la configuración basada en archivos describe la transformación de manera independiente de una sesión de edición en el navegador.

## Las decisiones de idioma deben ser reutilizables

La voz y las guías del glosario captan la intención organizacional. Glossia hace ese contexto disponible para humanos e integraciones, incluidos agentes a través de MCP. Es un tipo de reutilización diferente a buscar un segmento previamente traducido: puede orientar contenido nuevo incluso cuando no hay una frase coincidente en la memoria.

Eso no hace obsoletas las memorias de traducción basadas en segmentos. Los equipos pueden tener traducciones revisadas valiosas y flujos de trabajo especializados que desean conservar. La posición de Glossia es que tales recursos deberían complementar el proceso de entrega de una empresa en lugar de convertirse en una autoridad propietaria obligatoria sobre ella.

## El código fuente público ayuda, pero no es un plan de salida mágico

Poder examinar y modificar la implementación ayuda a los equipos a entender cómo se procesa su contenido. No significa que desaparezca cada dependencia operativa. Una instancia de Glossia desplegada aún necesita bases de datos, el acceso a proveedores de modelos para flujos de trabajo relevantes, credenciales e infraestructura. El contexto de idioma gestionado por el panel también necesita un plan de migración explícito si un equipo cambia de sistemas.

El núcleo de Glossia es de código abierto bajo Apache-2.0, lo que permite el autoalojamiento y servicios alojados competidores bajo sus términos. El código empresarial bajo `ee/` está disponible bajo una licencia separada y requiere un acuerdo comercial escrito para su uso en producción. Consulte el [aviso de licencias](https://github.com/glossia/glossia/blob/main/LICENSE.md) del repositorio al planificar un despliegue de reemplazo.

## Una prueba útil de portabilidad

Pregunte si el equipo aún puede examinar, revisar y publicar su contenido traducido existente si el servicio de idioma no está disponible. Con salidas propiedad del repositorio, la publicación no requiere volver a abrir un editor propietario solo para recuperar el último archivo.

Luego pregunte cómo se moverían las guías de idioma, las credenciales y la automatización a otro sistema. Son preguntas separadas y mantenerlas explícitas es más útil que prometer 'sin bloqueo' sin calificación.
