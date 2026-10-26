%{
  title: "Propiedad y portabilidad del contenido",
  summary:
    "Por qué importa el contenido de propiedad del repositorio, y qué dependencias de fuente pública se eliminan y cuáles no.",
  category: "explicación",
  section: "translation",
  order: 3
}
---

Una empresa debería poder cambiar sus herramientas de idioma sin perder el contenido que ya ha producido ni la capacidad de publicar ese contenido.

## La propiedad es más que un botón de exportación

Exportar archivos traducidos es útil, pero la portabilidad también incluye el historial de revisión, la orientación lingüística, la terminología y la configuración necesarias para continuar el trabajo. Si estas viven solo dentro de un espacio de trabajo propietario, la empresa puede retener su resultado aunque pierda el proceso que lo generó.

El flujo de trabajo del repositorio de Glossia mantiene el código fuente publicado y los archivos traducidos en Git. El historial de pull request permanece en el repositorio, y la configuración basada en archivos describe la transformación independentemente de una sesión de edición en el navegador.

## Las decisiones de idioma deben ser reutilizables

La voz y la orientación del glosario captan la intención organizacional. Glossia hace que ese contexto esté disponible para humanos e integraciones, incluidos los agentes a través de MCP. Este es un tipo diferente de reutilización a diferencia de buscar un segmento previamente traducido: puede guiar nuevo contenido incluso cuando no hay una frase coincidente en la memoria.

Eso no hace que las memorias de traducción basadas en segmentos queden obsoletas. Los equipos pueden contar con traducciones revisadas valiosas y flujos de trabajo especializados que desean mantener. La posición de Glossia es que estos recursos deberían complementar el proceso de entrega de una empresa en lugar de convertirse en una autoridad propietaria obligatoria sobre él.

## El código fuente público ayuda, pero no es un plan de salida mágico

Poder inspeccionar y modificar la implementación ayuda a los equipos a comprender cómo se procesa su contenido. No significa que desaparezcan cada dependencia operativa. Una instancia de Glossia desplegada aún necesita bases de datos, acceso al proveedor de modelos para flujos de trabajo relevantes, credenciales e infraestructura. El contexto lingüístico gestionado por el panel también requiere un plan de migración explícito si un equipo cambia de sistemas.

Glossia sigue un modelo de núcleo abierto. El núcleo utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite el uso comercial, la modificación, la distribución, el autoalojamiento y los servicios alojados competidores conforme a sus términos. El código de `ee/` tiene una [licencia Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) independiente: su código es visible, pero no es de código abierto, y su uso en producción requiere un acuerdo comercial por escrito.

## Una prueba útil de portabilidad

Pregunte si el equipo puede seguir inspeccionando, revisando y publicando su contenido traducido existente si el servicio de idioma no está disponible. Con las salidas propiedad del repositorio, la publicación no requiere volver a abrir un editor propietario solo para recuperar el último archivo.

Luego pregunte cómo se trasladaría la orientación del idioma, las credenciales y la automatización a otro sistema. Son preguntas separadas; mantenerlas explícitas es más útil que prometer "no bloqueo" sin reservas.
