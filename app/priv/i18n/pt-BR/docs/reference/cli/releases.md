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

- Renomear o binário nos arquivos de liberação do nome específico da plataforma para apenas `glossia`.
- Remover o xattr de quarentena do macOS dos binários antes do empacotamento.

## 0.14.0

*2026-02-14*

#### Funcionalidades

- Adicionar script de lançamento local e fluxo de alterações mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de Bug

- Torne a configuração do provedor OAuth opcional em produção. O app deve iniciar mesmo sem as credenciais OAuth do GitHub/GitLab definidas. Configure os provedores apenas quando as variáveis de ambiente estiverem presentes.
- Padronize a porta 4000 para produção e mantenha 4050 para o desenvolvimento. O proxy de produção espera o app na porta 4000. O `runtime.exs` padrão era 4050, o que causava falhas nos checks de saúde durante o deploy.

#### Funcionalidades

- Adicionar app Phoenix com login OAuth, melhorias na documentação e na interface do usuário.
- Usar o logotipo arredondado como favicon.
- Migrar o CLI para o Bun e atualizar os builds executáveis de CI.

## 0.1.0

*2026-02-12*

#### Correções de bugs

- Prevenir o transbordamento horizontal de trechos de código em dispositivos móveis.
- Adicionar margem direita adequada para trechos de código no mobile.
- Melhorar o layout responsivo para mobile para evitar desbordamento horizontal.
- Aplicar formatação do Biome.
- Adicionar títulos de grupo ao modelo de notas de lançamento.
- Atualizar o fluxo de trabalho de tradução do Bun para o Rust.
- Alinhar o corpo do post ao layout Hero e melhorar o conteúdo dos posts do blog.
- Centralizar o conteúdo do post do blog horizontalmente.
- Corrigir o pânico ao truncar resultados da ferramenta UTF-8 de múltiplos bytes.

#### Funcionalidades

- Adicionar seção de ferramentas de primeira parte e de site.
- Destacar etapas de verificação de ferramentas.
- Simplificar a saída de progresso.
- Colorir as linhas de progresso.
- Exibir atividade de tradução e validação.
- Formatar as linhas de ferramentas.
- Tornar o site responsivo com menu mobile e layout de múltiplos breakpoints.
- Reimplementar CLI em Bun/TypeScript.
- Adicionar fluxo de trabalho CI e testes.
- Adicionar verificação de formato com Biome.
- Adicionar seção de Refinamento Progressivo à página inicial.
- Adicionar seção de blog com suporte a SEO e primeiro post.
- Unificar saída do CLI com formato de verbo alinhado à direita.
- Colorizar saída do CLI com formatação de mensagens mais rica.
- Adicionar imagem quadrada Open Graph e tags meta do cartão do Twitter.
- Torne o agente coordenador agêntico com uso de ferramentas.
- Reescrever `glossia init` com o Protocolo de Cliente de Agentes (ACP).
- Adicionar suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações

- Dividir o CI em jobs separados de formato, typecheck, teste e build.
- Reescrever a CLI do TypeScript/Bun para Rust.