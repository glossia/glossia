%{
  title: "Glossia frente a Lokalise",
  summary:
    "Mantén la localización del producto en tu pipeline de entrega, con código fuente público, tus propios tokens de modelo y validación nativa.",
  category: "explicación",
  markdown_only: true,
  section: "translation",
  order: 21
}
---

**Elija Glossia cuando el repositorio del producto deba permanecer como la autoridad para el contenido multilingüe.** Las cadenas, la documentación, la configuración y sus verificaciones ya evolucionan con su aplicación. Glossia mantiene los cambios lingüísticos vinculados a esa evolución en lugar de pedirle a su equipo que haga de un editor alojado la autoridad de publicación.

[Lokalise](https://lokalise.com/) ofrece localización colaborativa, gestión de traducciones e integraciones para desarrolladores. La propuesta de Glossia es más específica: mantenga el flujo de trabajo del repositorio, aporte sus propias credenciales de modelo, reutilice sus verificaciones existentes e inspeccione el sistema que realiza el trabajo.

## ¿Por qué elegir Glossia?

| Su prioridad | La ventaja de Glossia |
|---|---|
| Coincidir con la velocidad de entrega de software | Los cambios de origen impulsan el trabajo de traducción; los resultados propuestos retornan a través de un flujo de trabajo de revisión del repositorio. |
| Controlar la implementación | El código fuente público hace que el procesamiento sea inspeccionable y respalda la modificación y el autoalojamiento bajo los términos de una licencia. |
| Utilice sus propios tokens de modelo | Las credenciales del proveedor con ámbito de cuenta le permiten elegir modelos compatibles sin colocar secretos en Git. |
| Validar el contenido real de la aplicación | Los scripts del repositorio pueden verificar el candidato en la ubicación donde la aplicación espera encontrarlo. |
| Mantener un límite de revisión claro | Las solicitudes de extracción mantienen visibles los cambios de idioma en las mismas herramientas utilizadas para revisar el producto. |

## Mantener los cambios de idioma vinculados a los cambios del producto

Un nuevo mensaje de interfaz de usuario o una sección de documentación no es una tarea de traducción aislada. Pertenece a una revisión del producto, usa su terminología y debe funcionar con su estructura.

Glossia lee la configuración `L10N.md` de propiedad del repositorio, usa cambios de contenido y contexto para identificar traducciones obsoletas y propone actualizaciones para revisión. Los revisores ven archivos reales y diferencias; el flujo de publicación sigue siendo suyo.

Lokalise también tiene automatización e integraciones de Git. La distinción de Glossia es el sistema de registro intencionado: su repositorio posee el contenido publicado y sus reglas de entrega, mientras que Glossia proporciona el contexto lingüístico y los mecanismos de transformación.

## Traiga sus propios tokens en lugar de fijar una única elección de modelo

Glossia le permite configurar los modelos compatibles mediante sus propias credenciales de API del proveedor. Un repositorio utiliza un identificador de modelo estable, por lo que rotar credenciales o actualizar el modelo detrás de ese identificador no requiere cambiar cada proyecto.

Una configuración anidada y orientación específica del idioma pueden seleccionar un modelo configurado diferente para un área o idioma particular. Esta es una selección explícita, no una promesa de conmutación automática del proveedor. Consulte [Modelos de cuenta](./account-models).

## Reutilice la validación que ya conoce su aplicación

Su repositorio puede ya saber cómo detectar cadenas inválidas, archivos malformados, atributos de componentes rotos o una falla en la compilación de documentación. Glossia puede invocar ese conocimiento a través de un comando de validación configurado.

El candidato se coloca temporalmente en su ruta de salida real para la comprobación. El objetivo anterior se restaura después de cada intento de validación y el candidato aceptado se escribe después. El resultado rechazado pasa por el presupuesto de recuperación configurado en lugar de ser aceptado solo porque el texto parece plausible.

Las comprobaciones estructurales y de repositorio no demuestran que cada oración sea correcta. Complementan la revisión lingüística humana y convierten esa revisión en parte de un cambio entregable. Consulte [L10N.md](/docs/reference/l10n-md) y [Recuperación de traducciones](./translation-recovery).

## Código fuente público y resultados de propiedad del repositorio

Glossia sigue un modelo de núcleo abierto. El núcleo utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite el uso comercial, la modificación, la distribución, el autoalojamiento y los servicios alojados competidores conforme a sus términos. El código de `ee/` tiene una [licencia Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) independiente: su código es visible, pero no es de código abierto, y su uso en producción requiere un acuerdo comercial por escrito.

Más importante para la entrega diaria, sus traducciones salidas permanecen en Git. No necesita una sesión de edición en otro producto simplemente para publicar los archivos existentes que posee.

Lokalise puede encajar para un equipo que quiera edición centralizada en el navegador y coordinación de localización. Glossia es la elección cuando **propiedad del repositorio, sus propios tokens de modelo y las comprobaciones existentes del producto** son el flujo de trabajo que desea mantener.

Pruebe un cambio representativo antes de cambiar de sistemas. Esta página no promete migración automática o paridad de características, ni afirma que Lokalise carece de automatización o todas las opciones del proveedor. Consulte [Documentación de Lokalise](https://docs.lokalise.com/) para sus capacidades actuales.
