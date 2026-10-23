# Glossia: un sistema operativo de idiomas para equipos

Glossia integra la voz, la terminología, la traducción, el historial de revisiones y las analíticas de localización en un solo sistema. Ayuda a los desarrolladores, lingüistas y equipos de producto a comunicarse consistentemente en múltiples idiomas sin mover su contenido fuera de Git.

## El problema

Lanzar en otro idioma no se trata solo de sustituir palabras. Los equipos necesitan preservar el significado, utilizar la terminología adecuada, adaptar el tono a la audiencia y mantener las traducciones actualizadas a medida que el producto cambia. El contexto disperso en hojas de cálculo, prompts y herramientas de traducción conduce a una redacción inconsistente y a un trabajo manual repetitivo.

Un LLM puede redactar una traducción, pero una redacción por sí sola no proporciona historial de versiones, validación, actualizaciones selectivas ni un ciclo de retroalimentación para el próximo cambio.

## El papel de Glossia

- **Memoria de lenguaje:** las guías de voz compartidas y las entradas del glosario ayudan a las personas y los agentes a utilizar un lenguaje consistente.
- **Localización de repositorio:** conecta un repositorio, describe los archivos de origen y marcadores de idioma objetivo en la configuración y revisa los cambios mediante pull requests.
- **Refinamiento progresivo:** los hashes del contenido ayudan a evitar traducir contenido sin cambios. La validación y la recuperación hacen que los fallos sean visibles y accionables.
- **Revisión de contenido:** preservar el historial de decisiones y cambios del lenguaje en lugar de tratar cada generación como un prompt aislado.
- **Analíticas de localización:** las analíticas web conscientes de la privacidad ayudan a los equipos a entender a su audiencia y en qué invertir en localización.
- **Integración de agentes:** un servidor MCP autenticado mediante OAuth e interfaces REST hacen que el contexto del lenguaje esté disponible para los flujos de trabajo existentes.

Glossia no reemplaza el juicio editorial. Proporciona el contexto, la automatización y el flujo de trabajo de revisión que permiten a los equipos aplicar dicho juicio de manera repetida.

## Explorar

- [Comenzar](/docs/tutorials/getting-started.md): conecta un repositorio y ejecuta tu primer flujo de trabajo de localización.
- [Por qué Glossia](/docs/explanation/why-glossia.md): los problemas que el sistema operativo de idiomas está diseñado para resolver.
- [Características](/features.md): capacidades del producto y casos de uso.
- [Documentación](/docs.md): tutoriales, guías paso a paso, referencia y explicaciones.
- [Blog](/blog.md): escritura sobre localización y sistemas de idiomas.
- [Registro de cambios](/changelog.md): cambios del producto.
- [Código fuente](https://github.com/glossia/glossia): examina la implementación y contribuye.

## Comparaciones

- [Glossia vs Crowdin](/docs/explanation/glossia-vs-crowdin.md)
- [Glossia vs Lokalise](/docs/explanation/glossia-vs-lokalise.md)
- [Glossia vs Phrase](/docs/explanation/glossia-vs-phrase.md)
- [Glossia vs Weblate](/docs/explanation/glossia-vs-weblate.md)

## Para rastreadores y agentes

Las páginas publicadas están disponibles como Markdown mediante la extensión `.md` de su URL, o solicitando `Accept: text/markdown` en la URL HTML. La URL Markdown de la página principal es `/index.md`. El contenido traducido utiliza los mismos prefijos de locales que HTML y vuelve al inglés cuando no hay ninguna traducción publicada.

Utiliza [/llms.txt](/llms.txt) para la exploración, [/llms-full.txt](/llms-full.txt) para una exportación consolidada de documentación y [/sitemap.xml](/sitemap.xml) para las URLs HTML canónicas. Los paneles de cuenta son interfaces de aplicación, no documentación; no los rastreéis para conocer a Glossia.
