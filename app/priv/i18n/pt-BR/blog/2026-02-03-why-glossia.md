%{
  title: "A localização ficou estagnada no passado. Criamos o Glossia para levá-la adiante.",
  summary:
    "Ferramentas tradicionais de localização adicionam sobrecarga, quebram o CI e prendem você a ecossistemas de fornecedores. Estamos explorando o que um fluxo de trabalho de localização autônoma pode ser.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Se você já lançou software em mais de um idioma, já conhece o processo. Você escolhe uma plataforma de localização, conecta-a ao seu repositório e, em seguida, passa o resto do tempo gerenciando a sincronização. O conteúdo sai, as traduções voltam e, em algum ponto intermediário, as coisas quebram.

Essa sobrecarga, a constante ida e volta do conteúdo a partir de e para o seu repositório, é o custo que cada equipe paga por usar as ferramentas de localização de hoje. Parece menor até você ser quem depura por que um Pull Request de tradução quebrou a build do seu site às 18h de sexta-feira.

## Um design herdado de antes da internet

A maioria das plataformas de localização foi desenhada em torno de conceitos que antecederam o fluxo de trabalho moderno de desenvolvimento. Memórias de tradução. Correspondência parcial. Tradutores humanos trabalhando dentro de editores proprietários, suportados por ferramentas que sugerem strings semelhantes a partir de um banco de dados.

Essas ideias faziam sentido quando a tradução era um processo manual, offline. Mas as empresas transformaram memórias de tradução em um mecanismo de lock-in. Suas traduções passadas, o conhecimento institucional que você pagou, vivem dentro de sua plataforma. Migrar para outro provedor significa começar do zero, ou pagar por uma exportação que nunca funciona bem.

O resultado é uma indústria construída sobre atrito artificial. Seu conteúdo sai do seu repositório, entra numa caixa preta e retorna segundo o cronograma de outra pessoa.

## O ciclo de feedback quebrado

O problema é estrutural: ferramentas externas de localização não podem executar seu pipeline de CI. Elas não são conscientes sobre seus linters, seu passo de build, seu verificador de links ou seu esquema de frontmatter. Elas empurram conteúdo traduzido de volta para o seu repositório e esperam o melhor. Quando quebra, e quebra, alguém da equipe tem que parar o que está fazendo para corrigir problemas de formatação, sintaxe quebrada ou marcação inválida que a ferramenta de tradução introduziu.

LLMs e experiências agênticas estão nos apresentando novas oportunidades para repensar integralmente esses fluxos de trabalho. Um agente que gera uma tradução, executa suas verificações, vê o erro e retenta até que a saída seja válida. Esse tipo de ciclo de feedback apertado muda tudo.

Mas isso só funciona se o conteúdo permanecer onde ele reside: no seu repositório. Assim que você o envia para uma plataforma externa, as traduções voltam em um cronograma de outra pessoa e a integra falha. O feedback que poderia ter sido instantâneo agora leva horas ou dias. O contexto que o tornava útil já desapareceu. Você perde o ciclo e, com ele, toda a vantagem que os fluxos de trabalho agênticos deveriam lhe dar.

## Observações que moldaram o Glossia

Essas frustrações não se tornaram o Glossia sozinhas. O projeto nasceu de uma experiência profunda tanto em desenvolvimento quanto em localização, a qual trouxe clareza para problemas difíceis de ver apenas de um lado. Compreender os fluxos linguísticos, as dinâmicas humanas das equipes de tradução e os motivos pelos quais as ferramentas existentes acabaram daquela forma foi essencial.

Juntos, chegávamos constantemente às mesmas observações: as ferramentas de localização foram desenhadas para um mundo sem LLMs, sem agentes de codificação e sem pipelines de CI. O modelo inteiro assumia que a tradução era algo que ocorria fora do fluxo de desenvolvimento e apenas voltava depois. Isso fazia sentido há dez anos. Não mais.

Começamos a perguntar: **e se os agentes de localização pudessem funcionar da mesma forma que os agentes de codificação?**

Temos estado prestando muita atenção à maneira como [Anthropic](https://anthropic.com) pensa sobre fluxos de trabalho agênticos com o Claude. O padrão de dar a um agente acesso a ferramentas, permitindo que ele raciocine em uma tarefa, valide sua própria saída e itere quando algo estiver errado, se encaixa notavelmente bem com a localização. Um agente de tradução capaz de ler seus arquivos de origem, entender o contexto do projeto, gerar traduções, rodar seu linter e corrigir problemas antes de abrir um pull request. Isso não é uma fantasia. Esse é o fluxo de trabalho que estamos construindo.

## Glossia é nosso presente para a indústria de software

Criamos a Glossia porque queremos que mais software seja localizado, e não menos.

Processos complicados e plataformas caras tornam a localização inacessível para pequenas equipes, desenvolvedores independentes e projetos paralelos. Se o seu fluxo de tradução exigir um processo de compras, uma negociação de preço por palavra e um gerente de projeto para coordenar as entregas, a maioria das equipes simplesmente lançará em inglês e dará por encerrado.

O Glossia usa modelos aos quais você já tem acesso. E ele valida a saída com suas próprias ferramentas, não com as nossas.

Acreditamos que a localização deve ser tão natural quanto executar sua suíte de testes.

## Primeiro agente, depois interfaces

No cerne, o Glossia é um agente. Começamos com o terminal como sua interface principal, pois é ali que os problemas mais difíceis são resolvidos primeiro: ler seus arquivos fonte, gerar traduções, rodar suas verificações e iterar até que a saída seja válida. Este é o mesmo padrão que [OpenAI](https://openai.com) seguiram com [Codex](https://openai.com/index/openai-codex/) e [Anthropic](https://anthropic.com) com [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Você constrói o agente, dá a ele um terminal e deixa que ele trabalhe.

Mas o terminal é apenas a primeira interface, não a única. Sabemos que nem todo mundo que contribui para a qualidade de localização é um desenvolvedor. Falamos disso frequentemente internamente. As pessoas que mais se importam com precisão de tradução, tom e nuances culturais são frequentemente linguistas e especialistas de conteúdo que não pensam em termos de branches, compilação ou JSON.

É por isso que queremos construir novas interfaces sobre o mesmo agente. Algo onde um linguista vê o conteúdo, o contexto e a tradução lado a lado. Eles trazem o julgamento humano que nenhum modelo pode substituir. Eles refinam o que precisa ser refinado. E o agente cuida de tudo o resto: commitar, validar, abrir o pull request.

Ainda não temos todas as respostas, e isso é intencional. Preferimos construir isso com cuidado do que correr para uma UI que perca o objetivo. Mas a direção está clara: Glossia deve acolher todos os que se importam em fazer com que o software fale todas as línguas.

## Fique atento

O Glossia ainda está em fase inicial e estamos o construindo em aberto. Se isso ressoar com a sua forma de pensar sobre localização, continue acompanhando o projeto. Compartilharemos mais à medida que avançarmos.