%{
  title: "Lançamentos",
  summary: "Histórico de lançamentos da CLI.",
  category: "Referência",
  subcategory: "cli",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correções de Bugs

- Renomear o binário dentro dos arquivos de lançamento do nome específico da plataforma para apenas `glossia`.
- Remover o xattr de quarentena do macOS dos binários antes do empacotamento.

## 0.14.0

*2026-02-14*

#### Recursos

- Adicionar script de liberação local e fluxo de trabalho de changelog mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de Bug

- Tornar a configuração do provedor OAuth opcional em produção. O aplicativo deve iniciar mesmo sem as credenciais GitHub/GitLab OAuth definidas. Configure os provedores apenas quando as variáveis de ambiente estiverem presentes.
- Padronize a porta 4000 para produção e mantenha 4050 para desenvolvimento. O proxy de produção espera o aplicativo na porta 4000. O `runtime.exs` padrão era 4050, o que causava falhas nas verificações de saúde durante o deploy.

#### Funcionalidades

- Adicionar aplicativo Phoenix com login OAuth, aprimoramentos de documentação e melhorias de interface do usuário.
- Use o logotipo arredondado como favicon.
- Migrar CLI para Bun e atualizar builds executáveis de CI.

## 0.1.0

*2026-02-12*

#### Correções de Bugs

- Prevenir transbordamento horizontal de trechos de código no mobile.
- Adicionar margem direita adequada aos trechos de código em dispositivos móveis.
- Melhorar o layout responsivo em dispositivos móveis para evitar desbordamento horizontal.
- Aplicar formatação biome.
- Adicionar títulos de grupo ao modelo de notas de lançamento.
- Atualizar o fluxo de trabalho de tradução do Bun para o Rust.
- Alinhar o corpo do post ao layout Hero e melhorar o conteúdo do post de blog.
- Centralizar o conteúdo do post de blog horizontalmente.
- Corrigir o pânico ao truncar resultados de ferramentas de UTF-8 de múltiplos bytes.

#### Funcionalidades

- Adicionar seção de ferramentas de primeira parte e site.
- Destacar as etapas de verificação de ferramentas.
- Simplificar a saída de progresso.
- Aplicar tonalidade nas linhas de progresso.
- Exibir atividade de tradução e validação.
- Formatar as linhas de ferramentas.
- Tornar o site responsivo com menu móvel e layout de múltiplos breakpoints.
- Reimplementar CLI em Bun/TypeScript.
- Adicionar fluxo de trabalho CI e testes.
- Adicionar verificação de formatação com Biome.
- Adicionar seção de Refinamento Progressivo à página inicial.
- Adicionar seção de blog com suporte de SEO e primeira publicação de blog.
- Unificar a saída do CLI com formato de verbos alinhado à direita.
- Colorizar a saída do CLI com formatação de mensagens mais rica.
- Adicionar imagem quadrada do OG e tags meta do cartão do Twitter.
- Torne o agente coordenador autônomo com uso de ferramentas.
- Reescrita `glossia init` com o Protocolo do Agente Cliente (ACP).
- Adicione suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações

- Separação do CI em jobs separados de formatação, verificação de tipos, testes e build.
- Reescrita do CLI do TypeScript/Bun para Rust.