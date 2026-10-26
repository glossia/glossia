# Glossia: un OS de lenguaje para equipos

Glossia integra la voz, la terminología, la traducción, el historial de revisiones y el análisis de localización en un solo sistema. Ayuda a los desarrolladores, lingüistas y equipos de producto a comunicarse de manera consistente a través de idiomas sin mover su contenido fuera de Git.

## El problema

Lanzar un producto en otro idioma no es solo reemplazar palabras. Los equipos necesitan preservar el significado, utilizar la terminología correcta, adaptar el tono al público y mantener las traducciones actualizadas conforme el producto cambia. El contexto disperso en hojas de cálculo, instrucciones y herramientas de traducción conduce a una redacción incoherente y trabajo manual repetido.

Un LLM puede redactar una traducción, pero un borrador por sí solo no proporciona historial de versiones, validación, actualizaciones selectivas ni un bucle de retroalimentación para el próximo cambio.

## El papel de Glossia

- **Memoria del lenguaje:** la orientación de voz compartida y las entradas del glosario ayudan a las personas y los agentes a usar un lenguaje consistente.
- **Localización del repositorio:** conectar un repositorio, describir archivos de origen y locales objetivo en la configuración y revisar cambios a través de solicitudes de extracción.
- **Refinamiento progresivo:** los hashes de contenido ayudan a evitar traducir contenido inalterado. La validación y la recuperación hacen visibles y accionables los fallos.
- **Gestión de revisiones de contenido:** conserve el historial de decisiones de lenguaje y cambios en lugar de tratar cada generación como una instrucción aislada.
- **Análisis de localización:** el análisis web consciente de la privacidad ayuda a los equipos a comprender a su audiencia y dónde vale la pena invertir en localización.
- **Integración de agentes:** un servidor MCP autenticado con OAuth e interfaces REST ponen el contexto del lenguaje disponible en los flujos de trabajo existentes.

Glossia no sustituye el juicio editorial. Proporciona el contexto, la automatización y el flujo de trabajo de revisión que permiten a los equipos aplicar ese criterio repetidamente.

## Explorar

- [Empezar](/docs/tutorials/getting-started.md): conecte un repositorio y ejecute su primer flujo de trabajo de localización.
- [¿Por qué Glossia?](/docs/explanation/why-glossia.md): los problemas para los que está diseñado el OS de lenguaje.
- [Características](/features.md): capacidades del producto y casos de uso.
- [Documentación](/docs.md): tutoriales, guías cómo hacer, referencia y explicaciones.
- [Blog](/blog.md): escritos sobre localización y sistemas de lenguaje.
- [Registro de cambios](/changelog.md): cambios del producto.
- [Código fuente](https://github.com/glossia/glossia): examine la implementación y contribuya.

## Comparaciones

- [Glossia vs Crowdin](/docs/explanation/glossia-vs-crowdin.md)
- [Glossia vs Lokalise](/docs/explanation/glossia-vs-lokalise.md)
- [Glossia vs Phrase](/docs/explanation/glossia-vs-phrase.md)
- [Glossia vs Weblate](/docs/explanation/glossia-vs-weblate.md)

## Para rastreadores y agentes

Las páginas publicadas están disponibles como Markdown añadiendo `.md` a su URL, o solicitando `Accept: text/markdown` en la URL HTML. La URL Markdown de la página principal es `/index.md`. El contenido traducido utiliza los mismos prefijos de localización que HTML y recurre al inglés cuando no se publica ninguna traducción.

Utilice [/llms.txt](/llms.txt) para el descubrimiento, [/llms-full.txt](/llms-full.txt) para la exportación de documentación consolidada y [/sitemap.xml](/sitemap.xml) para las URLs HTML canónicas. Los paneles de control de cuentas son superficies de aplicación, no documentación; no los rastree para aprender sobre Glossia.
