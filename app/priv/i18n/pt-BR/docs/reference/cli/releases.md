%{
  title: "Lançamentos",
  summary: "Histórico de lançamentos do CLI.",
  category: "Referência",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correções de Bug

- Renomeia o binário dentro dos arquivos de lançamento do nome específico da plataforma apenas para `glossia`.
- Remove o atributo xattr de quarentena do macOS dos binários antes do empacotamento.

## 0.14.0

*2026-02-14*

#### Funcionalidades

- Adiciona script de lançamento local e fluxo de trabalho de registro de alterações mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de Bug

- Torna a configuração do provedor OAuth opcional na produção. O aplicativo deve iniciar mesmo sem as credenciais OAuth do GitHub/GitLab definidas. Configure os provedores apenas quando as variáveis de ambiente estiverem presentes.
- Padrão na porta 4000 para produção e mantenha 4050 para desenvolvimento. O proxy de produção espera o aplicativo na porta 4000. O padrão em `runtime.exs` era 4050, o que causou falha nas verificações de saúde durante a implantação.

#### Funcionalidades

- Adiciona aplicativo Phoenix com login OAuth, melhorias de documentação e aprimoramentos de interface.
- Utiliza o logomarca arredondado como favicon.
- Migra CLI para Bun e atualiza builds executáveis de CI.

## 0.1.0

*2026-02-12*

#### Correções de Bug

- Impede o desbordamento horizontal de trecho de código no mobile.
- Adiciona margem direita adequada aos trechos de código no mobile.
- Melhora o layout responsivo do mobile para evitar desbordamento horizontal.
- Aplica formatação Biome.
- Adiciona títulos de grupo ao modelo de notas de lançamento.
- Atualiza fluxo de trabalho de tradução de Bun para Rust.
- Alinha o corpo do post com o layout de destaque e melhora o conteúdo do post do blog.
- Centraliza o conteúdo do post do blog horizontalmente.
- Corrige o panic ao truncar resultados de ferramentas UTF-8 de múltiplos bytes.

#### Funcionalidades

- Adiciona seção de ferramentas próprias e site.
- Exibe as etapas de verificação das ferramentas.
- Simplifica a saída de progresso.
- Aplica um tom às linhas de progresso.
- Mostra atividade de tradução e validação.
- Formata as linhas de ferramentas.
- Deixa o site responsivo com menu mobile e layout de múltiplos pontos de quebra.
- Reimplementa CLI em Bun/TypeScript.
- Adiciona fluxo de trabalho CI e testes.
- Adiciona verificação de formatação com Biome.
- Adiciona seção de Refinamento Progressivo à página inicial.
- Adiciona seção de blog com suporte para SEO e primeiro post do blog.
- Unifica saída CLI com formato de verbo alinhado à direita.
- Adiciona cores à saída CLI com formatação de mensagens mais rica.
- Adiciona imagem quadrada de OG e etiquetas meta de cartão do Twitter.
- Torna o agente coordenador agêntrico com uso de ferramentas.
- Reescreve `glossia init` com Protocolo de Cliente de Agente (ACP).
- Adiciona suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações

- Divide CI em trabalhos de formatação, typecheck, teste e build separados.
- Reescreve CLI de TypeScript/Bun para Rust.