%{
  title: "Lançamentos",
  summary: "Histórico de lançamentos CLI.",
  category: "Referência",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correções de Bugs

- Renomeia o binário nos arquivos de release do nome específico da plataforma para apenas `glossia`.
- Remova o xattr de quarentena do macOS dos binários antes do empacotamento.

## 0.14.0

*2026-02-14*

#### Funcionalidades

- Adicionar script de lançamento local e fluxo de trabalho de changelog mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de bugs

- Torne a configuração do provedor OAuth opcional em produção. O aplicativo deve iniciar mesmo sem credenciais OAuth do GitHub/GitLab configuradas. Configure provedores apenas quando as variáveis de ambiente estiverem presentes.
- Use a porta 4000 como padrão para produção e mantenha 4050 para desenvolvimento. O proxy de produção espera o aplicativo na porta 4000. O `runtime.exs` padrão era 4050, o que causava falhas nas verificações de saúde durante a implantação.

#### Funcionalidades

- Adiciona aplicativo Phoenix com login OAuth, melhorias na documentação e na interface do usuário.
- Usa logotipo arredondado como favicon.
- Migra CLI para Bun e atualiza builds executáveis de CI.

## 0.1.0

*2026-02-12*

#### Correções de Bug

- Previne o transbordamento horizontal de trechos de código no mobile.
- Adicionar margem direita adequada aos trechos de código no mobile.
- Melhorar o layout responsivo mobile para evitar transbordamento horizontal.
- Aplicar formatação Biome.
- Adicionar cabeçalhos de grupo ao modelo de notas de lançamento.
- Atualizar o fluxo de trabalho de tradução do Bun para Rust.
- Alinhar o corpo do post ao layout Hero e melhorar o conteúdo dos posts do blog.
- Centralizar o conteúdo do post do blog horizontalmente.
- Corrigir o pânico ao truncar resultados de ferramentas UTF-8 multi-byte.

#### Funcionalidades

- Adicionar seção de ferramentas de primeira parte e website.
- Mostrar etapas de verificação de ferramentas.
- Simplificar saída de progresso.
- Colorir linhas de progresso.
- Mostrar atividade de tradução e validação.
- Formatar linhas de ferramentas.
- Tornar o website responsivo com menu mobile e layout multi-breakpoint.
- Reimplementar CLI em Bun/TypeScript.
- Adicionar fluxo de CI e testes.
- Adicionar verificação de formatação com Biome.
- Adicionar seção de Refinamento Progressivo à página inicial.
- Adicionar seção de blog com suporte SEO e primeira postagem do blog.
- Unificar saída do CLI com formato de verbo alinhado à direita.
- Colorizar saída do CLI com formatação de mensagens mais rica.
- Adicionar imagem OG quadrada e tags meta de Twitter Card.
- Torne o agente coordenador agênte com uso de ferramentas.
- Reescrita `glossia init` com o Protocolo do Agente do Cliente (ACP).
- Adiciona suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações

- Divida o CI em tarefas separadas de formato, verificação de tipos, teste e build.
- Reescreve a CLI do TypeScript/Bun para Rust.