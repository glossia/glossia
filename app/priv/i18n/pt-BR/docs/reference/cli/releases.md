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

#### Correções de bugs

- Renomeie o binário dentro dos arquivos de release do nome específico da plataforma para apenas `glossia`.
- Remova o xattr de quarentena do macOS dos binários antes de empacotar.

## 0.14.0

*2026-02-14*

#### Funcionalidades

- Adicione script de liberação local e fluxo de trabalho de registro de alterações mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de Bugs

- Torne a configuração do provedor OAuth opcional na produção. O aplicativo deve iniciar mesmo sem credenciais OAuth do GitHub/GitLab configuradas. Configure provedores apenas quando as variáveis de ambiente estiverem presentes.
- Use a porta 4000 por padrão na produção e mantenha o 4050 no desenvolvimento. O proxy de produção espera o aplicativo na porta 4000. O `runtime.exs` o padrão era 4050, o que fez com que as verificações de saúde falhassem durante o deployment.

#### Funcionalidades

- Adicionar app Phoenix com login OAuth, melhorias na documentação e na interface.
- Usar logotipo arredondado como favicon.
- Migrar CLI para Bun e atualizar builds executáveis da CI.

## 0.1.0

*2026-02-12*

#### Correções de bugs

- Evitar desbordamento horizontal de snippets de código no mobile.
- Adicione margem direita adequada aos trechos de código no mobile.
- Melhore o layout responsivo para mobile para evitar desbordamento horizontal.
- Aplique a formatação do Biome.
- Adicione títulos de grupo ao modelo de notas de versão.
- Atualize o fluxo de trabalho de tradução do Bun para Rust.
- Alinhe o corpo do post com o layout de destaque e melhore o conteúdo do post do blog.
- Centralize horizontalmente o conteúdo do post do blog.
- Corrija o pânico ao truncar resultados de ferramentas em UTF-8 de múltiplos bytes.

#### Funcionalidades

- Adicionar ferramentas próprias e seção do site.
- Evidenciar etapas de verificação de ferramentas.
- Simplificar a saída de progresso.
- Colorir linhas de progresso.
- Exibir atividade de tradução e validação.
- Formatar linhas de ferramentas.
- Tornar o site responsivo com menu mobile e layout de múltiplos pontos de quebra.
- Reimplemente o CLI no Bun/TypeScript.
- Adicione workflow de CI e testes.
- Adicione verificação de formato com Biome.
- Adicione a seção Refinamento Progressivo à página inicial.
- Adicione a seção de blog com suporte a SEO e o primeiro post.
- Unifique a saída do CLI com formato de verbos alinhados à direita.
- Adicione cores à saída do CLI com formatação de mensagens mais rica.
- Adicione a imagem quadrada OG e as tags meta de cartão Twitter.
- Torna o agente coordenador autônomo com uso de ferramentas.
- Reescrita `glossia init` com o Protocolo do Cliente Agente (ACP).
- Adiciona suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações

- Separa o CI em tarefas separadas de formatação, verificação de tipos, testes e compilação.
- Reescreve o CLI do TypeScript/Bun para Rust.