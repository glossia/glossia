%{
  title: "Propiedad y portabilidad del contenido",
  summary:
    "Por qué importa el contenido propiedad del repositorio, y qué dependencias el código fuente público elimina y no elimina.",
  category: "explicación",
  section: "translation",
  order: 3
}
---

Una empresa debería poder cambiar sus herramientas de idioma sin perder el contenido que ya ha producido ni la capacidad de distribuir ese contenido.

## La propiedad es más que un botón de exportación

Exportar archivos traducidos es útil, pero la portabilidad también incluye el historial de revisión, la orientación lingüística, la terminología y la configuración necesarias para continuar el trabajo. Si estas solo residen dentro de un espacio de trabajo propietario, la empresa puede retener su producción mientras pierde el proceso que la generó.

El flujo de trabajo de repositorio de Glossia mantiene los archivos fuente publicados y los archivos traducidos en Git. El historial de solicitudes de extracción permanece en el repositorio y la configuración basada en archivos describe la transformación independientemente de una sesión de edición del navegador.

## Las decisiones lingüísticas deberían ser reutilizables

La voz y la orientación del glosario captan la intención organizativa. Glossia hace que ese contexto esté disponible para humanos e integraciones, incluidos los agentes a través de MCP. Este es un tipo diferente de reutilización de buscar un segmento previamente traducido: puede guiar contenido nuevo incluso cuando no hay una frase coincidente en la memoria.

Esto no hace que las memorias de traducción basadas en segmentos estén obsoletas. Los equipos pueden tener traducciones revisadas valiosas y flujos de trabajo especializados que desean conservar. La posición de Glossia es que dichos recursos deben complementar el proceso de entrega de una empresa en lugar de convertirse en una autoridad propietaria obligatoria sobre él.

## El código fuente público ayuda, pero no es un plan de salida mágico

Poder inspeccionar y modificar la implementación ayuda a los equipos a comprender cómo se procesa su contenido. No significa que desaparezca cada dependencia operativa. Una instancia desplegada de Glossia aún necesita bases de datos, acceso al proveedor de modelos para flujos de trabajo relevantes, credenciales e infraestructura. El contexto lingüístico gestionado desde el panel también necesita un plan de migración explícito si un equipo cambia de sistemas.

La licencia actual de O'Saasy restringe los servicios alojados competidores. La disponibilidad de fuente pública no es lo mismo que una licencia de código abierto sin restricciones ni una garantía de que un servicio de reemplazo puede operar bajo cualquier modelo de negocio. Vea la [licencia](https://github.com/glossia/glossia/blob/main/LICENSE.md) del repositorio.

## Una prueba útil de portabilidad

Pregúntese si el equipo aún puede inspeccionar, revisar y publicar su contenido traducido existente si el servicio de idioma no está disponible. Con salidas del repositorio, la publicación no requiere volver a abrir un editor propietario solo para recuperar el último archivo.

Luego pregunte cómo la orientación lingüística, las credenciales y la automatización se moverían a otro sistema. Estas son preguntas separadas y mantenerlas explícitas es más útil que prometer "no atrapamiento" sin calificación.
