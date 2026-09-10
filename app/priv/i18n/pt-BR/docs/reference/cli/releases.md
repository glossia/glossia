%{
  title: "Lançamentos",
  summary: "Histórico de lançamentos do CLI.",
  category: "referência",
  subcategory: "cli",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correções de bugs

- Renomear o binário dentro dos arquivos de lançamento do nome específico da plataforma para apenas `glossia`.
- Remover o xattr de quarentena do macOS dos binários antes do empacotamento.

## 0.14.0

*2026-02-14*

#### Funcionalidades

- Adicionar script de release local e fluxo de trabalho de changelog mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de Bug

- Torne a configuração do provedor de OAuth opcional na produção. O aplicativo deve iniciar mesmo sem as credenciais OAuth do GitHub/GitLab configuradas. Configure os provedores apenas quando as variáveis de ambiente estiverem presentes.
- Use a porta 4000 como padrão para a produção e mantenha 4050 para o desenvolvimento. O proxy de produção espera o aplicativo na porta 4000. O `runtime.exs` padrão era 4050, o que causou falha nas verificações de saúde durante a implantação.

#### Funcionalidades

- Adicionar app Phoenix com login OAuth, melhorias na documentação e na interface do usuário.
- Usar logomarca arredondada como favicon.
- Migrar CLI para Bun e atualizar builds executáveis do CI.

## 0.1.0

*2026-02-12*

#### Correções de Bug

- Prevenir transbordamento horizontal de trechos de código no mobile.
- Adicione margem direita adequada para trechos de código em dispositivos móveis.
- Melhore o layout responsivo móvel para evitar transbordamento horizontal.
- Aplique a formatação do Biome.
- Adicione títulos de grupo ao modelo de notas de lançamento.
- Atualize o fluxo de tradução de Bun para Rust.
- Alinhe o corpo do post ao layout de destaque e melhore o conteúdo do post do blog.
- Centralize horizontalmente o conteúdo do post do blog.
- Corrija o pânico ao truncar resultados de ferramentas UTF-8 de múltiplos bytes.

#### Funcionalidades

- Adicionar ferramentas de primeira parte e seção do site.
- Exibir etapas de verificação de ferramentas.
- Simplificar a saída de progresso.
- Colorir linhas de progresso.
- Mostrar atividade de tradução e validação.
- Formatar linhas de ferramentas.
- Tornar o site responsivo com menu móvel e layout de múltiplos pontos de quebra.
- Reimplementar CLI no Bun/TypeScript.
- Adicionar workflow de CI e testes.
- Adicionar verificação de formatação com o Biome.
- Adicionar seção de Refinamento Progressivo à página inicial.
- Adicionar seção de blog com suporte a SEO e a primeira postagem.
- Unificar a saída do CLI com formato de verbo alinhado à direita.
- Colorizar a saída do CLI com formatagem de mensagens mais rica.
- Adicionar imagem quadrada OG e tags meta do Twitter Card.
- Torna o agente coordenador agêntico com uso de ferramentas.
- Reescrita `glossia init` com o Protocolo de Cliente do Agente (ACP).
- Adiciona suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações

- Divide a CI em tarefas separadas de formatação, verificação de tipos, testes e compilação.
- Reescreve a CLI de TypeScript/Bun para Rust.