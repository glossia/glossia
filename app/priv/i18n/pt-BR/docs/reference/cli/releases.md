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
- Renomeie o binário dentro dos arquivos de lançamento do nome específico da plataforma para apenas `glossia`.
- Remova o xattr de quarentena do macOS dos binários antes do empacotamento.

## 0.14.0

*2026-02-14*

#### Funcionalidades
- Adicione script de lançamento local e fluxo de trabalho de changelog mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de bugs
- Corrija o tratamento da configuração do provedor de login hospedado.
- Corrija as verificações de saúde do serviço hospedado.

#### Funcionalidades
- Adicione aplicativo Phoenix com login OAuth, melhorias na documentação e melhorias na interface do usuário.
- Use logotipo arredondado como favicon.
- Migre a CLI para o Bun e atualize as builds executáveis do CI.

## 0.1.0

*2026-02-12*

#### Correções de bugs
- Evite o transbordamento horizontal de trechos de código no mobile.
- Adicione a margem direita adequada aos trechos de código no mobile.
- Melhore o layout responsivo no mobile para evitar o transbordamento horizontal.
- Aplique a formatação do biome.
- Adicione títulos de grupo ao modelo de notas de lançamento.
- Atualize o fluxo de trabalho de tradução do Bun para o Rust.
- Alinhe o corpo do post com o layout herói e melhore o conteúdo do post do blog.
- Centralize o conteúdo do post do blog horizontalmente.
- Corrija o pânico ao truncar resultados multibyte UTF-8 da ferramenta.

#### Funcionalidades
- Adicione ferramentas de primeira parte e a seção de site.
- Exiba as etapas de verificação da ferramenta.
- Simplifique a saída de progresso.
- Adicione cor às linhas de progresso.
- Exiba as atividades de tradução e validação.
- Formate as linhas de ferramenta.
- Torne o site responsivo com menu mobile e layout de múltiplos breakpoints.
- Reimplemente a CLI em Bun/TypeScript.
- Adicione fluxo de trabalho de CI e testes.
- Adicione verificação de formatação com Biome.
- Adicione seção de Refinamento Progressivo na página inicial.
- Adicione seção de blog com suporte ao SEO e o primeiro post do blog.
- Unifique a saída da CLI com o formato de verbo alinhado à direita.
- Colorize a saída da CLI com formatação de mensagens mais ricas.
- Adicione imagem quadrada OG e tags meta de card do Twitter.
- Torne o agente coordenador autônomo com uso de ferramentas.
- Reescreva `glossia init` com o Protocolo de Cliente de Agente (ACP).
- Adicione suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações
- Divida o CI em trabalhos separados de formatação, verificação de tipos, teste e compilação.
- Reescreva a CLI do TypeScript/Bun para Rust.
