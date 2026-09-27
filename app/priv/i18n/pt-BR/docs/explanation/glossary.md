%{
  title: "Glossário",
  summary:
    "Como o Glossia mantém traduções aprovadas consistentes em todos os idiomas e em cada arquivo.",
  category: "explicação",
  section: "tradução",
  order: 5
}
---
Um glossário é um conjunto curado de termos que suas traduções devem renderizar da mesma forma toda vez. O termo "Comit" no sentido de controle de versão permanece `commit` em espanhol, torna-se `提交` em chinês simplificado, e `コミット` em japonês. Uma decisão por idioma, imposta globalmente.

## Dois locais onde um glossário pode residir

O Glossia busca em dois locais as entradas de glossário e as funde no momento da tradução:

- **Seu repositório**, nos arquivos que você já utiliza para configurações de tradução. `L10N.md` declara os termos, e de cada idioma `L10N/<locale>.md` declara as suas traduções. Este é o glossário de autoridade do desenvolvedor: as alterações via pull requests, os revisores de cada idioma possuem o próprio arquivo, e arquivos aninhados podem refiná-lo para parte do repositório.
- **O servidor**, armazenado junto à sua conta. Este é o glossário de autoridade do linguista: revisores e contribuidores de localização adicionam ou refinam entradas sem mexer no código, através do dashboard, o [REST API](/docs/reference/apis), ou o [servidor MCP](/docs/reference/mcp). Aplica-se a cada repositório que a conta traduz.

Ambos os locais são úteis, e nenhum substitui o outro.

## Quando usar cada um

Definir um termo em **o servidor** quando:

- **Isso se aplica a mais de um repositório.** Nomes de produtos, termos de marca e vocabulário de empresa são definidos uma vez e usados em todos os lugares.
- **As pessoas que decidem isso não trabalham no repositório.** Linguistas, revisores e contribuidores externos podem refinar o glossário mesmo que o repositório seja de código fechado ou que não tenham permissão de escrita nele.
- **Você deseja corrigir um termo sem alterar o código.** Uma tradução corrigida aplica-se na próxima execução, sem solicitar um pull request na base de código.
- **As alterações exigem revisão e histórico.** Cada edição cria uma nova versão com uma nota de alteração; os contribuidores podem propor alterações como sugestões para que alguém as aprove, e versões anteriores permanecem disponíveis.
- **Outras ferramentas precisam disso.** Agentes e integrações podem ler o glossário por meio da REST API e do servidor MCP, por exemplo, para criar novo conteúdo que já utiliza os termos aprovados.

Defina um termo em **seu repositório** quando:

- **Ele pertence a esta base de código.** Um termo cujo significado é específico de um projeto, como "commit" referindo-se à ação de controle de versão, fica ao lado do código que o utiliza.
- **Ele deve mudar junto com o texto de origem.** O termo e o texto que o introduziu chegam ao mesmo pull request e são revisados juntos.
- **Apenas parte do repositório precisa dele.** Um aninhado `L10N.md` ou `L10N/<locale>.md` pode adicionar ou sobrescrever entradas para um diretório, como páginas de marketing.
- **Ela deve sobrescrever o servidor.** Uma entrada do repositório tem precedência sobre uma entrada do servidor para o mesmo termo, nos idiomas que ela traduz.

## Como elas se combinam

Para cada arquivo e idioma de destino, o Glossia resolve os dois glossários em um conjunto efetivo:

1. Comece com as entradas do glossário do servidor para o idioma de destino.
2. Sobreponha as entradas do repositório para esse idioma: os termos do arquivo `L10N.md` cadeia que tem uma tradução em sua `L10N/<locale>.md` cadeia. Quando uma entrada de repositório tem o mesmo termo de origem de uma entrada de servidor, a entrada de repositório vence.
3. Se um termo de repositório não tem tradução para um idioma, a entrada de servidor para aquele idioma ainda se aplica. O repositório nunca bloqueia um idioma que não traduziu.

A fusão acontece **por idioma-alvo**, não por entrada. Uma tradução de "commit" em `L10N/es.md` substitui a entrada de servidor em espanhol para "commit", mas não toca na entrada de servidor em japonês para o mesmo termo. Os revisores podem ver quais entradas de servidor foram substituídas: o resumo da sessão de tradução mostra quantas foram sobrescritas, e o arquivo de bloqueio de cada arquivo as lista sob `glossary.shadowed`.

## Quando o glossário muda, os arquivos são retraduzidos

Quando você edita uma entrada de glossário, o Glossia retraduz apenas os arquivos cujos *glossários tenham mudado efetivamente*. Se o texto fonte de um arquivo não contiver nenhum correspondente ao termo editado, suas traduções permanecem inalteradas. Se um arquivo usa o termo, sua próxima fase de tradução inclui a instrução atualizada.

O mesmo princípio se aplica na inversa: adicionar um termo utilizado apenas por um subconjunto de arquivos não força uma nova execução completa.

## O que um glossário não é

- Não é um dicionário de tradução automática. O modelo do Glossia lê o contexto circundante e pode apresentar um termo de forma diferente se a frase exigir. O glossário é uma orientação, não uma substituição.
- Não é todo o guia de estilo. Voz, tom, formalidade e público estão na configuração de Voz da sua conta e em `L10N.md`. O glossário é apenas para termos individuais e suas traduções aprovadas.
- Não silencioso. Cada termo aplicado é registrado no lockfile do arquivo, para que um revisor possa rastrear exatamente quais entradas do glossário foram incluídas no modelo.

## Relacionado

- Adicione seus primeiros termos: [Defina um glossário](/docs/how-to/define-a-glossary).
- Cada campo de entrada: [Referência do glossário](/docs/reference/glossary).
- Outros `L10N.md` campos: [Referência L10N.md](/docs/reference/l10n-md).