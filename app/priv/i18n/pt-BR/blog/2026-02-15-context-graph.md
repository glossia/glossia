%{
  title: "O grafo de contexto: codificando décadas de teoria linguística para a era agêntica",
  summary: "Modelos de linguagem são poderosos, mas precisam do contexto certo para produzir conteúdo incrível. Estamos projetando um grafo versionado e direcionado para capturar conhecimento linguístico e compartilhá-lo com agentes, e pensamos que isso é o que fará a Glossia se destacar.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Estive pensando bastante sobre o que faz a diferença entre conteúdo que soa gerado por máquina e conteúdo que parece ter sido escrito por alguém que compreende o público, a marca e as nuances culturais por trás de cada palavra. A resposta continua voltando para o mesmo lugar: **contexto**.

Os modelos de linguagem estão se tornando melhores em idiomas, e apostamos nessa trajetória continuar. Eles ainda não chegaram lá totalmente, mas o ritmo de melhoria é difícil de ignorar. O que falta, no entanto, é o sistema que fica entre o modelo e o conteúdo. É a peça que diz ao modelo *quem* você é, *como* você fala, *quais* elementos são relevantes nesta frase específica e *por que* essa frase existe no primeiro lugar. É isso que estamos resolvendo na Glossia, e acho que é o mais interessante no espaço atualmente.

## Três elementos, dois sob nosso controle

Quando olho no que é necessário para habilitar uma abordagem genuinamente nova para conteúdo monolíngüe e multilíngüe, vejo três elementos:

1. **Modelos que são bons em idiomas.** Eles ainda não estão totalmente lá, mas estão melhorando rápido e estamos apostando nessa tendência. Não precisamos construir um modelo de fundação. Precisamos estar preparados para usá-los bem quando chegarem.
2. **Um sistema para modelar e compartilhar o contexto que os agentes precisam.** É a peça que fica entre o modelo e o conteúdo. A camada que captura sua voz, sua terminologia, seu tom, as expectativas de seu público e serve tudo isso ao agente de forma estruturada.
3. **O contexto que vem dos usuários.** Humanos trazem julgamento, consciência cultural e direção criativa. Nenhum sistema pode substituir totalmente isso. Mas um sistema pode facilitar a captura e o reuso.

Desses três, há dois que controlamos: o sistema em si e como guiamos os usuários a contribuir contexto e nos ajudar a melhorar o sistema. Acreditamos que acertar em ambos é o que fará a Glossia se destacar em um espaço que rapidamente se enche com soluções de "apenas conecte um LLM". O sistema é onde precisamos codificar décadas de teoria linguística nos primitivos que estão emergindo no mundo agêntico. E a experiência do usuário ao redor dele é como garantimos que o contexto certo seja realmente capturado, refinado e devolvido ao loop.

Eugene Nida, um dos fundadores dos estudos modernos de tradução, argumentou que boa tradução não é sobre correspondência palavra por palavra. Seu conceito de [equivalência dinâmica](https://en.wikipedia.org/wiki/Dynamic_equivalence) diz que a relação entre o público-alvo e a mensagem traduzida deve senti-se tão idêntica quanto a relação entre o público original e a fonte. É uma ideia bonita, mas exige compreensão contextual profunda: quem está lendo, que enquadramento cultural eles trazem, que tom o original pretendia. Estes são exatamente os tipos de coisas que precisam viver em algum lugar onde um modelo possa acessá-las.

## O que precisamos capturar, e como

Uma das primeiras coisas que temos explorado é que informações precisam ser capturadas, e como estruturá-las para que os agentes possam realmente usá-las. Quanto mais pensamos, mais percebemos que não era um arquivo de configuração plano ou uma página de configurações. Precisava ser um grafo. Especificamente, um **[grafo acíclico direcionado](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Por que um DAG? Porque **contexto não é plano**. Sua voz de marca influencia sua terminologia. Sua terminologia molda como você escreve sobre recursos específicos. As expectativas do seu público informam o nível de formalidade, o que, por sua vez, afeta a escolha de palavras. Essas relações têm direção e hierarquia, e elas não formam ciclos.

Existem antecedentes aqui. Grafos de conhecimento têm sido usados há anos em sistemas de IA para representar relações estruturadas entre conceitos. Mais recentemente, [grafos de contexto](https://grokipedia.com/page/context-graph) estenderam essa ideia adicionando camadas dinâmicas de contexto, exatamente o tipo de coisa que agentes precisam para tomar decisões informadas. E no mundo multiagente, [os DAGs se tornaram um padrão fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependências de tarefas e fluxo de informações.

Mas aqui é a parte que me entusiasma: **cada nó neste grafo precisa ser versionado**. Quando você altera a sua voz de marca, não deveria perder acesso à versão anterior. Quando você atualiza uma entrada de terminologia, o sistema deve saber qual conteúdo foi produzido sob a definição antiga e quais partes podem precisar ser revisitadas. É isso que nos permite otimizar o fluxo de trabalho agênte para que ele seja ativado apenas para as partes realmente impactadas por uma mudança, em vez de reprocessar tudo.

## Bidirecional por design

Acreditamos que a relação entre nós de contexto e conteúdo precisa ser direcional, e precisa funcionar nos dois sentidos.

Olhando de um lado: você precisa saber como o conteúdo está conectado ao contexto. Quando uma parte do contexto muda (digamos, sua voz de marca se torna mais casual), quais posts de blog, descrições de produto ou artigos de ajuda foram escritos sob a versão anterior? São esses os que precisam ser revisitados ou re-traduzidos. Essa é a **direção para frente, do contexto ao conteúdo**.

Do outro lado: quando um linguista olha para uma peça de conteúdo e se pergunta por que uma escolha específica foi feita, ele deve ser capaz de rastreá-la de volta ao contexto que guiou a decisão. Que definição de voz estava ativa? Que regra de terminologia foi aplicada? Essa **rastreabilidade para trás** é o que permite que humanos entendam o que os agentes fizeram e iterem com confiança.

A NASA chama isso de [rastreabilidade bidirecional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): a capacidade de seguir uma associação entre entidades em qualquer direção. É um princípio da engenharia de sistemas, e resulta ser exatamente o que você precisa quando tenta criar um ciclo de feedback entre contexto linguístico e conteúdo gerado.

Essa qualidade bidirecional é o que torna o **refinamento progressivo** possível. Um linguista pode revisar uma peça de conteúdo, ver o contexto que a formou, decidir que a definição de voz precisa de ajuste, e criar esse ajuste. O sistema então sabe exatamente qual outro conteúdo é afetado pela mudança. É um ciclo apertado, e é profundamente humano.

## Além de um único repositório

Existe outra dimensão neste grafo que eu acho particularmente interessante. **Ele não pode viver em um único repositório.** O grafo de contexto precisa ser compartilhável entre projetos, e potencialmente entre organizações.

Pense nisso: uma empresa tem uma voz de marca. Essa voz se aplica a cada produto, cada site, cada artigo de suporte. Ela não vive em um único repositório. É uma preocupação transversal. Você pode definir sua voz centralizada no nível da organização, depois aplicar sobrescritas no nível do projeto para um produto ou público específico. Isso é **herança de escopo**, o mesmo padrão ao qual estamos acostumados na programação, mas aplicado ao contexto linguístico.

E esse contexto precisa ser versionado corretamente. Não basta apenas alterar a definição de voz e apagar a versão anterior. Há muito o que aprender sobre como o [Git trata a versionagem](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) usando armazenamento endereçável por conteúdo e DAGs. O modelo do Git para commits, branches e diffs é fundamentalmente sobre rastrear como as coisas mudam ao longo do tempo, preservando o acesso a cada estado anterior. É exatamente o que precisamos para o contexto linguístico.

Na verdade, acreditamos que uma alteração de voz deve ocorrer por meio de algo a que estamos chamando de *solicitação de alteração de voz*. Assim como uma pull request cria um espaço para discussão em torno de alterações de código, uma solicitação de alteração de voz cria um espaço para discutir alterações linguísticas. Por que estamos migrando para um tom mais conversacional? Qual será o impacto disso? Que conteúdos serão afetados? São conversas que valem a pena ter antes que a alteração se propague.

## Onde os humanos se tornam mais criativos, não menos relevantes

E é aí que as coisas começam a ficar realmente interessantes. Em vez de eliminar humanos, que é a narrativa que muita gente defende quando fala de IA, este sistema **dá aos humanos um papel mais criativo**.

Imagine uma equipe de linguistas e estrategistas de conteúdo em uma sessão onde discutem ideias sobre a direção linguística da marca. Eles poderiam explorar conceitos, debater mudanças de tom, referenciar contexto cultural ao qual nenhum modelo tem acesso. E então, em vez de atualizar manualmente centenas de arquivos, eles capturam suas decisões como ajustes ao gráfico de contexto. O sistema cuida da propagação.

Ou levem isso adiante: imagine sessões agênticas onde um linguista trabalha com um assistente de IA para explorar ideias linguísticas. "Seria possível tornar as mensagens de erro mais empáticas?" O agente simula o impacto, mostra como o contexto atual mudaria, e antecipa como o conteúdo atualizado poderia parecer. O linguista refinou o conteúdo, ajusta e, quando satisfeito, submete uma solicitação de alteração de contexto. Isso não seria incrível?

**Isso não se trata de substituir o linguista.** Trata-se de dar-lhes melhores ferramentas para fazer o que eles já são ótimos em: tomar decisões matizadas e culturalmente informadas sobre a linguagem. O sistema lida com as partes mecânicas (propagação, análise de impacto, consistência) enquanto os humanos se concentram nas partes criativas (voz, tom, ressonância cultural).

Volto sempre ao que Nida quis dizer com a equivalência dinâmica. O objetivo não é a precisão linguística em um sentido mecânico. Trata-se de criar a mesma relação sentida entre leitor e conteúdo, independentemente da linguagem. Isso exige bom gosto, juízo e consciência cultural. Coisas em que os humanos são maravilhosamente habilidosos e com as quais os modelos ainda lutam. O papel do sistema é garantir que esses insights humanos sejam capturados, estruturados e reutilizáveis.

## O que vem a seguir

Em um post subsequente, seremos mais técnicos e falaremos sobre o papel que as caixas de areia desempenharão na habilitação de experiências que ainda não foram vistas neste espaço, e por que estamos investindo pesado em APIs. Há uma dimensão inteira ao redor do estágio de homologação, do pré-visualização e do teste de mudanças linguísticas antes que elas sejam implantadas, que estamos ansiosos para explorar.

Se qualquer parte disso ressoar com você, seja você um linguista frustrado com as ferramentas atuais, um desenvolvedor que enfrentou dificuldades com os fluxos de trabalho de localização, ou simplesmente alguém que pensa profundamente sobre como a linguagem e a tecnologia se cruzam, adoraríamos ouvir você.