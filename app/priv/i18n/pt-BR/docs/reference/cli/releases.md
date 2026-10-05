%{
  title: "Lançamentos",
  summary: "Histórico de lançamentos da CLI.",
  category: "Referência",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correções de Bugs

- Renomear o binário dentro dos arquivos de release do nome específico da plataforma para apenas `glossia`.
- Remover o xattr de quarentena do macOS dos binários antes do empacotamento.

## 0.14.0

*2026-02-14*

#### Funcionalidades

- Adição de script de liberação local e fluxo de trabalho de registro de alterações mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de Bugs

- Correção na gestão da configuração do provedor de login hospedado.
- Correção nas verificações de saúde do serviço hospedado.

#### Funcionalidades

- Adicionado um app Phoenix com login OAuth, melhorias de documentação e da interface do usuário.
- Logo arredondada usada como favicon.
- CLI migrado para o Bun e builds executáveis de CI atualizados.

## 0.1.0

*2026-02-12*

#### Correções de bugs

- Previne o desbordamento horizontal de trechos de código no mobile.
- Adicionada margem direita adequada aos trechos de código no mobile.
- Melhore o layout responsivo para mobile para evitar desbordamento horizontal.
- Aplique formatação biome.
- Adicione títulos de grupo ao template de notas de lançamento.
- Atualize o fluxo de tradução do Bun para o Rust.
- Alinhe o corpo do post com o layout hero e melhore o conteúdo do post do blog.
- Centralize o conteúdo do post do blog horizontalmente.
- Corrija o pânico ao truncar resultados da ferramenta de UTF-8 multibyte.

#### Funcionalidades

- Adicionar seção de ferramentas próprias e do site.
- Apresentar etapas de verificação da ferramenta.
- Simplificar a saída de progresso.
- Aplicar cor às linhas de progresso.
- Mostrar atividade de tradução e validação.
- Formatar linhas da ferramenta.
- Tornar o site responsivo com menu móvel e layout de múltiplos breakpoints.
- Reimplementar o CLI em Bun/TypeScript.
- Adicionar fluxo de trabalho CI e testes.
- Adicionar verificação de formatação com Biome.
- Adicionar a seção Progressive Refinement à página inicial.
- Adicionar seção de blog com suporte a SEO e o primeiro post de blog.
- Unificar a saída do CLI com formato de verbos alinhado à direita.
- Colorizar a saída do CLI com formatação de mensagem mais rica.
- Adicionar imagem OG quadrada e tags meta do card do Twitter.
- Tornar o agente coordenador autônomo com uso de ferramentas.
- Reescrita `glossia init` com o Agent Client Protocol (ACP).
- Adicionar suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações

- Dividir o CI em tarefas separadas de formatação, verificação de tipos, testes e compilação.
- Reescrever o CLI de TypeScript/Bun para Rust.