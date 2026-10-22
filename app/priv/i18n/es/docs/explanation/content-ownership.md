%{
  title: "Propiedad y portabilidad del contenido",
  summary:
    "Por qué es importante el contenido propiedad del repositorio, y qué dependencias la fuente pública elimina y no elimina.",
  category: "Explicación",
  section: "translation",
  order: 3
}
---

Una empresa debería poder cambiar sus herramientas de idioma sin perder el contenido que ya ha producido ni la capacidad de distribuir ese contenido.

## La propiedad es más que un botón de exportación

Exportar archivos traducidos es útil, pero la portabilidad también incluye el historial de revisiones, las directrices de idioma, la terminología y la configuración necesaria para continuar la labor. Si estos solo residen dentro de un entorno de trabajo propietario, la empresa puede retener su resultado, mientras pierde el proceso que lo originó.

El flujo de trabajo de repositorio de Glossia conserva los archivos de origen publicados y los traducidos en Git. El historial de solicitudes de extracción permanece en el repositorio, y la configuración basada en archivos describe la transformación de manera independiente a una sesión de edición en el navegador.

## Las decisiones sobre el idioma deben ser reutilizables

La voz y las directrices del glosario captan la intención organizacional. Glossia pone ese contexto disponible para personas e integraciones, incluidos agentes a través de MCP. Este es un tipo de reutilización diferente de buscar un segmento ya traducido previamente: puede orientar nuevo contenido incluso cuando no existe una frase coincidente en una memoria.

Eso no hace que las memorias de traducción basadas en segmentos sean obsoletas. Los equipos pueden tener traducciones revisadas valiosas y flujos de trabajo especializados que deseen conservar. La postura de Glossia es que tales recursos deberían complementar el proceso de entrega de una empresa en lugar de convertirse en una autoridad propietaria obligatoria sobre él.

## El código fuente público ayuda, pero no es un plan de salida mágico

Poder inspeccionar y modificar la implementación ayuda a los equipos a comprender cómo se procesa su contenido. No significa que desaparezca cada dependencia operativa. Una instancia de Glossia desplegada aún necesita bases de datos, acceso de proveedor de modelos para los flujos de trabajo relevantes, credenciales e infraestructura. El contexto de idioma gestionado en el panel también necesita un plan de migración explícito si un equipo cambia sistemas.

La licencia O'Saasy actual restringe los servicios alojados competidores. La disponibilidad del código fuente público no es lo mismo que una licencia de código abierto sin restricciones ni un aseguramiento de que un servicio de reemplazo pueda operar bajo cualquier modelo de negocio. Consultar la [licencia](https://github.com/glossia/glossia/blob/main/LICENSE.md) del repositorio.

## Una prueba útil de portabilidad

Pregunte si el equipo puede seguir inspeccionando, revisando y publicando su contenido traducido existente si el servicio de idioma no está disponible. Con las salidas propiedad del repositorio, la publicación no requiere volver a abrir un editor propietario solo para recuperar el último archivo.

Luego pregunte cómo se moverían las directrices de idioma, las credenciales y la automatización a otro sistema. Son cuestiones separadas, y mantenerlas explícitas es más útil que prometer "sin ataduras" sin calificación.
