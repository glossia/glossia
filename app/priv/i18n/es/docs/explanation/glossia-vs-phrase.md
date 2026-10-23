%{
  title: "Glossia vs Phrase",
  summary:
    "Elige un flujo de trabajo de lenguaje nativo del repositorio con fuente pública, tus propios tokens de modelo y comprobaciones de entrega reutilizables.",
  category: "explicación",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Elija Glossia cuando desee que el trabajo lingüístico siga el sistema de entrega de su producto, en lugar de construir un proceso paralelo de gestión de traducción a su alrededores.** Mantenga el contenido en Git, elija modelos admitidos utilizando sus propias credenciales y valide los resultados con las comprobaciones que su repositorio ya confía.

[Phrase](https://phrase.com/) ofrece una suite de localización, incluidas Phrase Strings y Phrase TMS para diferentes necesidades de localización de software y de traducción gestionada. Glossia toma un enfoque enfocado: ofrece a los equipos de software un sistema operativo de idioma que se adapta a su bucle existente de revisión y entrega.

## ¿Por qué elegir Glossia

| Su prioridad | La ventaja de Glossia |
|---|---|
| Integrar cambios lingüísticos con el software | Los cambios del repositorio impulsan la localización, y los resultados regresan como cambios susceptibles de revisión. |
| Revise y tome el control del procesamiento | El código fuente público expone la implementación de la aplicación y del despliegue, con modificación y autoalojamiento permitidos bajo los términos de la licencia. |
| Utilice sus propios tokens | Configure sus propias credenciales de proveedor de modelos admitidos; seleccione modelos a través de los manejadores de cuenta en la configuración del repositorio. |
| Reutilice los pipelines de validación | Ejecuta comprobaciones nativas del repositorio en los candidatos de traducción en lugar de considerar la aprobación lingüística como prueba de que un archivo se construirá. |
| Mantenga una propiedad duradera | Los archivos publicados, la configuración y el historial de solicitudes de extracción permanecen con el repositorio. |

## Integre la localización como parte de la entrega continua

La detección de cambios de Glossia evita repetir el trabajo de traducción para entradas sin cambios. Su flujo de trabajo del repositorio mantiene un solicitud de extracción de traducción abierta por proyecto y publica el progreso en lotes, por lo que un repositorio de origen de rápida evolución no necesita un nuevo proceso de traducción para cada pequeño cambio.

El objetivo no es una carrera sin revisión hacia la producción. Se trata de hacer que el trabajo lingüístico sea continuamente revisable y entregable a través del pipeline que ya utiliza su equipo.

Phrase también ofrece API, integraciones y automatización. La ventaja que resalta Glossia es la alineación arquitectónica: el repositorio permanece como la autoridad de contenido y el límite de entrega, en lugar de ser solo un lugar para sincronizar los resultados de otro espacio de trabajo.

## Mantenga la elección del modelo y las credenciales bajo su control

Glossia acepta sus propios tokens de API del proveedor para los modelos admitidos. Las credenciales se mantienen en la configuración de la cuenta; los repositorios seleccionan manejadores estables. Un equipo puede rotar un token o cambiar el modelo detrás de un manejador sin reescribir sus instrucciones del repositorio.

Diferentes alcances de contenido y idiomas objetivo pueden usar diferentes modelos configurados. Los modelos de decisión opcionales pueden evaluar traducciones completas y solicitar correcciones, mientras que los humanos permanecen responsables del juicio lingüístico. Vea [Modelos de cuenta](./account-models) para el comportamiento actual y los límites.

## Su repositorio ya sabe qué significa el contenido válido

La vista de un sistema de gestión de traducción de una cadena no es necesariamente la vista de la aplicación de un archivo. Un repositorio puede tener su propio analizador, compilador, reglas de componente, construcción de documentación y comprobaciones de marcadores.

Glossia puede reutilizar esas comprobaciones a través de `L10N.md` comandos de validación. Escribe el candidato temporalmente en su ruta de destino real para la validación y solo lo acepta después de que las comprobaciones requeridas pasen. El comando y sus dependencias deben estar disponibles en el entorno de ejecución.

Esto permite al equipo extender su límite de calidad existente en lugar de mantener una definición separada de "válido" exclusivamente dentro de un espacio de trabajo de traducción. Vea [L10N.md](/docs/reference/l10n-md).

## Implementación pública, no una caja negra

Las aplicaciones, CLI, SDK y fuentes de implementación de Glossia son públicas. Puede inspeccionar cómo se maneja el contenido y modificar o autoalojar la implementación bajo la [O'Saasy license](https://github.com/glossia/glossia/blob/main/LICENSE.md). La licencia restringe los servicios alojados competidores y no es una licencia de código abierto sin restricciones.

Una suite de traducción más amplia puede tener sentido para operaciones especializadas de traducción y coordinación compleja. Si su prioridad es **adaptar la velocidad de entrega de software con sus propios tokens y las comprobaciones del repositorio**, Glossia está diseñado para mantener ese flujo de trabajo directo.

Mover un programa establecido de traducción aún requiere un plan para sus memorias, terminología e historial. Esta página no promete un importador de Phrase automático ni paridad completa de la suite, ni afirma que Phrase falte todas las integraciones equivalentes. Consulte [documentación de Phrase](https://support.phrase.com/) para las capacidades actuales del producto específico.
