%{
  title: "A localização ficou presa no passado. Criamos o Glossia para impulsioná-la adiante.",
  summary:
    "Ferramentas tradicionais de localização adicionam sobrecarga, quebram o CI e prendem você em ecossistemas de fornecedores. Estamos explorando o que um fluxo de trabalho de localização agêntico pode representar.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Se você já lançou software em mais de uma língua, já conhece o processo. Você escolhe uma plataforma de localização, a conecta ao seu repositório e depois passa o resto do seu tempo gerenciando a sincronização. O conteúdo sai, as traduções voltam e, em algum ponto, as coisas quebram.

Esse custo extra, a ida e volta constante do conteúdo de e para o seu repositório, é o imposto que cada equipe paga por usar as ferramentas de localização atuais. Parece insignificante até você ser quem está debugando por que uma PR de tradução quebrou sua build do site às 18h de sexta-feira.

## Um design herdado da era pré-internet

A maioria das plataformas de localização foi projetada em torno de conceitos que antecedem o fluxo de desenvolvimento moderno. Memórias de tradução. Correspondência imprecisa. Tradutores humanos trabalhando dentro de editores proprietários, apoiados por ferramentas que sugerem strings similares a partir de um banco de dados.

Essas ideias faziam sentido quando a tradução era um processo manual, offline. Mas as empresas transformaram as memórias de tradução em um mecanismo de bloqueio. Suas traduções passadas, o conhecimento institucional que você pagou, vivem dentro de sua plataforma. Migrar para outro provedor significa começar do zero, ou pagar por uma exportação que nunca funciona direito.

O resultado é uma indústria construída sobre atrito artificial. Seu conteúdo sai do seu repositório, entra em uma caixa preta e retorna conforme a agenda de outra pessoa.

## O ciclo de feedback quebrado

O problema é estrutural: ferramentas de localização externas não conseguem executar seu pipeline de CI. Elas não conhecem os seus linters, sua etapa de build, seu verificador de links ou seu esquema de frontmatter. Elas devolvem o conteúdo traduzido de volta para o seu repositório e torcem para o melhor. Quando quebra, e quebra, alguém da equipe tem que parar o que está fazendo para corrigir problemas de formatação, sintaxe quebrada ou markup inválido que a ferramenta de tradução introduziu.

LLMs e experiências agênticas estão nos apresentando novas oportunidades para repensar inteiramente esses fluxos de trabalho. Um agente que gera uma tradução, executa suas verificações, identifica o erro e reexecuta até que a saída seja válida. Esse tipo de ciclo de feedback curto muda tudo.

Mas funciona apenas se o conteúdo permanecer onde reside: no seu repositório. No momento em que você envia para uma plataforma externa, as traduções retornam seguindo o cronograma de outra pessoa e a integração é quebrada. O feedback que poderia ter sido instantâneo agora leva horas ou dias. O contexto que o tornava útil já desapareceu. Você perde o ciclo e, com ele, toda a vantagem que os fluxos de trabalho agênticos deveriam oferecer.

## Observações que moldaram o Glossia

Essas frustrações não se transformaram em Glossia por si mesmas. O projeto cresceu a partir de uma vasta experiência tanto em desenvolvimento quanto em localização, o que trouxe clareza para problemas difíceis de serem vistos apenas de um lado. Entender os fluxos linguísticos, a dinâmica humana das equipes de tradução e as razões pelas quais as ferramentas existentes acabaram daquela forma era essencial.

Juntos, seguimos chegando às mesmas observações: ferramentas de localização foram projetadas para um mundo sem LLMs, sem agentes de codificação e sem CI pipelines. O modelo inteiro assumiu que a tradução era algo que acontecia fora do fluxo de desenvolvimento e era enviado de volta depois. Isso fazia sentido há dez anos. Não é mais.

Começamos a perguntar: **e se os agentes de localização pudessem funcionar da mesma maneira que os agentes de codificação?**

Estamos prestando muita atenção a como [Anthropic](https://anthropic.com) pensa em fluxos de trabalho agênticos com Claude. O padrão de dar a um agente acesso a ferramentas, permitindo que ele raciocine em uma tarefa, valide sua própria saída e itere quando algo estiver errado, se molda muito bem à localização. Um agente de tradução que pode ler seus arquivos de origem, entender o contexto do projeto, gerar traduções, rodar seu linter e corrigir problemas antes de abrir um pull request. Isso não é uma fantasia. É o fluxo de trabalho que estamos construindo.

## Glossia é nosso presente para a indústria de software

Construímos a Glossia porque queremos que mais software seja localizado, não menos.

Processos complicados e plataformas dispendiosas tornam a localização inacessível para pequenas equipes, desenvolvedores independentes e projetos paralelos. Se o seu fluxo de trabalho de tradução exigir um processo de compras, uma negociação de preço por palavra e um gerente de projeto para coordenar as entregas, a maioria das equipes simplesmente lançará em inglês e considerará o dia encerrado.

O Glossia usa modelos aos quais você já tem acesso. E ele valida a saída com as suas próprias ferramentas, não com as nossas.

Acreditamos que a localização deve ser tão natural quanto executar sua suíte de testes.

## Um agente primeiro, interfaces depois

No seu núcleo, o Glossia é um agente. Estamos começando com o terminal como sua interface primária porque é lá que os problemas mais difíceis são resolvidos primeiro: lendo seus arquivos fonte, gerando traduções, executando suas verificações e iterando até que a saída seja válida. Este é o mesmo padrão que [OpenAI](https://openai.com) seguido com [Codex](https://openai.com/index/openai-codex/) e [Anthropic](https://anthropic.com) com [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Você constrói o agente, dá a ele um terminal e permite que ele trabalhe.

Mas o terminal é apenas a primeira interface, não a única. Sabemos que nem todos que contribuem para a qualidade da localização são desenvolvedores. Conversamos sobre isso frequentemente internamente. As pessoas que mais se preocupam com a precisão das traduções, o tom e as nuances culturais são frequentemente linguistas e especialistas em conteúdo que não pensam em termos de ramificações, compilação ou JSON.

É por isso que queremos construir novas interfaces sobre o mesmo agente. Algo onde um linguista vê o conteúdo, o contexto e a tradução lado a lado. Eles trazem o julgamento humano que nenhum modelo pode substituir. Eles refinam o que precisa ser refinado. E o agente cuida de tudo o resto: o commit, a validação e a abertura do pull request.

Ainda não temos todas as respostas, e isso é intencional. Preferimos construir isso com cuidado do que correr para uma interface que perca o objetivo. Mas a direção está clara: a Glossia deve acolher todos os que se preocupam em fazer o software falar todas as línguas.

## Fique atento

O Glossia ainda está em seus estágios iniciais, e estamos construindo-o de forma aberta. Se isso ressoar com a forma como você pensa sobre localização, continue acompanhando o projeto. Compartilharemos mais à medida que avançamos.