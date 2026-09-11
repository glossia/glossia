%{
  title: "A localização ficou presa no passado. Construímos o Glossia para movê-la para frente.",
  summary:
    "Ferramentas tradicionais de localização adicionam sobrecarga, quebram o CI e vinculam você a ecossistemas de fornecedores. Estamos explorando o que um fluxo de trabalho de localização autônomo pode parecer.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Se você já lançou software em mais de um idioma, já entende a dinâmica. Você escolhe uma plataforma de localização, conecta-a ao seu repositório e passa o resto do tempo gerenciando a sincronização. O conteúdo sai, as traduções voltam e, em algum momento entre ambos, as coisas quebram.

Essa sobrecarga, a ida e volta constante de conteúdo do e para o seu repositório, é o tributo que cada equipe paga ao usar ferramentas de localização atuais. Soa insignificante até ser você quem depura por que um PR de tradução quebrou a build do seu site às 18h em sexta-feira.

## Um design herdado de antes da internet

A maioria das plataformas de localização foi projetada em torno de conceitos que antecedem o fluxo de trabalho moderno de desenvolvimento. Memórias de tradução. Correspondência parcial. Tradutores humanos trabalhando em editores proprietários, apoiados por ferramentas que sugerem strings semelhantes a partir de um banco de dados.

Essas ideias faziam sentido quando a tradução era um processo manual e offline. Mas as empresas transformaram as memórias de tradução em um mecanismo de lock-in. Suas traduções passadas, o conhecimento institucional pelo qual você pagou, vivem dentro da plataforma delas. Mudar para outro provedor significa começar do zero ou pagar por uma exportação que dificilmente funciona perfeitamente.

O resultado é uma indústria construída sobre atrito artificial. Seu conteúdo sai do seu repositório, entra em uma caixa preta e retorna conforme o cronograma de outra pessoa.

## O ciclo de feedback quebrado

O problema é estrutural: ferramentas de localização externas não conseguêm rodar seu pipeline de CI. Elas não têm conhecimento sobre seus linters, sua etapa de build, seu verificador de links ou seu esquema frontmatter. Elas devolvem conteúdo traduzido de volta para o seu repositório e torcem para o melhor. Quando quebra, e quebra, alguém da equipe precisa parar o que está fazendo para corrigir problemas de formatação, sintaxe quebrada ou markup inválido introduzido pela ferramenta de tradução.

LLMs e experiências agênticas estão nos apresentando novas oportunidades para repensar esses fluxos de trabalho por completo. Um agente que gera uma tradução, executa suas verificações, detecta o erro e retenta até que a saída seja válida. Esse tipo de ciclo de feedback apertado muda tudo.

Mas isso só funciona se o conteúdo permanecer onde ele vive: em seu repositório. No momento em que você envia para uma plataforma externa, as traduções retornam em um cronograma de outrem e a integração falha. O feedback que poderia ter sido instantâneo agora leva horas ou dias. O contexto que o tornava útil já se perdeu há muito tempo. Você perde o ciclo, e com ele, toda a vantagem que os fluxos de trabalho agênticos deveriam ter te proporcionado.

## Observações que moldaram o Glossia

Essas frustrações não se tornaram o Glossia por conta própria. O projeto cresceu a partir de uma experiência profunda tanto em desenvolvimento quanto em localização, o que trouxe clareza para problemas que são difíceis de ver de apenas um lado. Compreender os fluxos de trabalho linguísticos, a dinâmica humana das equipes de tradução e as razões pelas quais as ferramentas existentes acabaram daquela forma foi essencial.

Juntos, sempre chegávamos às mesmas observações: as ferramentas de localização foram projetadas para um mundo sem LLMs, sem agentes de codificação e sem pipelines CI. Todo o modelo assumia que a tradução era algo que ocorria fora do fluxo de desenvolvimento e era reintegrada posteriormente. Isso fazia sentido há dez anos. Já não faz mais.

Começamos a nos perguntar: **e se os agentes de localização pudessem trabalhar da mesma forma que os agentes de codificação fazem?**

Temos prestado muita atenção a como [Anthropic](https://anthropic.com) reflete sobre fluxos de trabalho agênticos com Claude. O padrão de dar acesso a ferramentas a um agente, permitindo que ele raciocine sobre uma tarefa, valide sua própria saída e itere quando algo não estiver certo, se traduz de forma notável para a localização. Um agente de tradução que pode ler seus arquivos de origem, entender o contexto do projeto, gerar traduções, executar seu linter e corrigir problemas antes de abrir uma pull request. Isso não é uma fantasia. Esse é o fluxo de trabalho que estamos construindo.

## Glossia é nosso presente para a indústria de software.

Criamos a Glossia porque queremos que mais software seja localizado, não menos.

Processos complicados e plataformas caras tornam a localização inacessível para pequenas equipes, desenvolvedores independentes e projetos pessoais. Se o seu fluxo de tradução exigir um processo de compras, uma negociação de preços por palavra e um gerente de projeto para coordenar as entregas, a maioria das equipes lançará em inglês e ponto final.

A Glossia usa modelos que você já tem acesso. E ela valida a saída com suas próprias ferramentas, não com as nossas.

Acreditamos que a localização deve ser tão natural quanto executar sua suíte de testes.

## Primeiro o agente, depois as interfaces

No seu núcleo, o Glossia é um agente. Estamos começando com o terminal como a interface principal porque é ali que os problemas mais difíceis são resolvidos primeiro: ler seus arquivos-fonte, gerar traduções, executar suas verificações e iterar até que a saída seja válida. Este é o mesmo padrão que [OpenAI](https://openai.com) seguido com [Codex](https://openai.com/index/openai-codex/) e [Anthropic](https://anthropic.com) com [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Você constrói o agente, dá a ele um terminal, e deixa-o trabalhar.

Mas o terminal é apenas a primeira interface, não a única. Sabemos que nem todo contribuidor para qualidade de localização é um desenvolvedor. Discutimos isso frequentemente internamente. As pessoas que mais se importam com a precisão da tradução, o tom e a nuance cultural são, muitas vezes, linguistas e especialistas em conteúdo que não pensam em termos de ramificações, compilação ou JSON.

Por isso, queremos criar novas interfaces sobre o mesmo agente. É algo onde um linguista vê o conteúdo, o contexto e a tradução lado a lado. Eles trazem o julgamento humano que nenhum modelo pode substituir. Eles refinam o que precisa ser refinado. E o agente cuida do restante: commits, validações e abertura do pull request.

Ainda não temos todas as respostas e isso é intencional. Preferimos construir isso com cuidado a correr para uma UI que perca o ponto. Mas a direção está clara: o Glossia deve acolher todos os que se importam em fazer o software falar todas as línguas.

## Fique ligado

A Glossia ainda está em uma fase inicial e estamos construindo-a de forma aberta. Se isso ressoar com a sua forma de pensar sobre localização, fique de olho no projeto. Compartilharemos mais à medida que avançamos.