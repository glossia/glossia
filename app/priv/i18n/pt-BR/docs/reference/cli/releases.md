%{
  title: "Versões",
  summary: "Histórico de versões da CLI.",
  category: "reference",
  subcategory: "cli",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correções de bugs
- Renomear o binário nos arquivos compactados de versão, substituindo o nome específico da plataforma por apenas `glossia`.
- Remover o atributo estendido de quarentena do macOS dos binários antes do empacotamento.

## 0.14.0

*2026-02-14*

#### Funcionalidades
- Adicionar script local de versão e fluxo de trabalho de changelog mantido manualmente.

## 0.2.0

*2026-02-14*

#### Correções de bugs
- Tornar opcional a configuração dos provedores OAuth em produção. O aplicativo deve inicializar mesmo sem as credenciais OAuth do GitHub/GitLab definidas. Configurar os provedores somente quando as variáveis de ambiente estiverem presentes.
- Usar a porta 4000 por padrão em produção e manter a 4050 no ambiente de desenvolvimento. O proxy de produção espera que o aplicativo esteja na porta 4000. O valor padrão de `runtime.exs` era 4050, o que fazia as verificações de integridade falharem durante a implantação.

#### Funcionalidades
- Adicionar aplicativo Phoenix com login via OAuth, melhorias na documentação e aprimoramentos na interface do usuário.
- Usar o logotipo arredondado como favicon.
- Migrar a interface de linha de comando para Bun e atualizar as compilações de executáveis da integração contínua.

## 0.1.0

*2026-02-12*

#### Correções de bugs
- Evitar que trechos de código ultrapassem horizontalmente a tela em dispositivos móveis.
- Adicionar margem direita adequada aos trechos de código em dispositivos móveis.
- Melhorar o layout responsivo para dispositivos móveis a fim de evitar o transbordamento horizontal.
- Aplicar a formatação do Biome.
- Adicionar títulos de grupos ao modelo de notas de versão.
- Migrar o fluxo de tradução de Bun para Rust.
- Alinhar o corpo das publicações ao layout principal e melhorar o conteúdo das publicações do blog.
- Centralizar horizontalmente o conteúdo das publicações do blog.
- Corrigir falha crítica ao truncar resultados de ferramentas com caracteres UTF-8 de múltiplos bytes.

#### Funcionalidades
- Adicionar ferramentas próprias e uma seção no site.
- Exibir as etapas de verificação das ferramentas.
- Simplificar a saída de progresso.
- Aplicar tonalidade às linhas de progresso.
- Exibir as atividades de tradução e validação.
- Formatar as linhas das ferramentas.
- Tornar o site responsivo, com menu para dispositivos móveis e layout adaptado a vários pontos de quebra.
- Reimplementar a interface de linha de comando em Bun/TypeScript.
- Adicionar fluxo de integração contínua e testes.
- Adicionar verificação de formatação com o Biome.
- Adicionar a seção de Refinamento progressivo à página inicial.
- Adicionar seção de blog com suporte à otimização para mecanismos de busca e a primeira publicação.
- Unificar a saída da interface de linha de comando com o formato de verbos alinhados à direita.
- Colorir a saída da interface de linha de comando com uma formatação de mensagens mais completa.
- Adicionar imagem quadrada do Open Graph e metatags de cartão do Twitter.
- Tornar o agente coordenador capaz de agir de forma autônoma usando ferramentas.
- Reescrever `glossia init` com o Protocolo de Cliente de Agente (Agent Client Protocol, ACP).
- Adicionar suporte ao Gemini, validação automática, rastreamento de tokens e melhorias de confiabilidade.

#### Refatorações
- Dividir a integração contínua em tarefas separadas de formatação, verificação de tipos, testes e compilação.
- Reescrever a interface de linha de comando de TypeScript/Bun para Rust.