%{
  title: "Glossário",
  summary:
    "Como a Glossia mantém traduções aprovadas consistentes em todos os idiomas e arquivos.",
  category: "explicação",
  section: "translation",
  order: 5
}
---
Um glossário é um conjunto curado de termos que suas traduções devem renderizar da mesma forma a cada vez. O termo "Commit" no sentido de controle de versão permanece `commit` em espanhol, torna-se `提交` em chinês simplificado, e `コミット` em japonês. Uma decisão por idioma, aplicada em todos os lugares.

## Dois locais onde um glossário pode existir

A Glossia busca em dois locais por entradas de glossário e as combina no momento da tradução:

- **, Seu repositório**nos arquivos que você já usa para configurações de tradução. `L10N.md` declara os termos, e o de cada idioma `L10N/<locale>.md` declara suas traduções. Este é o glossário de autoridade do desenvolvedor: as mudanças transitam pelos pull requests, os revisores de cada idioma possuem seu próprio arquivo, e arquivos aninhados podem refiná-lo para parte do repositório.
- **Sua conta Glossia**, gerenciada pelo painel hospedado. Este é o glossário de autoridade do linguista: revisores e contribuidores de localização adicionam ou refinam entradas sem tocar no código, através do painel, o [""REST API""](/docs/reference/apis), ou o [""MCP server""](/docs/reference/mcp)Aplica-se a cada repositório traduzido pela conta.

Ambos os locais são úteis, e nenhum substitui o outro.

## Quando usar qual

Defina um termo em **sua conta do Glossia** quando:

- **Aplica-se a mais de um repositório.** Nomes de produtos, termos da marca e vocabulário corporativo são definidos uma vez e usados em todos os lugares.
- **As pessoas que decidem isso não trabalham no repositório.** Linguistas, revisores e contribuintes externos podem refinar o glossário mesmo que o repositório seja de código fechado ou não tenham acesso de escrita nele.
- **Você quer corrigir um termo sem alterar o código.** Uma tradução corrigida é aplicada na próxima execução, sem necessidade de pull request contra o código.
- **As alterações requerem revisão e histórico.** Cada edição cria uma nova versão com uma nota de alteração, os contribuintes podem propor mudanças como sugestões para aprovação e versões anteriores permanecem disponíveis.
- **Outras ferramentas precisam disso.** Agentes e integrações podem ler o glossário via REST API e servidor MCP, por exemplo para criar novo conteúdo que já usa os termos aprovados.

Defina um termo em **seu repositório** quando:

- **Ele pertence a esta base de código.** Um termo cujo significado é específico para um projeto, como "commit" significando a ação de controle de versão, fica próximo ao código que o utiliza.
- **Ele deve mudar junto com o texto fonte.** O termo e o texto que o introduziu chegam na mesma solicitação de pull e são revisados juntos.
- **Apenas parte do repositório precisa dele.** Um aninhado `L10N.md` ou `L10N/<locale>.md` pode adicionar ou sobrescrever entradas de um único diretório, como páginas de marketing.
- **Ele deve sobrescrever o glossário da conta.** Uma entrada do repositório tem precedência sobre uma entrada da conta para o mesmo termo, para os idiomas que traduz.

## Como eles se combinam

Para cada arquivo e idioma-alvo, o Glossia resolve os dois glossários em um conjunto efetivo:

1. Comece com as entradas do glossário da conta para o idioma-alvo.
2. Sobreponha as entradas do repositório para esse idioma: os termos do arquivo `L10N.md` cadeia que possui uma tradução em sua `L10N/<locale>.md` cadeia. Quando uma entrada de repositório possui o mesmo termo de origem do que uma entrada de conta, a entrada do repositório prevalece.
3. Se um termo do repositório não possui tradução para um idioma, a entrada de conta para esse idioma ainda se aplica. O repositório nunca bloqueia um idioma que não traduziu.

A mesclagem ocorre **por idioma de destino**, não por entrada. Uma tradução de "commit" em `L10N/es.md` substitui a entrada de "commit" da conta em Espanhol, mas não afeta a entrada da conta em Japonês para o mesmo termo. Os revisores podem ver quais entradas de conta foram substituídas: o resumo da sessão de tradução mostra quantas foram sobrescritas, e o lockfile de cada arquivo as lista em `glossary.shadowed`.

## Quando o glossário muda, os arquivos são retraduzidos

Quando você edita uma entrada do glosário, o Glossia retraduz apenas os arquivos cujos *glosário efetivo mudou*. Se o texto fonte do arquivo não contiver nenhuma correspondência para o termo editado, suas traduções permanecem intactas. Se o arquivo utiliza o termo, sua próxima passagem de tradução inclui a instrução atualizada.

O mesmo princípio se aplica na inversa: adicionar um termo utilizado apenas por um subconjunto de arquivos não força uma reexecução completa.

## O que um glosário não é

- Não é um dicionário de tradução automática. O modelo do Glossia analisa o contexto circundante e pode traduzir um termo de forma diferente se a frase exigir isso. O glosário é orientação, não substituição.
- Não é todo o guia de estilo. A Voz, o tom, a formalidade e o público estão na configuração de Voz da sua conta e no `L10N.md`. O glosário é apenas para termos individuais e suas traduções aprovadas.
- Não é silencioso. Todo termo aplicado é registrado no lockfile do arquivo para que um revisor possa rastrear exatamente quais entradas do glosário foram incluídas no modelo.

## Relacionado

- Adicione seus primeiros termos: [Defina um glosário](/docs/how-to/define-a-glossary).
- Cada campo de entrada: [Referência do glosário](/docs/reference/glossary).
- Outros `L10N.md` campos: [Referência L10N.md](/docs/reference/l10n-md).