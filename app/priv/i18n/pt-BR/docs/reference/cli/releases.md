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

#### Correções de Bugs

- Renomeie o binário dentro dos arquivos de release do nome específico da plataforma para apenas `glossia`.
- Remova o atributo xattr de quarentena do macOS dos binários antes do empacotamento.

## 0.14.0

*2026-02-14*

#### Funcionalidades

- Adiciona script de lançamento local e fluxo de trabalho de histórico de alterações mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de Bugs

- Torna a configuração do provedor OAuth opcional em produção. O app deve iniciar mesmo sem credenciais OAuth do GitHub/GitLab configuradas. Configure os provedores apenas quando as variáveis de ambiente estiverem presentes.
- Use a porta 4000 como padrão para produção e mantenha 4050 para desenvolvimento. O proxy de produção espera que o app esteja na porta 4000. O `runtime.exs` padrão era 4050, o que causou falhas nas verificações de saúde durante a implantação.

#### Funcionalidades

- Adicione o app Phoenix com login OAuth, aprimoramentos na documentação e melhorias na interface do usuário.
- Use o logotipo arredondado como favicon.
- Migre CLI para Bun e atualize os builds executáveis do CI.

## 0.1.0

*2026-02-12*

#### Correções de bugs

- Previne o desbordamento horizontal de trechos de código em dispositivos móveis.
- Adicione margem direita adequada aos trechos de código nos dispositivos móveis.
- Melhore o layout responsivo para dispositivos móveis para evitar transbordamento horizontal.
- Aplique a formatação do biome.
- Adicione títulos de grupo ao modelo de notas de versão.
- Atualize o fluxo de trabalho de tradução do Bun para Rust.
- Alinhe o corpo do post ao layout do herói e melhore o conteúdo do post de blog.
- Centralize o conteúdo do post de blog horizontalmente.
- Corrija o pânico ao truncar resultados de ferramentas em UTF-8 de múltiplos bytes.

#### Funcionalidades

- Adicionar ferramentas e seção de site de primeira parte.
- Expor etapas de verificação de ferramenta.
- Simplificar a saída de progresso.
- Colorir as linhas de progresso.
- Exibir atividade de tradução e validação.
- Formatar as linhas de ferramenta.
- Tornar o site responsivo com menu móvel e layout de múltiplos pontos de quebra.
- Reimplementar CLI no Bun/TypeScript.
- Adicionar fluxo de CI e testes.
- Adicionar verificação de formato com Biome.
- Adicionar seção de Refinação Progressiva à página inicial.
- Adicionar seção de blog com suporte ao SEO e primeira postagem.
- Unificar saída da CLI com formato de verbos alinhado à direita.
- Colorizar saída da CLI com formatação de mensagens mais rica.
- Adicionar imagem quadrada OG e tags meta de cartão do Twitter.
- Torne o agente coordenador autônomo com uso de ferramentas.
- Reescrita `glossia init` com o Agent Client Protocol (ACP).
- Adicione suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações

- Divida o CI em jobs separados de formatação, verificação de tipos, teste e compilação.
- Reescreva o CLI de TypeScript/Bun para Rust.