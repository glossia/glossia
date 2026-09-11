%{
  title: "A localização estava estagnada no passado. Criamos o Glossia para avançá-la.",
  summary:
    "Ferramentas tradicionais de localização adicionam sobrecarga, quebram o CI e prendem você em ecossistemas de fornecedores. Estamos explorando o que um fluxo de trabalho de localização baseado em agentes pode ser.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Se você já lançou software em mais de um idioma, sabe a rotina. Você escolhe uma plataforma de localização, conecta-a ao seu repositório e passa o resto do tempo gerenciando a sincronização. O conteúdo sai, as traduções voltam e, em algum momento no meio disso, as coisas quebram.

Essa sobrecarga, a ida e volta constante do conteúdo de e para o seu repositório, é o custo que cada equipe paga por usar as ferramentas de localização de hoje. Parece menor até você ser quem depura por que um PR de tradução quebrou a build do seu site às 18h de uma sexta-feira.

## Um design herdado de antes da internet

A maioria das plataformas de localização foi desenhada em torno de conceitos que precedem o fluxo de desenvolvimento moderno. Memórias de tradução. Correspondência Fuzzy. Tradutores humanos trabalhando dentro de editores proprietários, apoiados por ferramentas que sugerem strings semelhantes de um banco de dados.

Essas ideias faziam sentido quando a tradução era um processo manual e offline. Mas as empresas transformaram as memórias de tradução em um mecanismo de lock-in. Suas traduções passadas, o conhecimento institucional que você pagou, vivem na plataforma deles. Mover-se para outro provedor significa começar do zero ou pagar por uma exportação que nunca funciona perfeitamente.

O resultado é uma indústria construída sobre atrito artificial. Seu conteúdo deixa o repositório, entra em uma caixa preta e retorna no agendamento de outra pessoa.

## O ciclo de feedback quebrado

O problema é estrutural: ferramentas de localização externas não podem rodar seu pipeline de CI. Elas não sabem dos seus linters, da etapa de build, do verificador de links ou do esquema de frontmatter. Elas empurram conteúdo traduzido de volta para o repositório e torcem para o melhor. Quando quebra, e quebra, alguém na equipe tem que parar o que está fazendo para corrigir problemas de formatação, sintaxe quebrada ou marcação inválida que a ferramenta de tradução introduziu.

LLMs e experiências com agentes estão nos apresentando novas oportunidades para repensar esses fluxos de trabalho por completo. Um agente que gera uma tradução, executa suas verificações, vê o erro e retenta até que a saída seja válida. Esse ciclo de feedback tão estreito muda tudo.

Mas só funciona se o conteúdo permanecer onde reside: em seu repositório. No momento em que você o envia para uma plataforma externa, as traduções retornam na timeline de outra pessoa e a integração falha. O feedback que poderia ter sido instantâneo agora leva horas ou dias. O contexto que o tornava útil já desapareceu. Você perde o ciclo e, com isso, toda a vantagem que os fluxos de trabalho com agentes deviam oferecer.

## Observações que moldaram o Glossia

Essas frustrações não se transformaram sozinhas em Glossia. O projeto cresceu a partir de uma experiência profunda tanto em desenvolvimento quanto em localização, o que trouxe clareza para problemas difíceis de enxergar apenas de um lado. Compreender os fluxos de trabalho linguísticos, as dinâmicas humanas das equipes de tradução e as razões pelas quais as ferramentas existentes acabaram desse jeito era essencial.

Juntos, continuávamos chegando às mesmas conclusões: as ferramentas de localização foram projetadas para um mundo sem LLMs, sem agentes de codificação e sem pipelines de CI. O modelo inteiro pressupunha que a tradução era algo que ocorria fora do fluxo de desenvolvimento e era trazido de volta. Isso fazia sentido há dez anos. Não faz mais.

Começamos a nos perguntar: **E se os agentes de localização pudessem funcionar da mesma maneira que os agentes de codificação?**

Estamos prestando muita atenção a como [Anthropic](https://anthropic.com) reflete sobre fluxos de trabalho agênticos com Claude. O padrão de dar a um agente acesso a ferramentas, permitindo que ele raciocine sobre uma tarefa, valide sua própria saída e itere quando algo estiver incorreto, se encaixa muito bem na localização. Um agente de tradução capaz de ler seus arquivos de origem, entender o contexto do projeto, gerar traduções, executar o linter e corrigir problemas antes de abrir um pull request. Isso não é uma fantasia. É o fluxo de trabalho que estamos construindo.

## A Glossia é nosso presente para a indústria de software

Construímos a Glossia porque queremos que mais software seja localizado, não menos.

Processos complicados e plataformas caras tornam a localização inacessível para pequenas equipes, desenvolvedores independentes e projetos pessoais. Se o seu fluxo de trabalho de tradução exigir um processo de aquisição, uma negociação de preços por palavra e um gerente de projeto para coordenar as transferências, a maioria das equipes simplesmente lançará em inglês e considerará o expediente encerrado.

O Glossia usa modelos aos quais você já tem acesso. E ele valida a saída com suas próprias ferramentas, não com as nossas.

Acreditamos que a localização deve ser tão natural quanto executar sua suíte de testes.

## Um agente primeiro, interfaces segundo.

No seu cerne, o Glossia é um agente. Estamos começando com o terminal como sua interface primária, pois é lá que os problemas mais difíceis são resolvidos em primeiro lugar: lendo seus arquivos-fonte, gerando traduções, executando suas verificações e iterando até que a saída seja válida. Este é o mesmo padrão que [OpenAI](https://openai.com) seguido com [Codex](https://openai.com/index/openai-codex/) e [Anthropic](https://anthropic.com) com [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Você constrói o agente, dá a ele um terminal e permite que ele trabalhe.

Mas o terminal é apenas a primeira interface, não a única. Sabemos que nem todos que contribuem para a qualidade da localização são desenvolvedores. Discutimos isso frequentemente internamente. As pessoas que mais se preocupam com precisão de tradução, tom e nuances culturais são, muitas vezes, linguistas e especialistas em conteúdo que não pensam em termos de ramificações, compilação ou JSON.

É por isso que queremos construir novas interfaces sobre o mesmo agente. Algo onde um linguista vê o conteúdo, o contexto e a tradução lado a lado. Eles trazem o julgamento humano que nenhum modelo pode substituir. Eles refinam o que precisa de refinamento. E o agente lida com tudo o resto: fazer commits, validar e abrir o pull request.

Ainda não temos todas as respostas e isso é intencional. Prefirimos construir isso com cuidado em vez de correr para uma interface que perca o sentido. Mas a direção está clara: Glossia deve acolher todos que se importam em fazer software falar todas as línguas.

## Fique atento

O Glossia ainda está nos seus primeiros passos, e o estamos desenvolvendo em aberto. Se algo disso ressoar com a sua forma de pensar sobre localização, fique de olho no projeto. Vamos compartilhar mais conforme avançamos.