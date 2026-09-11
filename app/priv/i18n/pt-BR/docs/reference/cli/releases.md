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

#### Correções de bug

- Renomear o binário nos arquivos de lançamento do nome específico de plataforma para apenas `glossia`.
- Remover o xattr de quarentena do macOS dos binários antes do empacotamento.

## 0.14.0

*2026-02-14*

#### Funcionalidades

- Adicione script de release local e fluxo de trabalho de registro de alterações mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de bugs

- Torne a configuração do provedor OAuth opcional em produção. O aplicativo deve iniciar mesmo sem credenciais OAuth do GitHub/GitLab definidas. Configure apenas os provedores quando as variáveis de ambiente estiverem presentes.
- Padronize a porta 4000 para produção e mantenha 4050 para desenvolvimento. O proxy de produção espera o aplicativo na porta 4000. O `runtime.exs` padrão era 4050, o que causava falhas nas verificações de saúde durante o deploy.

#### Funcionalidades

- Adicionar aplicativo Phoenix com login OAuth, melhorias na documentação e na interface.
- Usar logotipo arredondado como ícone.
- Migrar CLI para Bun e atualizar as compilações executáveis da CI.

## 0.1.0

*2026-02-12*

#### Correções de Bugs

- Prevenir transbordamento horizontal de trechos de código em dispositivos móveis.
- Adicionar margem direita adequada aos trechos de código no mobile.
- Melhorar o layout responsivo do mobile para evitar transbordamento horizontal.
- Aplicar formatação biome.
- Adicionar cabeçalhos de grupo ao modelo de notas de versão.
- Atualizar o fluxo de tradução do Bun para o Rust.
- Alinhar o corpo do post com o layout hero e melhorar o conteúdo do post de blog.
- Centralizar o conteúdo do post de blog horizontalmente.
- Corrigir o pânico ao truncar resultados de ferramentas com múltiplos bytes UTF-8.

#### Recursos

- Adicionar ferramentas de primeira parte e seção do site.
- Destacar etapas de verificação de ferramentas.
- Simplificar a saída de progresso.
- Colorir as linhas de progresso.
- Mostrar atividades de tradução e validação.
- Formatar as linhas das ferramentas.
- Tornar o site responsivo com menu mobile e layout de múltiplos breakpoints.
- Reimplement CLI em Bun/TypeScript.
- Adicionar fluxo de CI e testes.
- Adicionar verificação de formatação com Biome.
- Adicionar seção de Refinamento Progressivo à página inicial.
- Adicionar seção de blog com suporte SEO e primeira postagem.
- Unificar saída do CLI com formato de verbo alinhado à direita.
- Colorizar saída do CLI com formatação de mensagens mais rica.
- Adicionar imagem OG quadrada e tags meta do cartão do Twitter.
- Tornar o agente coordenador autônomo com uso de ferramentas.
- Reescrita `glossia init` com Protocolo de Cliente de Agente (ACP).
- Adicionar suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações

- Dividir CI em jobs separados de formatação, verificação de tipos, testes e compilação.
- Reescrever CLI de TypeScript/Bun para Rust.