%{
  title: "A localização ficou estagnada no passado. Criamos o Glossia para levar isso para frente.",
  summary: "Ferramentas tradicionais de localização adicionam sobrecarga, quebram a CI e prendem você nos ecossistemas de fornecedores. Estamos explorando o que um fluxo de trabalho de localização agêntico pode parecer.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Se você já lançou software em mais de um idioma, você conhece o processo. Escolhe uma plataforma de localização, a conecta ao seu repositório e passa o resto do tempo gerenciando a sincronização. O conteúdo sai, traduções voltam e, em algum meio disso, as coisas quebram.

Essa sobrecarga, o movimento constante de conteúdo para e do seu repositório, é o custo que cada equipe paga ao usar as ferramentas de localização de hoje. Parece insignificante até você ser quem está debugando por que um pull request de tradução quebrou a build do site às 18h de sexta-feira.

## Um design herdado de antes da internet

A maioria das plataformas de localização foi projetada em torno de conceitos que antecedem o fluxo de desenvolvimento moderno. Memórias de tradução. Correspondência fuzzy. Tradutores humanos trabalhando dentro de editores proprietários, apoiados por ferramentas que sugerem cadeias de texto semelhantes de um banco de dados.

Essas ideias faziam sentido quando a tradução era um processo manual e offline. Mas as empresas transformaram memórias de tradução em um mecanismo de\_lock-in\_. Suas traduções passadas, o conhecimento institucional que você pagou, vivem dentro da plataforma deles. Mudar para outro provedor significa começar do zero, ou pagar por uma exportação que nunca funciona bem.

O resultado é uma indústria construída sobre atrito artificial. Seu conteúdo sai do seu repositório, entra numa caixa-preta e retorna no cronograma de outra pessoa.

## O ciclo de feedback quebrado

O problema é estrutural: ferramentas de localização externas não podem executar seu pipeline de CI. Elas não conhecem seus linters, seu passo de build, seu verificador de links ou seu esquema de frontmatter. Elas empurram o conteúdo traduzido de volta para o seu repositório e torcem para o melhor. Quando quebram, e quebram, alguém da equipe tem que parar o que está fazendo para corrigir problemas de formatação, sintaxe quebrada ou marcação inválida que a ferramenta de tradução introduziu.

LLMs e experiências com agentes estão apresentando novas oportunidades para repensar esses fluxos de trabalho totalmente. Um agente que gera uma tradução, executa suas verificações, vê o erro e executa novas tentativas até que a saída seja válida. Esse tipo de ciclo de feedback apertado muda tudo.

Mas só funciona se o conteúdo permanecer onde vive: no seu repositório. No momento em que você envia para uma plataforma externa, as traduções voltam no cronograma de outra pessoa e a integração quebra. O feedback que poderia ter sido instantâneo agora leva horas ou dias. O contexto que o tornou útil já se foi perdoe. Você perde o ciclo e, com ele, toda a vantagem que esses fluxos de trabalho de agentes deveriam te dar.

## Observações que moldaram a Glossia

Essas frustrações não se transformaram em Glossia por si sós. O projeto cresceu a partir de uma experiência profunda tanto em desenvolvimento quanto em localização, o que trouxe clareza para problemas difíceis de enxergar de apenas um lado. Compreender os fluxos de trabalho linguísticos, as dinâmicas humanas das equipes de tradução e as razões pelas quais as ferramentas existentes acabaram como acabaram foi essencial.

Juntos, continuávamos chegando às mesmas conclusões: as ferramentas de localização foram projetadas para um mundo sem LLMs, sem agentes de código e sem pipelines de CI. Todo o modelo assumia que a tradução era algo que acontecia fora do fluxo de desenvolvimento e era empurrada de volta para dentro. Isso fazia sentido há dez anos. Não faz mais.

Começamos a perguntar: **e se os agentes de localização pudessem trabalhar da mesma maneira que os agentes de código?**

Estivemos prestando muita atenção em como a [Anthropic](https://anthropic.com) concebe fluxos de trabalho de agentes com o Claude. O padrão de dar a um agente acesso a ferramentas, permitir que ele raciocine sobre uma tarefa, valide sua própria saída e itere quando algo sai do caminho mapeia maravilhosamente bem para a localização. Um agente de tradução capaz de ler seus arquivos de origem, compreender o contexto do projeto, gerar traduções, executar seus linters e corrigir problemas antes de abrir um pull request. Isso não é uma fantasia. É o fluxo de trabalho que estamos construindo.

## Glossia é nosso presente para a indústria de software

Construímos a Glossia porque queremos que mais software seja localizado, não menos.

Processos complexos e plataformas caras tornam a localização inacessível para equipes pequenas, desenvolvedores independentes e projetos pessoais. Se o seu fluxo de tradução exigir um processo de aquisição, uma negociação de preços por palavra e um gerente de projeto para coordenar entregas, a maioria das equipes apenas lançará em inglês e considerará o trabalho concluído.

Glossia usa modelos a que você já tem acesso. E valida a saída com suas próprias ferramentas, não com as nossas.

Acreditamos que a localização deve ser tão natural quanto executar sua suite de testes.

## Um agente primeiro, interfaces depois

No seu cerne, o Glossia é um agente. Estamos começando com o terminal como sua interface primária, pois é ali que os problemas mais difíceis são resolvidos primeiro: lendo seus arquivos de origem, gerando traduções, executando suas verificações e iterando até que a saída seja válida. Este é o mesmo padrão que a [OpenAI](https://openai.com) seguiu com o [Codex](https://openai.com/index/openai-codex/) e a [Anthropic](https://anthropic.com) com o [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Você constrói o agente, lhe dá um terminal e deixa que ele trabalhe.

Mas o terminal é apenas a primeira interface, não a única. Sabemos que nem todos que contribuem para a qualidade da localização são desenvolvedores. Discutimos isso frequentemente internamente. Quem mais se importa com a precisão da tradução, o tom e as nuances culturais são frequentemente linguistas e especialistas em conteúdo que não pensam em termos de ramos, compilação ou JSON.

É por isso que queremos construir novas interfaces sobre o mesmo agente. Algo onde um linguista vê o conteúdo, o contexto e a tradução lado a lado. Eles trazem o julgamento humano que nenhum modelo pode substituir. Eles refinam o que precisa de refinamento. E o agente lida com o resto: fazer o commit, validar e abrir a pull request.

Ainda não temos todas as respostas, e isso é intencional. Prefirimos construir isso com cuidado do que apressar uma interface que não acerta o objetivo. Mas a direção é clara: o Glossia deve acolher todos os que se importam em fazer com que o software fale todas as línguas.

## Continue acompanhando

O Glossia ainda está no início e estamos construindo de forma aberta. Se qualquer uma dessas coisas ressoa com como você pensa sobre a localização, continue acompanhando o projeto. Compartilharemos mais conforme avançarmos.