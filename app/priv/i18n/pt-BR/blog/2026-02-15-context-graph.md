%{
  title: "O grafo de contexto: codificando décadas de teoria linguística para a era agêntica",
  summary:
    "Modelos de linguagem são potentes, mas precisam do contexto adequado para gerar conteúdo excelente. Estamos projetando um grafo versionado e dirigido para capturar conhecimento linguístico e compartilhá-lo com agentes, e acreditamos que é isso que fará a Glossia se destacar.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Tenho pensado muito sobre o que faz a diferença entre conteúdo que parece gerado por máquina e conteúdo que dá a sensação de ter sido escrito por alguém que entende o público, a marca e as nuances culturais por trás de cada palavra. A resposta sempre volta para a mesma coisa: **contexto**.

Os modelos de linguagem estão ficando melhores em línguas, e estamos apostando nessa tendência continuar. Eles ainda não estão totalmente lá, mas o ritmo de melhoria é difícil de ignorar. O que falta, no entanto, é o sistema que fica entre o modelo e o conteúdo. É esse o componente que diz ao modelo *quem* você é, *como* você fala, *o que* importa nesta frase específica e *por que* essa frase existe em primeiro lugar. É esse o problema com o qual trabalhamos na Glossia, e eu acredito que é o mais interessante do espaço atualmente.

## Três elementos, dois sob nosso controle

Quando olho para o que é necessário para viabilizar uma abordagem genuinamente nova para conteúdo mono-língue e multi-língue, vejo três elementos:

1. **Modelos bons em línguas.** Eles ainda não estão totalmente lá, mas estão melhorando rapidamente e estamos apostando nessa tendência. Não precisamos construir um modelo de base. Precisamos estar prontos para usá-los bem quando chegarem lá.
2. **Um sistema para modelar e compartilhar o contexto que os agentes precisam.** Esta é a peça que fica entre o modelo e o conteúdo. A camada que captura sua voz, sua terminologia, seu tom, suas expectativas do público e serve tudo isso ao agente de forma estruturada.
3. **O contexto que vem dos usuários.** Humanos trazem julgamento, consciência cultural e direção criativa. Nenhum sistema pode plenamente substituir isso. Mas um sistema pode facilitar a captura e a reutilização.

Desses três, há dois que controlamos: o próprio sistema e a forma como orientamos os usuários para contribuir com contexto e ajudar a melhorar o sistema. Acreditamos que acertar ambos é o que fará a Glossia se destacar em um espaço que está rapidamente se preenchendo com soluções de "apenas integrar um LLM". O sistema é onde precisamos codificar décadas de teoria linguística nas primitivas que estão emergindo no mundo dos agentes. E a experiência do usuário ao seu redor é como garantimos que o contexto certo seja realmente capturado, refinado e alimentado de volta ao processo.

Eugene Nida, um dos fundadores dos estudos modernos de tradução, argumentou que a boa tradução não se trata de correspondência palavra por palavra. Seu conceito de [equivalência dinâmica](https://en.wikipedia.org/wiki/Dynamic_equivalence) diz que a relação entre o público-alvo e a mensagem traduzida deve ser a mesma que a relação entre o público original e a fonte. É uma ideia linda, mas exige profundo entendimento contextual: quem está lendo, que quadro cultural eles trazem, que tom o original pretendia. São exatamente esses os tipos de coisas que precisam morar em algum lugar que um modelo possa acessá-los.

## O que precisamos capturar e como

Uma das primeiras coisas que temos explorado é qual informação precisa ser capturada e como estruturá-la para que os agentes consigam realmente usá-la. Quanto mais pensamos sobre isso, mais percebemos que isso não poderia ser um arquivo de configuração plano ou uma página de configurações. Precisava ser um grafo. Especificamente, um **[grafo acíclico dirigido](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Por que um DAG? Porque o **contexto não é plano**. Sua voz de marca influencia sua terminologia. Sua terminologia molda como você escreve sobre funcionalidades específicas. As expectativas do seu público informam o nível de formalidade, o que por sua vez afeta a escolha de palavras. Essas relações têm direção e hierarquia, e não retornam a si mesmas.

Aqui há antecedentes técnicos. Gráficos de conhecimento têm sido usados há anos em sistemas de IA para representar relações estruturadas entre conceitos. Mais recentemente, [gráficos de contexto](https://grokipedia.com/page/context-graph) estenderam essa ideia adicionando camadas de contexto dinâmicas, exatamente o tipo de coisa que agentes precisam para tomar decisões informadas. E no mundo multiagente, [DAGs se tornaram um padrão fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependências de tarefas e fluxo de informações.

Mas é aqui que a coisa me empolga: **cada nó neste gráfico precisa ser versionado**. Quando você altera sua voz de marca, não deve perder acesso à versão anterior. Quando você atualiza uma entrada de terminologia, o sistema deve saber qual conteúdo foi produzido sob a definição antiga e quais partes podem precisar ser revistas. É isso que nos permite otimizar o fluxo de trabalho de agentes para que ele apenas dispare para as peças que são realmente impactadas por uma mudança, em vez de reprocessar tudo.

## Bidirecional por design

Acreditamos que a relação entre nós de contexto e conteúdo precisa ser direcional, e precisa funcionar nos dois sentidos.

Olhando de um lado: você precisa saber como o conteúdo está conectado ao contexto. Quando uma peça de contexto muda (diga, sua voz de marca muda para ser mais casual), quais posts de blog, descrições de produtos ou artigos de ajuda foram escritos sob a versão anterior? Estes são aqueles que precisam ser revisitados ou retraduzidos. Esta é a **direção direta, do contexto para o conteúdo**.

Do outro lado: quando um lingüista examina uma peça de conteúdo e se pergunta por que uma escolha particular foi feita, ele deve ser capaz de rastrear de volta ao contexto que orientou a decisão. Qual definição de voz estava ativa? Qual regra de terminologia foi aplicada? Essa **rastreabilidade para trás** é o que permite aos humanos entender o que os agentes fizeram e iterar sobre isso com confiança.

A NASA chama isso de [rastreabilidade bidirecional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): a capacidade de seguir uma associação entre entidades em qualquer direção. É um princípio da engenharia de sistemas, e acabou sendo exatamente o que você precisa quando tenta criar um loop de feedback entre contexto linguístico e conteúdo gerado.

Essa qualidade bidirecional é o que torna o **refinamento progressivo** possível. Um lingüista pode revisar um conteúdo, ver o contexto que o moldou, decidir que a definição de voz precisa de ajuste e criar esse ajuste. O sistema então sabe exatamente qual outro conteúdo é afetado pela mudança. É um loop apertado, e é profundamente humano.

## Além de um único repositório

Há outra dimensão neste gráfico que considero particularmente interessante. **Não pode viver em um único repositório.** O gráfico de contexto precisa ser compartilhável entre projetos, e potencialmente entre organizações.

Penise nisso: uma empresa tem uma voz de marca. Essa voz se aplica em todos os produtos, todos os sites, todos os artigos de suporte. Ela não vive em um único repositório. É uma preocupação transversal. Você pode definir sua voz central no nível de organização, e depois aplicar sobreposições no nível de projeto para um produto ou público específico. Isso é **herança de escopo**, o mesmo padrão ao qual estamos acostumados na programação, mas aplicado ao contexto linguístico.

E este contexto precisa ser versionado adequadamente. Você não pode apenas mudar a definição de voz e apagar a versão anterior. Há muito o que aprender com o modo como o [Git lida com o versionamento](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) por meio de armazenamento endereçável por conteúdo e DAGs. O modelo de commits, branches e diffs do Git é fundamentalmente sobre rastrear como as coisas mudam ao longo do tempo, preservando o acesso a todos os estados anteriores. É exatamente isso que precisamos para o contexto linguístico.

Na verdade, achamos que uma alteração de voz deve ocorrer por meio de algo que我们正在 chamando de *solicitação de alteração de voz*. Da mesma forma que um pull request cria um espaço para discussão em torno de alterações de código, uma solicitação de alteração de voz cria um espaço para discutir alterações linguísticas. Por que estamos mudando para um tom mais conversacional? Que impacto teremos? Que conteúdo será afetado? Essas são conversas vale a pena ter antes que a alteração se propague.

## Onde os humanos se tornam mais criativos, não menos relevantes

E é aqui que as coisas começam a ficar muito interessantes. Em vez de eliminar humanos, que é a narrativa que muitas pessoas impõem quando falam sobre IA, este sistema **dá aos humanos um papel mais criativo**.

Imagine uma equipe de lingüistas e estrategistas de conteúdo tendo uma sessão onde discutem ideias sobre a direção linguística da marca. Eles podem explorar conceitos, debater mudanças de tom, referenciar contexto cultural ao qual nenhum modelo tem acesso. E, em vez de atualizar manualmente centenas de arquivos, capturam suas decisões como ajustes ao gráfico de contexto. O sistema cuida da propagação.

Ou dê um passo adiante: imagine sessões com agentes onde um lingüista trabalha com um assistente de IA para explorar ideias linguísticas. "E se tornássemos as mensagens de erro mais empáticas?" O agente simula o impacto, mostra como o contexto atual mudaria, e antecipa o que o conteúdo atualizado pode parecer. O lingüista refinaria, ajustar, e quando estão satisfeitos, submete uma solicitação de alteração de contexto. Não seria algo assim?

**Isso não é sobre substituir o lingüista.** Trata-se de oferecer ferramentas melhores para que eles realizem o que já são ótimos em: tomar decisões sutis e culturalmente informadas sobre a linguagem. O sistema lida com as partes mecânicas (propagação, análise de impacto, consistência) enquanto os humanos se concentram nas partes criativas (voz, tom, ressonância cultural).

Volto sempre ao que Nida pretendia com a equivalência dinâmica. O objetivo não é precisão linguística em um sentido mecânico. É criar a mesma relação sentida entre o leitor e o conteúdo, independentemente da língua. Isso exige gosto, julgamento e consciência cultural. Coisas que os seres humanos fazem notavelmente bem, que os modelos ainda têm dificuldade. O trabalho do sistema é garantir que essas insights humanas sejam capturadas, estruturadas e reutilizáveis.

## O que está porvir

Em um post futuro, vamos ser mais técnicos e falar sobre o papel que os sandboxes desempenham ao permitir experiências que ainda não foram vistas neste espaço, e por que investimos pesadamente em APIs. Existe toda uma dimensão em torno do staging, preview e testes de alterações linguísticas antes de irem para a produção, que estamos ansiosos para aprofundar.

Se qualquer ponto disso ressoa com você, seja um lingüista frustrado com as ferramentas atuais, um desenvolvedor que já encontrou dificuldades com os fluxos de trabalho de localização, ou apenas alguém que reflete profundamente sobre como a linguagem e a tecnologia se interconectam, adoraríamos ouvir de você.