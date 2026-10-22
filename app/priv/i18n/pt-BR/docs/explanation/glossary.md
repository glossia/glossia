%{
  title: "Glossário",
  summary:
    "Como o Glossia mantém traduções aprovadas consistentes em todos os idiomas e arquivos.",
  category: "explicação",
  section: "translation",
  order: 5
}
---

Um glossário é um conjunto curado de termos que suas traduções devem renderizar da mesma maneira toda vez. O termo "Commit" no sentido de controle de versão permanece `commit` em espanhol, torna-se `提交` em chinês simplificado e `コミット` em japonês. Uma decisão por idioma, aplicada em todos os lugares.

## Dois lugares onde um glossário pode viver

A Glossia busca em dois lugares por entradas de glossário e as funde no momento da tradução:

- **Seu repositório**, nos arquivos que você já usa para configurações de tradução. `L10N.md` declara os termos, e para cada idioma `L10N/<locale>.md` declara suas traduções. Este é o glossário de autoridade do desenvolvedor: as alterações viajam através de pull requests, cada idioma tem seus próprios revisores que possuem seu próprio arquivo, e arquivos aninhados podem refiná-lo para parte do repositório.
- **Sua conta Glossia**, gerenciada através do painel hospedado. Este é o glossário de autoridade do linguista: revisores e colaboradores de localização adicionam ou refinam entradas sem tocar no código, através do painel, da [REST API](/docs/reference/apis) ou do [servidor MCP](/docs/reference/mcp). Aplica-se a todos os repositórios que a conta traduz.

Ambos os lugares são úteis, e nenhum substitui o outro.

## Quando usar qual

Defina um termo em **sua conta Glossia** quando:

- **Aplica-se a mais de um repositório.** Nomes de produtos, termos de marca e vocabulário da empresa são definidos uma vez e usados em todos os lugares.
- **As pessoas que decidem não trabalham no repositório.** Linguistas, revisores e colaboradores externos podem refinar o glossário mesmo quando o repositório é de código fechado ou não possuem acesso de escrita para ele.
- **Você deseja corrigir um termo sem uma alteração de código.** Uma tradução corrigida aplica-se na próxima execução, sem um pull request contra o código-base.
- **As alterações precisam de revisão e histórico.** Cada edição cria uma nova versão com uma nota de mudança, colaboradores podem propor alterações como sugestões para alguém aprovar, e versões anteriores permanecem disponíveis.
- **Outras ferramentas precisam disso.** Agentes e integrações podem ler o glossário através da REST API e do servidor MCP, por exemplo, para escrever novo conteúdo que já usa os termos aprovados.

Defina um termo em **o seu repositório** quando:

- **Pertence a este código-base.** Um termo cujo significado é específico para um projeto, tal como "commit" significando a ação de controle de versão, fica próximo ao código que o utiliza.
- **Deve mudar junto com o texto de origem.** O termo e o texto que o introduziu serão incluídos no mesmo pull request e serão revisados juntos.
- **Apenas parte do repositório precisa disso.** Um `L10N.md` ou `L10N/<locale>.md` aninhado pode adicionar ou sobrescrever entradas para um diretório, como páginas de marketing.
- **Ele deve sobrescrever o glossário da conta.** Uma entrada de repositório vence uma entrada de conta para o mesmo termo, para os idiomas em que traduz.

## Como eles se combinam

Para cada arquivo e idioma de destino, a Glossia resolve os dois glossários em um conjunto efetivo:

1. Comece com as entradas do glossário da conta para o idioma de destino.
2. Sobreponha as entradas de repositório para aquele idioma: os termos da cadeia `L10N.md` do arquivo que têm uma tradução em sua cadeia `L10N/<locale>.md`. Quando uma entrada de repositório tem o mesmo termo de origem que uma entrada de conta, a entrada de repositório vence.
3. Se um termo de repositório não tem tradução para um idioma, a entrada de conta para aquele idioma ainda se aplica. O repositório nunca bloqueia um idioma para o qual não traduz.

A mescla ocorre **por idioma de destino**, não por entrada. A tradução espanhola de "commit" em `L10N/es.md` substitui a entrada espanhola da conta para "commit", mas não toca na entrada japonesa da conta para o mesmo termo. Os revisores podem ver quais entradas da conta foram substituídas: o resumo da sessão de tradução mostra quantas foram sobrescritas, e o lockfile de cada arquivo lista-os sob `glossary.shadowed`.

## Quando o glossário muda, os arquivos são retraduzidos

Quando você edita uma entrada de glossário, a Glossia apenas re-traduz os arquivos cujo *glossário efetivo mudou*. Se o texto de origem de um arquivo não contém correspondências para o termo editado, suas traduções permanecem inalteradas. Se um arquivo usa o termo, sua próxima passagem de tradução inclui a instrução atualizada.

O mesmo princípio se aplica ao inverso: adicionar um termo usado apenas por um subconjunto de arquivos não força uma execução completa novamente.

## O que um glossário não é

- Não é um dicionário de tradução automática. O modelo da Glossia lê o contexto ao redor e pode renderizar um termo de maneira diferente se a frase o exigir. O glossário é orientação, não substituição.
- Não é todo o guia de estilo. Voz, tom, formalidade e público vivem na configuração de Voz da sua conta e em `L10N.md`. O glossário é apenas para termos individuais e suas traduções aprovadas.
- Não é silencioso. Cada termo aplicado é registrado no lockfile do arquivo para que um revisor possa rastrear exatamente quais entradas de glossário chegaram ao modelo.

## Relacionado

- Adicione seus primeiros termos: [Defina um glossário](/docs/how-to/define-a-glossary).
- Cada campo de entrada: [Referência do glossário](/docs/reference/glossary).
- Os outros `L10N.md` campos: [Referência L10N.md](/docs/reference/l10n-md).
