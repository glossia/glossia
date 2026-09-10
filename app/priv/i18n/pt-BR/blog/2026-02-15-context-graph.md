%{
  title: "O grafo de contexto: codificando décadas de teoria linguística para a era agêntica",
  summary:
    "Os modelos de linguagem são poderosos, mas precisam do contexto certo para produzir excelente conteúdo. Estamos projetando um grafo versionado e direcionado para capturar conhecimento linguístico e compartilhá-lo com agentes, e consideramos que isso é o que fará a Glossia se destacar.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Tenho pensado bastante sobre o que faz a diferença entre o conteúdo que soa como gerado por máquina e o conteúdo que parece ter sido escrito por alguém que entende o público, a marca e as nuances culturais por trás de cada palavra. A resposta continua voltando para a mesma coisa: **contexto**.

Os modelos de linguagem estão se tornando melhores em idiomas e estamos apostando nessa trajetória continuar. Eles ainda não estão completamente lá, mas o ritmo de melhoria é difícil de ignorar. O que falta, contudo, é o sistema que fica entre o modelo e o conteúdo. A coisa que diz ao modelo *quem* você é, *como* você fala, *o que* importa nessa frase específica, e *por que* essa frase existe no primeiro lugar. Esse é o problema com o qual trabalhamos na Glossia e acho que é o mais interessante no cenário atualmente.

## Três elementos, dois que controlamos

Quando olho no que é necessário para habilitar uma abordagem genuinamente nova para conteúdo monolíngue e multilíngue, vejo três elementos:

1. **Modelos que são bons em idiomas.** Eles ainda não estão totalmente lá, mas estão evoluindo rapidamente e apostamos nessa tendência. Não precisamos criar um modelo de fundação. Precisamos estar prontos para usá-los bem quando chegarem lá.
2. **Um sistema para modelar e compartilhar o contexto que os agentes precisam.** Esta é a parte que fica entre o modelo e o conteúdo. A camada que captura sua voz, sua terminologia, seu tom, suas expectativas do público e fornece tudo isso ao agente de forma estruturada.
3. **O contexto que vem dos usuários.** Humanos trazem juízo, consciência cultural e direção criativa. Nenhum sistema pode substituir isso totalmente. Mas um sistema pode torná-lo fácil de capturar e reutilizar.

Desses três, há dois que controlamos: o próprio sistema e como orientamos os usuários para contribuir com contexto e ajudar a melhorar o sistema. Acreditamos que acertar ambos fará com que a Glossia se destaque em um espaço que está rapidamente se enchendo de soluções "simplesmente conecte um LLM". O sistema é onde precisamos codificar décadas de teoria linguística nos primitivos que estão emergindo no mundo dos agentes. E a experiência do usuário em torno disso é como garantimos que o contexto certo seja realmente capturado, refinado e alimentado de volta ao loop.

Eugene Nida, um dos fundadores dos estudos modernos de tradução, argumentou que uma boa tradução não se trata de correspondência palavra por palavra. Seu conceito de [equivalência dinâmica](https://en.wikipedia.org/wiki/Dynamic_equivalence) diz que a relação entre o público-alvo e a mensagem traduzida deve ser a mesma da relação entre o público original e a fonte. Essa é uma bela ideia, mas exige uma compreensão contextual profunda: quem está lendo, que enquadramento cultural trazem, que tom o original pretendia. Estas são exatamente os tipos de coisas que precisam viver em algum lugar onde um modelo possa acessá-las.

## O que precisamos capturar, e como

Uma das primeiras coisas em que estamos explorando é o que precisa ser capturado e como estruturá-lo para que os agentes possam realmente usá-lo. Quanto mais pensamos nisso, mais percebemos que isso não era um arquivo de configuração plano ou uma página de configurações. Precisava ser um grafo. Especificamente, um **[grafo acíclico dirigido](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Por que um DAG? Porque **o contexto não é plano**. Sua voz de marca influencia sua terminologia. Sua terminologia define como você escreve sobre recursos específicos. As expectativas de seu público informam o nível de formalidade, o que, por sua vez, afeta a escolha de palavras. Essas relações têm direção e hierarquia, e não retornam a si mesmas.

Existem trabalhos anteriores aqui. Os grafos de conhecimento vêm sendo usados há anos em sistemas de IA para representar relações estruturadas entre conceitos. Mais recentemente, [grafos de contexto](https://grokipedia.com/page/context-graph) estenderam essa ideia ao adicionar camadas de contexto dinâmicas, exatamente o tipo de coisa que os agentes precisam para tomar decisões informadas. E no mundo multiagente, [os DAGs tornaram-se um padrão fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependências de tarefas e fluxo de informações.

Mas é essa parte aqui que me empolga: **cada nó neste grafo precisa ser versionado**. Quando você altera sua voz de marca, não deve perder acesso à versão anterior. Ao atualizar um registro terminológico, o sistema precisa saber qual conteúdo foi produzido sob a definição antiga e quais peças podem precisar ser revistas. É isso que nos permite otimizar o fluxo de trabalho de agentes para que seja disparado apenas para as partes realmente impactadas pela mudança, em vez de reprocessar tudo.

## Bidirecional por design

Acreditamos que a relação entre os nós de contexto e o conteúdo precisa ser direcional e precisa funcionar em ambas as direções.

Olhando de um lado: você precisa saber como o conteúdo está conectado ao contexto. Quando um elemento de contexto muda (digamos, sua voz da marca muda para ser mais informal), quais posts de blog, descrições de produtos ou artigos de ajuda foram escritos na versão anterior? Esses são os que precisam ser revisados ou retraduzidos. Isso é o **direção direta, do contexto para o conteúdo**.

Do outro lado: quando um linguista examina uma parte do conteúdo e questiona o porquê de uma escolha específica ter sido feita, ele deve ser capaz de rastreá-la de volta ao contexto que orientou a decisão. Qual definição de voz estava ativa? Qual regra de terminologia se aplicou? Esta **rastreabilidade reversa** é o que permite às pessoas entender o que os agentes fizeram e iterar sobre isso com confiança.

A NASA chama isso [rastreabilidade bidirecional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): a capacidade de seguir uma associação entre entidades em qualquer direção. É um princípio da engenharia de sistemas, e acaba ser exatamente o que você precisa quando está tentando criar um ciclo de feedback entre contexto linguístico e conteúdo gerado.

Essa qualidade bidirecional é o que torna **refinamento progressivo** possível. Um linguista pode revisar uma peça de conteúdo, ver o contexto que a moldou, decidir que a definição de voz precisa de ajuste e criar esse ajuste. O sistema então sabe exatamente qual outro conteúdo é afetado pela mudança. É um ciclo apertado, e é profundamente humano.

## Além de um único repositório

Existe outra dimensão neste grafo que eu acho particularmente interessante. **Não pode viver em um único repositório.** O grafo de contexto precisa ser compartilhável entre projetos, e potencialmente entre organizações.

Pense nisso: uma empresa tem uma voz de marca. Essa voz se aplica a cada produto, cada site, cada artigo de suporte. Não vive em um único repositório. É uma preocupação transversal. Você pode definir sua voz central no nível da organização, depois aplicar as sobreposições no nível do projeto para um produto ou público específico. Esta é **herança de escopo**", o mesmo padrão ao qual estamos acostumados em programação, mas aplicado ao contexto linguístico.

E este contexto precisa ser versionado adequadamente. Você não pode apenas mudar a definição de voz e apagar a versão anterior. Há muito a aprender sobre como [Git lida com versionamento](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) através de armazenamento endereçável por conteúdo e DAGs. O modelo do Git de commits, ramificações e diffs é fundamentalmente sobre rastrear como as coisas mudam ao longo do tempo, preservando acesso a todos os estados anteriores. Isso é exatamente o que precisamos para o contexto linguístico.

De fato, acreditamos que uma mudança de voz deve acontecer através de algo a que chamamos de *solicitação de mudança de voz*. Muito como um pull request cria um espaço para discussão em torno de mudanças de código, uma solicitação de mudança de voz cria espaço para debater mudanças linguísticas. Por que estamos mudando para um tom mais conversacional? Que impacto isso terá? Que conteúdo será afetado? São conversas que valem a pena ter antes que a mudança se propague.

## Onde os humanos se tornam mais criativos, não menos relevantes

E é aqui que as coisas começam a ficar realmente interessantes. Em vez de eliminar humanos, que é a narrativa que muitas pessoas defendem quando falam de IA, este sistema **dá aos humanos um papel mais criativo**.

Imagine uma equipe de linguistas e estrategistas de conteúdo em uma sessão para discutir ideias sobre a direção linguística da marca. Eles poderiam explorar conceitos, debater mudanças de tom, referenciar contexto cultural ao qual nenhum modelo tem acesso. Então, em vez de atualizar manualmente centenas de arquivos, eles capturam suas decisões como ajustes ao grafo de contexto. O sistema cuida da propagação.

Ou leve o assunto um passo adiante: imagine sessões agênticas onde um linguista trabalha com um assistente de IA para explorar ideias linguísticas. "E se tornássemos as mensagens de erro mais empáticas?" O agente simula o impacto, mostra como o contexto atual teria alteração e antecipa como o conteúdo atualizado pode ficar. O linguista refina, ajusta e, quando satisfeito, submete um pedido de alteração de contexto. Não seria incrível?

**Isso não é sobre substituir o linguista.** Trata-se de oferecer ao profissional ferramentas melhores para fazer o que já são excelentes em: tomar decisões sutis e culturalmente fundamentadas sobre a linguagem. O sistema lida com os aspectos mecânicos (propagação, análise de impacto, consistência) enquanto os humanos se concentram nos aspectos criativos (voz, tom, ressonância cultural).

Volto sempre ao que Nida buscava com a equivalência dinâmica. O objetivo não é a precisão linguística em um sentido mecânico. Trata-se de criar a mesma relação sentida entre o leitor e o conteúdo, independentemente da língua. Isso exige bom gosto, julgamento e consciência cultural. Habilidades nas quais os humanos são notavelmente bons e que os modelos ainda têm dificuldade. O papel do sistema é garantir que esses insights humanos sejam capturados, estruturados e reutilizáveis.

## O que vem a seguir

Em uma postagem complementar, seremos mais técnicos e falaremos sobre o papel que os sandboxes desempenharão na viabilização de experiências ainda não vistas neste espaço, e por que estamos investindo pesado em APIs. Existe uma dimensão inteira ligada ao ambiente de staging, pré-visualização e testes de alterações linguísticas antes que sejam publicadas que estamos ansiosos para explorar.

Se qualquer um desses pontos ressoar com você, seja um linguista frustrado com a ferramenta atual, um desenvolvedor que tenha lutado com fluxos de trabalho de localização, ou apenas alguém que pense profundamente sobre como a linguagem e a tecnologia se cruzam, gostaríamos de ouvir sua opinião.