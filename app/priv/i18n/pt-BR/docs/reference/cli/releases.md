%{
  title: "Versões",
  summary: "Histórico de lançamentos CLI.",
  category: "Referência",
  subcategory: "CLI",
  order: 2
}
---

## 0.14.1

*2026-02-14*

#### Correções de Bug
- Renomear o binário dentro dos arquivos de lançamento do nome específico da plataforma apenas para `glossia`.
- Remover o atributo xattr de quarentena do macOS dos binários antes do empacotamento.

## 0.14.0

*2026-02-14*

#### Melhorias
- Adicionar script de lançamento local e fluxo de trabalho de changelog mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de Bug
- Corrigir o tratamento da configuração do provedor de login hospedado.
- Corrigir as verificações de saúde do serviço hospedado.

#### Melhorias
- Adicionar aplicativo Phoenix com login OAuth, melhorias de documentação e na interface do usuário.
- Usar logotipo arredondado como favicon.
- Migrar CLI para Bun e atualizar os builds executáveis de CI.

## 0.1.0

*2026-02-12*

#### Correções de Bug
- Impedir transbordamento horizontal de trechos de código no mobile.
- Adicionar margem direita adequada aos trechos de código no mobile.
- Melhorar o layout responsivo do mobile para evitar transbordamento horizontal.
- Aplicar formatação Biome.
- Adicionar títulos de grupo ao modelo de notas de lançamento.
- Atualizar o fluxo de trabalho de tradução do Bun para o Rust.
- Alinhar o corpo do post com o layout de destaque e melhorar o conteúdo do post.
- Centralizar horizontalmente o conteúdo do post.
- Corrigir panic ao truncar resultados de ferramentas UTF-8 de múltiplos bytes.

#### Melhorias
- Adicionar seção de ferramentas próprias e do site.
- Exibir etapas de verificação de ferramentas.
- Simplificar a saída de progresso.
- Colorir as linhas de progresso.
- Mostrar atividade de tradução e validação.
- Formatar linhas de ferramentas.
- Tornar o site responsivo com menu mobile e layout de múltiplos pontos de quebra.
- Reimplementar CLI em Bun/TypeScript.
- Adicionar fluxo de trabalho de CI e testes.
- Adicionar verificação de formatação com Biome.
- Adicionar seção de Refinamento Progressivo na página inicial.
- Adicionar seção de blog com suporte a SEO e primeiro post.
- Unificar a saída da CLI com formato de verbos alinhados à direita.
- Colorir a saída da CLI com formatação de mensagens mais rica.
- Adicionar imagem OG quadrada e tags meta do cartão do Twitter.
- Tornar o agente coordenador agêntico com uso de ferramentas.
- Reescrever `glossia init` com o Protocolo de Cliente de Agente (ACP).
- Adicionar suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações
- Dividir CI em jobs separados de formatação, verificação de tipos, testes e build.
- Reescrever CLI do TypeScript/Bun para o Rust.
