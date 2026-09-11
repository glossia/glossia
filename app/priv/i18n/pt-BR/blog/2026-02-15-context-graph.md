%{
  title: "O grafo de contexto: codificando décadas de teoria linguística para a era agêntica",
  summary:
    "Modelos de linguagem são poderosos, mas precisam do contexto adequado para produzir conteúdo excelente. Estamos projetando um grafo versionado e dirigido para capturar conhecimento linguístico e compartilhá-lo com agentes, e acreditamos que é isso que fará a Glossia se destacar.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Andei muito pensando sobre o que faz a diferença entre conteúdo que soa gerado por máquina e conteúdo que parece ter sido escrito por alguém que compreende o público, a marca e as nuances culturais por trás de cada palavra. A resposta sempre volta à mesma coisa: **contexto**.

Os modelos de linguagem estão ficando melhores em idiomas, e apostamos nessa trajetória continuar. Eles ainda não estão totalmente lá, mas o ritmo de melhoria é difícil de ignorar. O que falta, no entanto, é o sistema que fica entre o modelo e o conteúdo. A coisa que diz ao modelo *quem* você é, *como* você fala, *o que* importa nessa frase específica, e *por que* essa frase existe antes de tudo. Esse é o problema com o qual estamos trabalhando no Glossia, e acho que é o mais interessante no espaço atualmente.

## Três elementos, dois controlamos

Ao analisar o que é necessário para viabilizar uma abordagem genuinamente nova para conteúdo monolíngue e multilíngue, vejo três elementos:

1. **Modelos proficientes em idiomas.** Eles ainda não estão totalmente lá, mas estão melhorando rapidamente e estamos apostando nessa tendência. Não precisamos construir um modelo de base. Precisamos estar prontos para usá-los bem quando chegarem.
2. **Um sistema para modelar e compartilhar o contexto que os agentes precisam.** Esta é a peça que fica entre o modelo e o conteúdo. A camada que captura sua voz, sua terminologia, seu tom, as expectativas do seu público e serve tudo isso ao agente de forma estruturada.
3. **O contexto que vem dos usuários.** Os humanos trazem julgamento, consciência cultural e direção criativa. Nenhum sistema pode substituir isso completamente. Mas um sistema pode torná-lo fácil de capturar e reutilizar.

Das três, há duas que controlamos: o próprio sistema e como orientamos os usuários a contribuir com contexto e nos ajudar a melhorar o sistema. Acreditamos que acertar ambas é o que fará do Glossia se destacar em um espaço que está rapidamente se enchendo com soluções de "apenas conectar um LLM". É no sistema que precisamos codificar décadas de teoria linguística nos primitivos que estão emergindo no mundo agêntico. E a experiência do usuário ao redor é como nos garantimos que o contexto correto seja realmente capturado, refinado e realimentado no ciclo.

Eugene Nida, um dos fundadores dos estudos modernos de tradução, argumentou que uma boa tradução não é sobre correspondência palavra por palavra. Seu conceito de [equivalência dinâmica](https://en.wikipedia.org/wiki/Dynamic_equivalence) afirma que a relação entre o público-alvo e a mensagem traduzida deve se sentir a mesma que a relação entre o público original e a fonte. Essa é uma ideia belíssima, mas exige compreensão contextual profunda: quem está lendo, que enquadramento cultural eles trazem, que tom o original buscava. São exatamente os tipos de coisas que precisam estar em um lugar onde um modelo possa acessá-las.

## O que precisamos capturar, e como

Uma das primeiras coisas que estamos explorando é o que precisa ser capturado e como estruturá-lo para que os agentes possam realmente utilizá-lo. Quanto mais pensamos sobre isso, mais percebemos que não era um arquivo de configuração plano ou uma página de configurações. Precisava ser um grafo. Especificamente, um **[grafo acíclico direcionado](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Por que um DAG? Porque **o contexto não é plano**A voz da sua marca influencia sua terminologia. Sua terminologia molda como você escreve sobre recursos específicos. As expectativas do seu público informam o nível de formalidade, o que, por sua vez, afeta a escolha de palavras. Essas relações têm direção e hierarquia, e não retornam a si mesmas.

Aqui já existem trabalhos anteriores. Grafos de conhecimento são usados há anos em sistemas de IA para representar relacionamentos estruturados entre conceitos. Mais recentemente, [grafos de contexto](https://grokipedia.com/page/context-graph) expandiram essa ideia adicionando camadas dinâmicas de contexto, exatamente o tipo de coisa que os agentes precisam para tomar decisões informadas. E no mundo multiagente, [DAGs se tornaram um padrão fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependências de tarefas e fluxo de informações.

Mas aqui está a parte que me anima: **cada nó neste grafo precisa ser versionado**. Quando você altera a voz da marca, não deve perder acesso à versão anterior. Quando você atualiza uma entrada de terminologia, o sistema deve saber qual conteúdo foi produzido sob a definição antiga e quais partes podem precisar ser revistas. É isso que nos permite otimizar o fluxo de trabalho dos agentes para que ele seja acionado apenas para as partes realmente impactadas por uma alteração, e não para reprocesar tudo.

## Bidirecional por design

Acreditamos que a relação entre nós de contexto e conteúdo precisa ser direcional, e precisa funcionar nas duas direções.

Ao olhar por um lado: você precisa saber como o conteúdo está conectado ao contexto. Quando uma parte do contexto muda (por exemplo, sua voz de marca muda para ser mais casual), quais posts de blog, descrições de produtos ou artigos de ajuda foram escritos sob a versão anterior? Esses são os que precisam ser revisitados ou retraduzidos. Isso é a **direção direta, do contexto ao conteúdo**.

Do outro lado: quando um linguista observa um trecho de conteúdo e questiona por que uma escolha específica foi feita, ele deve ser capaz de rastrear de volta ao contexto que guiou a decisão. Qual definição de voz estava ativa? Qual regra de terminologia se aplicou? Esta **rastreabilidade reversa** é o que permite que humanos entendam o que os agentes fizeram e iterem sobre isso com confiança.

A NASA chama isso [rastreabilidade bidirecional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): a capacidade de seguir uma associação entre entidades em ambas as direções. É um princípio da engenharia de sistemas, e acaba sendo exatamente o que você precisa ao tentar criar um ciclo de realimentação entre o contexto linguístico e o conteúdo gerado.

Esta qualidade bidirecional é o que torna **refinamento progressivo** possível. Um linguista pode revisar um trecho de conteúdo, ver o contexto que o moldou, decidir que a definição de voz precisa de ajuste e criar tal ajuste. O sistema então sabe exatamente qual outro conteúdo é afetado pela mudança. É um ciclo apertado e profundamente humano.

## Além de um único repositório

Há outra dimensão neste grafo que considero particularmente interessante. **Não pode viver em um único repositório.** O grafo de contexto precisa ser compartilhável entre projetos, e potencialmente entre organizações.

Pense nisso: uma empresa tem uma voz da marca. Essa voz se aplica em todos os produtos, todos os sites, todos os artigos de suporte. Ela não vive em um único repositório. É uma preocupação transversal. Você pode definir sua voz principal no nível da organização e aplicar sobrescritas no nível do projeto para um produto ou público específico. Isso é **herança de escopo**, o mesmo padrão ao qual estamos acostumados na programação, mas aplicado ao contexto linguístico.

E esse contexto precisa ser versionado adequadamente. Você não pode simplesmente mudar a definição de voz e apagar a versão anterior. Há muito o que aprender sobre como [Git gerencia versionamento](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) através de armazenamento endereçável por conteúdo e DAGs. O modelo de commits, ramos e diffs do Git é fundamentalmente sobre rastrear como as coisas mudam ao longo do tempo, preservando o acesso a cada estado anterior. Isso é exatamente o que precisamos para o contexto linguístico.

Na verdade, achamos que uma mudança de voz deve acontecer por meio de algo a que chamamos de *solicitação de mudança de voz*. Muito como uma pull request cria um espaço para discussão em torno de mudanças de código, uma solicitação de mudança de voz cria um espaço para discutir mudanças linguísticas. Por que estamos adotando um tom mais conversacional? Qual o impacto disso terá? Qual conteúdo será afetado? Estas são conversas que valem a pena ter antes da mudança se propagar.

## Onde humanos se tornam mais criativos, não menos relevantes

E é aqui que as coisas começam a ficar realmente interessantes. Em vez de eliminar humanos, que é a narrativa que muita gente defende quando fala de IA, este sistema **dá aos humanos um papel mais criativo**.

Imagine uma equipe de linguistas e estrategistas de conteúdo em uma sessão onde discutem ideias sobre a direção linguística da marca. Eles podem explorar conceitos, debater mudanças de tom, referenciar contexto cultural que nenhum modelo tem acesso. E, então, em vez de atualizar manualmente centenas de arquivos, capturam suas decisões como ajustes ao grafo de contexto. O sistema cuida da propagação.

Ou levem isso um passo adiante: imagine sessões agênticas onde um linguista trabalha com um assistente de IA para explorar ideias linguísticas. "E se tornássemos as mensagens de erro mais empáticas?" O agente simula o impacto, mostra como o contexto atual mudaria e antecipa como o conteúdo atualizado pode parecer. O linguista refina, ajusta e, quando fica satisfeito, envia uma solicitação de alteração de contexto. Isso seria incrível?

**Isso não se trata de substituir o linguista.** Trata-se de dar-lhes melhores ferramentas para realizarem o que já são ótimos: tomar decisões nuancadas e culturalmente informadas sobre a linguagem. O sistema gerencia as partes mecânicas (propagação, análise de impacto, consistência) enquanto humanos se concentram nas partes criativas (voz, tom, ressonância cultural).

Volto sempre ao que Nida buscava com a equivalência dinâmica. O objetivo não é precisão linguística em sentido mecânico. Trata-se de criar a mesma relação sentida entre o leitor e o conteúdo, independentemente da língua. Isso requer gosto, julgamento e conscientização cultural. Coisas nas quais os humanos são notavelmente bons, e com as quais os modelos ainda lutam. O papel do sistema é garantir que essas perspectivas humanas sejam capturadas, estruturadas e reutilizáveis.

## O que vem a seguir

Em um post de acompanhamento, aprofundaremos o lado técnico e falaremos sobre o papel dos ambientes sandbox na habilitação de experiências que ainda não foram vistas neste espaço, e por que estamos investindo fortemente em APIs. Existe toda uma dimensão em torno do ambiente de staging, visualização prévia e teste de alterações linguísticas antes que sejam publicadas, sobre a qual estamos empolgados em explorar.

Se isso ressoar com você, seja você um linguista frustrado com as ferramentas atuais, um desenvolvedor que teve dificuldades com fluxos de localização, ou apenas alguém que pensa profundamente sobre como a linguagem e a tecnologia se cruzam, gostaríamos de ouvir você.