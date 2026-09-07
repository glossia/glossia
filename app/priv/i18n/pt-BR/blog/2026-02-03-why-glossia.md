%{
  title: "A localização estava presa no passado. Construímos o Glossia para avançá-la.",
  summary:
    "Ferramentas tradicionais de localização geram sobrecarga, quebram o CI e prendem você a ecossistemas de fornecedores. Estamos explorando o que um fluxo de trabalho de localização autônomo pode ser.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Se você já lançou software em mais de um idioma, você já sabe como é o processo. Você escolhe uma plataforma de localização, conecta ao seu repositório e depois passa o resto do tempo gerenciando a sincronização. O conteúdo sai, as traduções voltam e, em algum ponto do meio, as coisas quebram.

Essa sobrecarga, o ciclo constante de ida e volta de conteúdo para e do seu repositório, é o custo que cada equipe paga ao usar as ferramentas de localização de hoje. Parece pequeno até você ser quem depura por que uma pull request de tradução quebrou a build do site às 18h numa sexta-feira.

## Um design herdado antes da internet

A maioria das plataformas de localização foi projetada em torno de conceitos que antecedem o fluxo de desenvolvimento moderno. Memórias de tradução. Correspondência fuzzy. Tradutores humanos trabalhando em editores proprietários, apoiados por ferramentas que sugerem strings semelhantes a partir de um banco de dados.

Essas ideias faziam sentido quando a tradução era um processo manual e offline. Mas as empresas transformaram as memórias de tradução em um mecanismo de lock-in. Suas traduções passadas, o conhecimento institucional que você pagou por, vivem dentro da plataforma deles. Mudar para outro provedor significa começar do zero, ou pagar por uma exportação que nunca funciona como deveria.

O resultado é uma indústria construída sobre atrito artificial. Seu conteúdo deixa o repositório, entra em uma caixa preta e retorna no cronograma de outra pessoa.

## O ciclo de feedback quebrado

O problema é estrutural: ferramentas de localização externas não podem executar seu pipeline de CI. Elas não sabem sobre seus linters, sua etapa de build, seu verificador de links ou seu esquema frontmatter. Elas empurram conteúdo traduzido de volta para o repositório e esperam o melhor. Quando quebra, e às vezes quebra, alguém da equipe tem que parar o que está fazendo para corrigir problemas de formatação, sintaxe quebrada ou markup inválido que a ferramenta de tradução introduziu.

LLMs e experiências com agentes estão nos apresentando novas oportunidades para repensar esses fluxos de trabalho por completo. Um agente que gera uma tradução, executa suas verificações, vê o erro e tenta novamente até que a saída seja válida. Esse tipo de ciclo de feedback apertado muda tudo.

Mas só funciona se o conteúdo ficar onde mora: em seu repositório. Assim que você envia para uma plataforma externa, as traduções voltam no cronograma de outra pessoa e a integração quebra. O feedback que poderia ter sido instantâneo agora leva horas ou dias. O contexto que o tornava útil já se foi. Você perde o ciclo e, com ele, toda a vantagem que os fluxos de trabalho com agentes deveriam ter dado.

## Observações que moldaram o Glossia

Essas frustrações não viraram o Glossia sozinhas. O projeto cresceu de uma experiência profunda tanto em desenvolvimento quanto em localização, o que trouxe clareza para problemas difíceis de ver apenas de um lado. Entender os fluxos linguísticos, a dinâmica humana das equipes de tradução e as razões pelas quais as ferramentas existentes acabaram como acabaram foi essencial.

Juntos, nós sempre chegamos às mesmas observações: as ferramentas de localização foram projetadas para um mundo sem LLMs, sem agentes de codificação e sem pipelines de CI. Todo o modelo assumia que a tradução era algo que acontecia fora do fluxo de desenvolvimento e era empurrada de volta. Isso fazia sentido há dez anos. Não faz mais.

Começamos a perguntar: **e se os agentes de localização pudessem trabalhar da mesma forma que os agentes de codificação?**

Temos prestado muita atenção em como a [Anthropic](https://anthropic.com) pensa sobre fluxos de trabalho com agentes com o Claude. O padrão de dar acesso a ferramentas a um agente, permitir que ele raciocine sobre uma tarefa, valide sua própria saída e itere quando algo está errado se encaixa notavelmente bem na localização. Um agente de tradução que pode ler seus arquivos de origem, entender o contexto do projeto, gerar traduções, executar o linter e corrigir problemas antes de abrir um pull request. Isso não é fantasia. É o fluxo de trabalho que estamos construindo.

## Glossia é nosso presente à indústria de software

Criamos o Glossia porque queremos que mais software seja localizado, não menos.

Processos complexos e plataformas caras tornam a localização inacessível para pequenas equipes, desenvolvedores independentes e projetos pessoais. Se o fluxo de trabalho da sua tradução exigir um processo de aquisição, uma negociação de preço por palavra e um gerente de projeto para coordenar as entregas, a maioria das equipes simplesmente lançará em inglês e dará por feito.

O Glossia usa modelos aos quais você já tem acesso. E ele valida a saída com suas próprias ferramentas, não com as nossas.

Acreditamos que a localização deve ser tão natural quanto executar sua suíte de testes.

## Um agente primeiro, interfaces segundo

No seu núcleo, o Glossia é um agente. Estamos começando com o terminal como interface primária porque é aí que os problemas mais difíceis são resolvidos primeiro: lendo seus arquivos-fonte, gerando traduções, executando suas verificações e iterando até que a saída seja válida. Este é o mesmo padrão que [OpenAI](https://openai.com) seguiu com [Codex](https://openai.com/index/openai-codex/) e [Anthropic](https://anthropic.com) com [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Você constrói o agente, dá-lhe um terminal e deixa-o trabalhar.

Mas o terminal é apenas a primeira interface, não a única. Sabemos que nem todos que contribuem para a qualidade da localização são desenvolvedores. Falamos sobre isso frequentemente internamente. As pessoas que mais se importam com precisão de tradução, tom e nuances culturais são frequentemente linguistas e especialistas em conteúdo que não pensam em termos de ramificações, compilação ou JSON.

É por isso que queremos construir novas interfaces sobre o mesmo agente. Algo onde um linguista veja o conteúdo, o contexto e a tradução lado a lado. Eles trazem o julgamento humano que nenhum modelo pode substituir. Eles refinam o que precisa ser refinado. E o agente cuida de tudo o resto: realizar o commit, validar, abrir o pull request.

Ainda não temos todas as respostas, e isso é intencional. Preferimos construir isso com cuidado do que correr para uma interface que perde o ponto. Mas a direção é clara: o Glossia deve acolher todos que se importam em fazer o software falar todas as línguas.

## Fique atento

O Glossia ainda está no início, e estamos construindo-o de forma aberta. Se qualquer parte disso ressoa com como você pensa sobre localização, fique de olho no projeto. Compartilharemos mais conforme avançamos.