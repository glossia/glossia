%{
  title: "A localização ficou presa no passado. Criamos o Glossia para levá-la adiante.",
  summary:
    "Ferramentas tradicionais de localização adicionam sobrecarga, quebram a CI e prendem você em ecossistemas de fornecedores. Estamos explorando o que um fluxo de trabalho de localização agêntico pode parecer.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Se você já lançou software em mais de um idioma, conhece a rotina. Você escolhe uma plataforma de localização, conecta-a ao seu repositório e passa o resto do tempo gerenciando a sincronização. O conteúdo sai, as traduções voltam e, em algum ponto, as coisas quebram.

Esse custo, a ida e volta constante de conteúdo para e do seu repositório, é o imposto que cada equipe paga por usar as ferramentas de localização atuais. Parece algo menor até você ser a pessoa que precisa debugar por que um PR de tradução quebrou a build do site às 18h numa sexta-feira.

## Uma concepção herdada da era antes da internet

A maioria das plataformas de localização foi desenhada em torno de conceitos que antecedem o fluxo de desenvolvimento moderno. Memórias de tradução. Fuzzy matching. Tradutores humanos trabalhando dentro de editores proprietários, apoiados por ferramentas que sugerem strings semelhantes de um banco de dados.

Essas ideias faziam sentido quando a tradução era um processo manual, offline. Mas as empresas transformaram as memórias de tradução em um mecanismo de lock-in. Suas traduções passadas, o conhecimento institucional que você pagou, vivem na plataforma deles. Mudar para outro provedor significa começar do zero ou pagar por uma exportação que agora nunca funciona bem.

O resultado é uma indústria construída sobre fricção artificial. Seu conteúdo deixa seu repositório, entra numa caixa preta e retorna segundo o cronograma de outra pessoa.

## O ciclo de feedback quebrado

O problema é estrutural: ferramentas de localização externas não podem rodar seu pipeline de CI. Elas não conhecem seus linters, seu passo de build, seu verificador de links ou seu esquema frontmatter. Elas empurram conteúdo traduzido de volta para o repositório e esperam o melhor. Quando algo quebra, e de fato quebra, alguém da equipe tem que parar o que está fazendo para corrigir problemas de formatação, sintaxe quebrada ou marcação inválida que a ferramenta de tradução引入了.

LLMs e experiências com agentes estão nos apresentando novas oportunidades para repensar integralmente esses fluxos de trabalho. Um agente que gera uma tradução, executa suas verificações, vê o erro e tenta novamente até que a saída seja válida. Esse tipo de ciclo de feedback apertado muda tudo.

Mas só funciona se o conteúdo permanecer onde está: no seu repositório. No momento em que você o envia para uma plataforma externa, as traduções voltam num cronograma de outra pessoa e a integração falha. O feedback que poderia ter sido instantâneo agora leva horas ou dias. O contexto que o tornou útil se foi. Você perde o ciclo, e com ele, toda a vantagem que os fluxos com agentes deveriam ter lhe proporcionado.

## Observações que moldaram a Glossia

Essas frustrações não se transformaram sozinhas na Glossia. O projeto cresceu a partir de uma experiência profunda tanto em desenvolvimento quanto em localização, o que trouxe clareza para problemas difíceis de serem vistos de apenas um lado. Entender os fluxos linguísticos, as dinâmicas humanas das equipes de tradução e os motivos pelos quais as ferramentas existentes chegaram ao estado em que chegaram foi essencial.

Juntos, sempre chegávamos às mesmas observações: as ferramentas de localização foram projetadas para um mundo sem LLMs, sem agentes de codificação e sem pipelines de CI. O modelo inteiro pressupunha que a tradução era algo que acontecia fora do fluxo de desenvolvimento e era reintroduzida posteriormente. Isso fazia sentido há dez anos. Já não faz mais.

Começamos a questionar: **E se os agentes de localização pudessem funcionar da mesma maneira que os agentes de codificação?**

Temos estado prestando muita atenção a como [Anthropic](https://anthropic.com) Pensa em fluxos de trabalho agênticos com Claude. O padrão de dar a um agente acesso a ferramentas, permitindo que ele raciocine em uma tarefa, valide sua própria saída e itere quando algo der errado, se ajuste muito bem à localização. Um agente de tradução capaz de ler seus arquivos de origem, compreender o contexto do projeto, gerar traduções, executar o linter e corrigir problemas antes de abrir um pull request. Isso não é uma fantasia. Esse é o fluxo de trabalho que estamos construindo.

## Glossia é nosso presente à indústria de software

Criamos a Glossia porque queremos mais software localizado, e não menos.

Processos complicados e plataformas caras tornam a localização inacessível para pequenas equipes, desenvolvedores independentes e projetos paralelos. Se o seu fluxo de tradução exigir um processo de compras, uma negociação de preços por palavra e um gerente de projeto para coordenar as entregas, a maioria das equipes lançará em inglês e dará por feito.

O Glossia usa modelos aos quais você já tem acesso. E ele valida a saída com suas próprias ferramentas, não com as nossas.

Acreditamos que a localização deve ser tão natural quanto executar sua suíte de testes.

## Um agente primeiro, interfaces depois

No seu núcleo, o Glossia é um agente. Estamos começando com o terminal como sua interface primária porque é ali que os problemas mais difíceis são resolvidos primeiro: lendo seus arquivos de origem, gerando traduções, executando suas verificações e iterando até a saída ser válida. Esse é o mesmo padrão que [OpenAI](https://openai.com) seguiu com [Codex](https://openai.com/index/openai-codex/) e [Anthropic](https://anthropic.com) com [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Você constrói o agente, dá a ele um terminal e deixa-o trabalhar.

Mas o terminal é apenas a primeira interface, não a única. Sabemos que nem todo quem contribui para a qualidade de localização é um desenvolvedor. Discutimos isso frequentemente internamente. As pessoas que mais se importam com a precisão da tradução, o tom e os nuances culturais são frequentemente linguistas e especialistas em conteúdo que não pensam em termos de branches, compilação ou JSON.

É por isso que queremos construir novas interfaces sobre o mesmo agente. Algo onde um linguista vê o conteúdo, o contexto e a tradução lado a lado. Eles trazem o julgamento humano que nenhum modelo pode substituir. Eles refinam o que precisa ser refinado. E o agente cuida do resto: fazer o commit, validar e criar o pull request.

Ainda não temos todas as respostas e isso é intencional. Preferimos construir isso com ponderação em vez de correr para uma UI que não resolve o problema. Mas a direção está clara: o Glossia deve acolher todos os que se importam em fazer o software falar todas as línguas.

## Fique atento

O Glossia ainda está no início, e estamos construindo-o de forma aberta. Se isso ressoar com a sua visão sobre localização, fique de olho no projeto. Compartilharemos mais conforme avançamos.