%{
  title: "Lançamentos",
  summary: "Histórico de lançamentos do CLI.",
  category: "Referência",
  subcategory: "cli",
  order: 2
}
---

## 0.14.1

*2026-02-14*

#### Correções de bugs
- Renomear o binário dentro dos arquivos de release do nome específico da plataforma apenas para `glossia`.
- Remover o atributo xattr de quarentena macOS dos binários antes da embalagem.

## 0.14.0

*2026-02-14*

#### Funcionalidades
- Adicionar script de release local e fluxo de trabalho de changelog mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de bugs
- Corrigir o tratamento de configuração do provedor de login hospedado.
- Corrigir as verificações de saúde do serviço hospedado.

#### Funcionalidades
- Adicionar aplicativo Phoenix com login OAuth, melhorias de documentação e interface de usuário.
- Usar logotipo arredondado como favicon.
- Migrar CLI para Bun e atualizar builds executáveis de CI.

## 0.1.0

*2026-02-12*

#### Correções de bugs
- Prevenir desbordamento horizontal de trechos de código no mobile.
- Adicionar margem direita adequada aos trechos de código no mobile.
- Melhorar o layout responsivo do mobile para evitar desbordamento horizontal.
- Aplicar formatação Biome.
- Adicionar cabeçalhos de grupo ao modelo de notas de release.
- Atualizar o fluxo de trabalho de tradução do Bun para Rust.
- Alinhar o corpo do post com o layout hero e melhorar o conteúdo do post do blog.
- Centralizar o conteúdo do post do blog horizontalmente.
- Corrigir o pânico ao truncar resultados de ferramentas UTF-8 de múltiplos bytes.

#### Funcionalidades
- Adicionar seção de ferramentas de primeira parte e site.
- Exibir etapas de verificação de ferramentas.
- Simplificar a saída de progresso.
- Colorir as linhas de progresso.
- Exibir a atividade de tradução e validação.
- Formatar as linhas de ferramentas.
- Tornar o site responsivo com menu mobile e layout com múltiplos pontos de quebra.
- Reimplementar CLI em Bun/TypeScript.
- Adicionar fluxo de trabalho CI e testes.
- Adicionar verificação de formatação com Biome.
- Adicionar seção Refinamento Progressivo na página inicial.
- Adicionar seção de blog com suporte SEO e primeiro post do blog.
- Unificar a saída do CLI com formato de verbo alinhado à direita.
- Colorir a saída do CLI com formatação de mensagens mais rica.
- Adicionar imagem OG quadrada e meta tags de cartão do Twitter.
- Tornar o agente coordenador autônomo com uso de ferramentas.
- Reescrever `glossia init` com Agent Client Protocol (ACP).
- Adicionar suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações
- Dividir CI em tarefas separadas de formatação, verificação de tipos, teste e build.
- Reescrever CLI de TypeScript/Bun para Rust.
