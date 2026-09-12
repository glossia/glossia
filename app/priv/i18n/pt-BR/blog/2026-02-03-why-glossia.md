%{
  title: "A localização estava presa no passado. Construímos o Glossia para avançá-la.",
  summary:
    "Ferramentas tradicionais de localization adicionam sobrecarga, quebram o CI e prendem você em ecossistemas de fornecedores. Estamos explorando o que um workflow de localização agêntico pode ser.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Se você já distribuiu software em mais de um idioma, conhece o processo. Você escolhe uma plataforma de localização, a conecta ao seu repositório e então passa o resto do tempo gerenciando a sincronização. O conteúdo sai, as traduções voltam e, em algum lugar no meio, as coisas quebram.

Essa sobrecarga, a ida e volta constante de conteúdo entre seu repositório, é a taxa que toda equipe paga ao usar as ferramentas de localização de hoje. Parece insignificante até você ser quem depura por que uma PR de tradução quebrou a compilação do seu site às 18h de sexta-feira.

## Um design herdado de antes da internet

A maioria das plataformas de localização foi projetada em torno de conceitos que antecedem o fluxo de trabalho moderno de desenvolvimento. Memórias de tradução. Correspondência fuzzy. Tradutores humanos trabalhando dentro de editores proprietários, apoiados por ferramentas que sugerem strings similares de um banco de dados.

Essas ideias faziam sentido quando a tradução era um processo manual e offline. Mas as empresas transformaram as memórias de tradução em um mecanismo de lock-in. Suas traduções passadas, o conhecimento institucional que você pagou, vivem dentro da plataforma deles. Mudar para outro provedor significa começar do zero, ou pagar por uma exportação que nunca funciona bem.

O resultado é uma indústria construída sobre fricção artificial. Seu conteúdo deixa seu repositório, entra em uma caixa preta e volta sob o cronograma de outra pessoa.

## O ciclo de feedback quebrado

O problema é estrutural: ferramentas de localização externas não podem executar sua pipeline de CI. Elas não têm conhecimento dos seus linters, da etapa de build, do verificador de links ou do esquema frontmatter. Elas empurram o conteúdo traduzido de volta para o seu repositório e esperam o melhor. Quando algo quebra, e quebra mesmo, alguém da equipe tem que parar o que está fazendo para corrigir problemas de formatação, sintaxe quebrada ou markup inválido que a ferramenta de tradução introduziu.

Os LLMs e as experiências agênticas estão nos apresentando novas oportunidades para repensar inteiramente esses fluxos de trabalho. Um agente que gera uma tradução, executa suas verificações, vê o erro e retenta até que o resultado seja válido. Esse tipo de ciclo de feedback apertado muda tudo.

Mas só funciona se o conteúdo permanecer onde está: no seu repositório. Assim que enviar para uma plataforma externa, as traduções voltam na linha do tempo de outra pessoa e a integração falha. O feedback que poderia ter sido instantâneo agora leva horas ou dias. O contexto que o tornou útil já desapareceu. Você perde o ciclo e, com isso, toda a vantagem que os fluxos agênticos deveriam lhe oferecer.

## Observações que moldaram a Glossia

Essas frustrações não deram origem ao Glossia sozinhas. O projeto se desenvolveu de uma experiência profunda tanto em desenvolvimento quanto em localização, o que trouxe clareza para problemas que são difíceis de ver apenas de um lado. Entender os fluxos linguísticos, a dinâmica humana das equipes de tradução e as razões pelas quais as ferramentas existentes acabaram como ficaram, era essencial.

Juntos, chegávamos sempre às mesmas observações: as ferramentas de localização foram projetadas para um mundo sem LLMs, sem agentes de código e sem pipelines de CI. Todo o modelo assumia que a tradução era algo que acontecia fora do fluxo de desenvolvimento e era reintegrado. Isso fazia sentido há dez anos. Não faz mais.

Começamos a perguntar: **e se os agentes de localização pudessem funcionar da mesma maneira que os agentes de código?**

Temos prestado muita atenção a como [Anthropic](https://anthropic.com) pensa sobre fluxos de trabalho autônomos com Claude. O padrão de dar a um agente acesso a ferramentas, permitindo que ele raciocine sobre uma tarefa, valide sua própria saída e itere quando algo não estiver certo alinha-se muito bem com a localização. Um agente de tradução que possa ler seus arquivos de origem, entender o contexto do projeto, gerar traduções, rodar seu linter e corrigir problemas antes de abrir um pull request. Isso não é uma fantasia. É o fluxo de trabalho que estamos construindo.

## Glossia é nosso presente para a indústria de software

Criamos a Glossia porque queremos que mais software seja localizado, e não menos.

Processos complicados e plataformas caras tornam a localização inacessível para pequenas equipes, desenvolvedores independentes e projetos paralelos. Se o fluxo de trabalho de tradução exigir um processo de aquisição, uma negociação de preço por palavra e um gerente de projeto para coordenar transferências, a maioria das equipes simplesmente lança o produto em inglês e considera o trabalho concluído.

A Glossia usa modelos aos quais você já tem acesso. E valida a saída com suas próprias ferramentas, não as nossas.

Acreditamos que a localização deve ser tão natural quanto executar sua suíte de testes.

## Primeiro o agente, depois as interfaces.

Em seu cerne, Glossia é um agente. Estamos começando com o terminal como a interface principal, porque é ali que os problemas mais complexos são resolvidos em primeiro lugar: ler seus arquivos-fonte, gerar traduções, executar verificações e iterar até que a saída seja válida. Este é o mesmo padrão que [OpenAI](https://openai.com) usou com [Codex](https://openai.com/index/openai-codex/) e [Anthropic](https://anthropic.com) com [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Você constrói o agente, dá a ele um terminal e deixa-o trabalhar.

Mas o terminal é apenas a primeira interface, não a única. Sabemos que nem todos os que contribuem para a qualidade da localização são desenvolvedores. Conversamos internamente com frequência sobre isso. As pessoas que mais se preocupam com a precisão da tradução, o tom e as nuances culturais são frequentemente linguistas e especialistas em conteúdo que não pensam em termos de branches, compilação ou JSON.

É por isso que queremos construir novas interfaces sobre o mesmo agente. Algo onde um linguista vê o conteúdo, o contexto e a tradução lado a lado. Eles trazem o julgamento humano que nenhum modelo pode substituir. Eles refinam o que precisa de refinamento. E o agente cuida de tudo o mais: fazer o commit, validar e abrir o pull request.

Ainda não temos todas as respostas, e isso é intencional. Preferimos construir isso com cuidado do que correr para uma interface que perca a ideia. Mas a direção é clara: a Glossia deve acolher todos os que se importam em fazer softwares falarem todas as línguas.

## Fique ligado

A Glossia ainda está em seus primeiros estágios, e estamos construindo-a de forma aberta. Se algo disso ressoar com como você pensa sobre localização, continue acompanhando o projeto. Compartilharemos mais conforme avançamos.