%{
  title: "Glossário",
  summary:
    "Como o Glossia mantém traduções aprovadas consistentes em todos os idiomas e em cada arquivo.",
  category: "Explicação",
  section: "translation",
  order: 5
}
---

Um glossário é um conjunto curado de termos que suas traduções devem renderizar da mesma forma toda vez. "Commit" no sentido de controle de versão fica `commit` em espanhol, torna-se `提交` em chinês simplificado, e `コミット` em japonês. Uma decisão por idioma, aplicada em todos os lugares.

## Dois lugares onde um glossário pode existir

A Glossia busca em dois lugares as entradas de glossário e as mescla no momento da tradução:

- **Seu repositório**, nos arquivos que já usa para definições de tradução. `L10N.md` declara os termos, e cada arquivo de língua `L10N/<locale>.md` declara suas traduções. Este é o glossário definido pelo desenvolvedor: as modificações viajam através de pull requests, cada revisor de idioma tem seu próprio arquivo, e arquivos aninhados podem refiná-lo para parte do repositório.
- **Sua conta Glossia**, gerenciada através do painel hospedado. Este é o glossário definido pelos linguistas: revisores e contribuidores de localização adicionam ou refinam entradas sem tocar no código, através do painel, da [REST API](/docs/reference/apis) ou da [MCP server](/docs/reference/mcp). Aplica-se a todos os repositórios que a conta traduz.

Ambos os lugares são úteis, e nenhum substitui o outro.

## Quando usar cada um

Defina um termo em **seu Glossia account** quando:

- **Aplica-se a mais de um repositório.** Nomes de produtos, termos da marca e vocabulário de empresa são definidos uma vez e usados em todos os lugares.
- **As pessoas que decidem não trabalham no repositório.** Linguistas, revisores e contribuidores externos podem refinar o glossário mesmo quando o repositório é de código fechado ou eles não têm permissão de escrita nele.
- **Você quer corrigir um termo sem uma mudança de código.** Uma tradução corrigida aplica-se na próxima execução, sem pull request contra o código fonte.
- **Alterações precisam de revisão e histórico.** Cada edição cria uma nova versão com uma nota de alteração, contribuidores podem propor mudanças como sugestões para alguém aprovar, e versões anteriores permanecem disponíveis.
- **Outras ferramentas precisam disso.** Agentes e integrações podem ler o glossário através da REST API e do MCP server, por exemplo para escrever novo conteúdo que já usa os termos aprovados.

Defina um termo em **o seu repositório** quando:

- **P pertence a este código fonte.** Um termo cujo significado é específico de um projeto, como "commit" significando a ação de controle de versão, fica ao lado do código que o usa.
- **Deve variar junto com o texto fonte.** O termo e o conteúdo que o introduziu chegam na mesma pull request e são revisados juntos.
- **Apenas parte do repositório precisa disso.** Um arquivo aninhado `L10N.md` ou `L10N/<locale>.md` pode adicionar ou sobrescrever entradas para um diretório, como páginas de marketing.
- **Deve substituir o glossário da conta.** Uma entrada de repositório vence uma entrada da conta para o mesmo termo, para os idiomas que traduz.

## Como são combinados

Para cada arquivo e idioma-alvo, a Glossia resolve os dois glossários em um conjunto efetivo:

1. Comece com as entradas de glossário da conta para o idioma-alvo.
2. Sobreponha as entradas do repositório para aquele idioma: os termos da cadeia `L10N.md` do arquivo que têm tradução em sua cadeia `L10N/<locale>.md`. Quando uma entrada de repositório tem o mesmo termo fonte que uma entrada da conta, a entrada de repositório ganha.
3. Se um termo do repositório não tem tradução para um idioma, a entrada da conta para aquele idioma ainda se aplica. O repositório nunca bloqueia um idioma que não traduziu.

A mesclagem ocorre **por idioma-alvo**, não por entrada. Uma tradução espanhola de "commit" em `L10N/es.md` substitui a entrada espanhola da conta para "commit", mas não altera a entrada japonesa da conta para o mesmo termo. Revisores podem ver quais entradas da conta foram substituídas: o resumo da sessão de tradução mostra quantas foram sobrescritas, e o lockfile de cada arquivo lista-as sob `glossary.shadowed`.

## Quando o glossário muda, arquivos re-translate

Quando você edita uma entrada de glossário, a Glossia só re-traduz os arquivos cujos *glossário efetivo mudou*. Se o texto fonte do arquivo não contém correspondências para o termo editado, suas traduções permanecem intocadas. Se o arquivo usa o termo, sua próxima passada de tradução inclui a instrução atualizada.

O mesmo princípio se aplica ao contrário: adicionar um termo usado apenas por um subconjunto de arquivos não força uma execução completa.

## O que um glossário não é

- Não é um dicionário de tradução automática. O modelo da Glossia lê o contexto circundante e pode renderizar um termo de forma diferente se a frase exigir. O glossário é orientação, não substituição.
- Não é o guia completo de estilo. Voz, tom, formalidade e público vivem na configuração de Voz da sua conta e em `L10N.md`. O glossário é apenas para termos individuais e suas traduções aprovadas.
- Não é silencioso. Cada termo aplicado é registrado no lockfile do arquivo para que um revisor possa rastrear exatamente quais entradas de glossário alcançaram o modelo.

## Relacionados

- Adicione seus primeiros termos: [Defina um glossário](/docs/how-to/define-a-glossary).
- Cada campo de entrada: [Referência de glossário](/docs/reference/glossary).
- Os outros campos `L10N.md`: [Referência de L10N.md](/docs/reference/l10n-md).
