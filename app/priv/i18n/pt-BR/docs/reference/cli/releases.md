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

- Renomear o binário dentro dos arquivos de release do nome específico da plataforma para apenas `glossia`.
- Remover o xattr de quarentena do macOS dos binários antes do empacotamento.

## 0.14.0

*2026-02-14*

#### Funcionalidades

- Adicionar script de lançamento local e fluxo de trabalho de log de alterações mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de Bugs

- Torne a configuração do provedor OAuth opcional em produção. O aplicativo deve iniciar mesmo sem as credenciais OAuth do GitHub/GitLab configuradas. Configure os provedores apenas quando as variáveis de ambiente estiverem presentes.
- Utilize a porta 4000 como padrão para produção e mantenha 4050 para desenvolvimento. O proxy de produção espera o aplicativo na porta 4000. O `runtime.exs` padrão era 4050, o que causava que as verificações de saúde falhassem durante a implantação.

#### Funcionalidades

- Adicionar aplicativo Phoenix com login OAuth, melhorias na documentação e na interface do usuário.
- Usar logomarca arredondada como favicon.
- Migrar CLI para Bun e atualizar os builds executáveis da CI.

## 0.1.0

*2026-02-12*

#### Correções de Bugs

- Prevenir transbordamento horizontal de trechos de código em dispositivos móveis.
- Adicione margem direita adequada aos trechos de código no mobile.
- Melhore o layout responsivo do mobile para evitar o desbordamento horizontal.
- Aplique a formatação do biome.
- Adicione títulos de grupo ao modelo de notas de versão.
- Atualize o fluxo de trabalho de tradução do Bun para o Rust.
- Alinhe o corpo do post com o layout hero e melhore o conteúdo da postagem de blog.
- Centralize o conteúdo da postagem de blog horizontalmente.
- Corrija o pânico ao truncar resultados de ferramentas UTF-8 multi-byte.

#### Funcionalidades

- Adicionar seção de ferramentas de primeira parte e do site.
- Expor etapas de verificação das ferramentas.
- Simplificar a saída de progresso.
- Colorir as linhas de progresso.
- Mostrar atividade de tradução e validação.
- Formatar linhas das ferramentas.
- Tornar o site responsivo com menu mobile e layout de múltiplos pontos de quebra.
- Reimplementar CLI em Bun/TypeScript.
- Adicionar fluxo de trabalho CI e testes.
- Adicionar verificação de formato com Biome.
- Adicionar seção de Refinamento Progressivo à página inicial.
- Adicionar seção de blog com suporte de SEO e primeiro post de blog.
- Unificar saída do CLI com formato de verbo alinhado à direita.
- Colorizar saída do CLI com formatação de mensagem mais rica.
- Adicionar imagem quadrada OG e meta tags de cartão do Twitter.
- Torne o agente coordenador agêntico com uso de ferramentas.
- Reescrita `glossia init` com Protocolo de Cliente de Agente (ACP).
- Adicione suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações

- Divida o CI em tarefas separadas de formatação, verificação de tipo, testes e compilação.
- Reescreva o CLI de TypeScript/Bun para Rust.