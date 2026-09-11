%{
  title: "Lançamentos",
  summary: "Histórico de lançamentos CLI.",
  category: "referência",
  subcategory: "cli",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correções de Bugs

- Renomeie o binário nos arquivos de lançamento do nome específico da plataforma para apenas `glossia`.
- Remova o atributo xattr de quarentena do macOS dos binários antes da empacotagem.

## 0.14.0

*2026-02-14*

#### Funcionalidades

- Adicionar script de release local e fluxo de trabalho de registro de alterações mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de bugs

- Torne a configuração do provedor OAuth opcional na produção. O app deve iniciar mesmo sem as credenciais OAuth do GitHub/GitLab definidas. Configure os provedores apenas quando as variáveis de ambiente estiverem presentes.
- Utilize a porta 4000 como padrão para a produção e mantenha 4050 para o desenvolvimento. O proxy de produção espera o app na porta 4000. O `runtime.exs` o padrão era 4050, o que fez com que as verificações de saúde falhassem durante a implantação.

#### Recursos

- Adicionar aplicativo Phoenix com login OAuth, melhorias de documentação e aprimoramentos de interface do usuário.
- Use logo arredondada como favicon.
- Migrar CLI para Bun e atualizar builds executáveis do CI.

## 0.1.0

*2026-02-12*

#### Correções de Bugs

- Prevenir transbordamento horizontal de trechos de código no mobile.
- Adicionar margem direita adequada aos trechos de código no mobile.
- Melhorar o layout responsivo do mobile para evitar transbordamento horizontal.
- Aplicar a formatação Biome.
- Adicionar títulos de grupo ao modelo de notas de lançamento.
- Atualizar o fluxo de trabalho de tradução do Bun para Rust.
- Alinhar o corpo do post com o layout do herói e melhorar o conteúdo do post de blog.
- Centralizar o conteúdo do post de blog horizontalmente.
- Corrigir o pânico ao truncar resultados de ferramentas UTF-8 multi-byte.

#### Funcionalidades

- Adicionar ferramentas de primeira parte e seção do site.
- Destacar etapas de verificação de ferramentas.
- Simplificar a saída de progresso.
- Colorir linhas de progresso.
- Exibir atividade de tradução e validação.
- Formatar linhas de ferramentas.
- Tornar o site responsivo com menu móvel e layout multiponto.
- Reimplementar CLI em Bun/TypeScript.
- Adicionar fluxo de trabalho de CI e testes.
- Adicionar verificação de formatação com Biome.
- Adicionar seção de Refinamento Progressivo à página inicial.
- Adicionar seção de blog com suporte ao SEO e primeiro post de blog.
- Unificar saída CLI com formato de verbo alinhado à direita.
- Colorizar saída CLI com formatação de mensagens mais rica.
- Adicionar imagem quadrada OG e tags meta do Twitter Card.
- Torna o agente coordenador autônomo com uso de ferramentas.
- Reescrever `glossia init` com Protocolo de Cliente de Agente (ACP).
- Adiciona suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações

- Divide o CI em tarefas separadas para formatação, verificação de tipos, testes e compilação.
- Reescreve a CLI de TypeScript/Bun para Rust.