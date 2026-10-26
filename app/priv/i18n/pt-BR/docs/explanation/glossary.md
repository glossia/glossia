%{
  title: "Glossário",
  summary:
    "Como o Glossia mantém as traduções aprovadas consistentes em todos os idiomas e arquivos.",
  category: "Explicação",
  section: "translation",
  order: 5
}
---

Um glossário é um conjunto curado de termos que suas traduções devem renderizar da mesma maneira a cada vez. "Commit" no sentido de controle de versão permanece `commit` em espanhol, torna-se `提交` no chinês simplificado e `コミット` no japonês. Uma decisão por idioma, imposta em todo lugar.

## Dois lugares onde um glossário pode residir

O Glossia procura entradas de glossário em dois lugares e as funde no momento da tradução:

- **Seu repositório**, nos arquivos que você já usa para configurações de tradução. `L10N.md` declara os termos, e o `L10N/<locale>.md` de cada idioma declara suas traduções. Este é o glossário de autoridade do desenvolvedor: as alterações percorrem pull requests, revisores de cada idioma têm seus próprios arquivos, e arquivos aninhados podem refiná-lo para uma parte do repositório.
- **Sua conta do Glossia**, gerenciada através do painel hospedado. Este é o glossário de autoridade dos linguistas: revisores e colaboradores de localização adicionam ou refinam entradas sem tocar no código, através do painel, da [REST API](/docs/reference/apis) ou do [servidor MCP](/docs/reference/mcp). Ele se aplica a todos os repositórios que a conta traduz.

Ambos os lugares são úteis, e nenhum substitui o outro.

## Quando usar cada um

Defina um termo em **sua conta do Glossia** quando:

- **Ele se aplica a mais de um repositório.** Nomes de produtos, termos da marca e vocabulário corporativo são definidos uma vez e usados em todos os lugares.
- **Quem o decide não trabalha no repositório.** Linguistas, revisores e colaboradores externos podem refinar o glossário mesmo que o repositório seja de código fechado ou que não tenham acesso de escrita a ele.
- **Você deseja corrigir um termo sem alteração de código.** Uma tradução corrigida aplica-se na próxima execução, sem pull request contra o repositório de código.
- **As alterações precisam de revisão e histórico.** Toda edição cria uma nova versão com uma nota de alteração, contribuidores podem propor alterações como sugestões para uma pessoa aprovar, e versões anteriores permanecem disponíveis.
- **Outras ferramentas precisam disso.** Agentes e integrações podem ler o glossário através da REST API e do servidor MCP, por exemplo, para escrever conteúdo novo que já usa os termos aprovados.

Defina um termo em **seu repositório** quando:

- **Ele pertence a essa base de código.** Um termo cujo significado é específico de um projeto, como "commit" significando a ação de controle de versão, fica ao lado do código que o usa.
- **Ela deve mudar junto com o texto fonte.** O termo e o texto que o introduziu são enviados no mesmo pull request e revisados juntos.
- **Apenas parte do repositório precisa dele.** Um `L10N.md` ou `L10N/<locale>.md` aninhado pode adicionar ou sobrescrever entradas para uma diretório, como páginas de marketing.
- **Ela deve sobrescrever o glossário da conta.** Uma entrada do repositório vence uma entrada da conta para o mesmo termo, para os idiomas que traduz.

## Como eles se combinam

Para cada arquivo e idioma de destino, o Glossia resolve os dois glossários em um conjunto eficaz:

1. Comece com as entradas do glossário da conta para o idioma de destino.
2. Sobreponha as entradas do repositório para esse idioma: os termos da cadeia de `L10N.md` do arquivo que tem tradução em sua cadeia `L10N/<locale>.md`. Quando uma entrada do repositório tem o mesmo termo de origem que uma entrada da conta, a entrada do repositório vence.
3. Se um termo do repositório não tiver tradução para um idioma, a entrada da conta para esse idioma ainda se aplica. O repositório nunca bloqueia um idioma que não traduz.

A mesclagem ocorre **por idioma de destino**, não por entrada. Uma tradução espanhola de "commit" em `L10N/es.md` substitui a entrada espanhola da conta para "commit", mas não toca na entrada japonesa da conta para o mesmo termo. Revisores podem ver quais entradas da conta foram substituídas: o resumo da sessão de tradução mostra quantas foram sobrescritas, e o lockfile de cada arquivo lista-as em `glossary.shadowed`.

## Quando o glossário muda, os arquivos re-traduzem

Quando você edita uma entrada de glossário, o Glossia re-traduz apenas os arquivos cujo *glossário efetivo mudou*. Se o texto fonte de um arquivo não tiver correspondências para o termo editado, suas traduções permanecem intocadas. Se um arquivo usa o termo, sua próxima passagem de tradução inclui a instrução atualizada.

O mesmo princípio se aplica ao inverso: adicionar um termo usado apenas por um subconjunto de arquivos não força uma execução completa.

## O que um glossário não é

- Não é um dicionário de tradução automática. O modelo do Glossia lê o contexto e pode renderizar um termo de forma diferente se a frase exigir. O glossário é orientação, não substituição.
- Não é todo o guia de estilo. Voz, tom, formalidade e público estão na configuração de Voz de sua conta e no `L10N.md`.
- Não é silencioso. Todo termo aplicado é registrado no lockfile do arquivo para que um revisor possa rastrear exatamente quais entradas de glossário alcançaram o modelo.

## Relacionado

- Adicione seus primeiros termos: [Defina um glossário](/docs/how-to/define-a-glossary).
- Cada campo de entrada: [Referência de glossário](/docs/reference/glossary).
- Os outros campos `L10N.md`: [Referência L10N.md](/docs/reference/l10n-md).
