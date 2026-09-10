%{
  title: "O grafo de contexto: codificando décadas de teoria linguística para a era agêntica",
  summary:
    "Modelos de linguagem são poderosos, mas precisam do contexto adequado para produzir conteúdo excelente. Estamos projetando um grafo dirigido e versionado para capturar o conhecimento linguístico e compartilhá-lo com agentes, e acreditamos que é isso que fará o Glossia se destacar.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Ando pensando bastante no que faz a diferença entre conteúdo que soa gerado por máquina e conteúdo que parece ter sido escrito por alguém que entende o público, a marca e as nuances culturais por trás de cada palavra. A resposta volta sempre para a mesma coisa: **contexto**.

Modelos de linguagem estão ficando melhores em idiomas, e estamos apostando nessa trajetória continuar. Eles não estão totalmente lá ainda, mas o ritmo de melhoria é difícil de ignorar. O que ainda falta, no entanto, é o sistema que fica entre o modelo e o conteúdo. Aquilo que diz ao modelo *quem* você é, *como* você fala, *o que* importa nesta frase específica, e *por que* essa frase existe em primeiro lugar. Esse é o problema em que estamos trabalhando na Glossia, e, na minha opinião, é o mais interessante do espaço atualmente.

## Três elementos, dois que controlamos

Ao analisar o que é necessário para viabilizar uma abordagem genuinamente nova para conteúdo monolíngue e multilíngue, vejo três elementos:

1. **Modelos que são bons em línguas.** Eles ainda não estão totalmente lá, mas estão melhorando rápido e apostamos nessa tendência. Não precisamos construir um modelo de fundação. Precisamos estar prontos para usá-los bem quando chegarem.
2. **Um sistema para modelar e compartilhar o contexto que os agentes precisam.** Esta é a peça que fica entre o modelo e o conteúdo. A camada que captura a sua voz, a sua terminologia, o seu tom, as expectativas do seu público e serve tudo isso ao agente de forma estruturada.
3. **O contexto que vem dos usuários.** Humanos trazem julgamento, consciência cultural e direção criativa. Nenhum sistema pode substituir totalmente isso. Mas um sistema pode tornar fácil capturar e reutilizar.

Desses três, controlamos dois: o próprio sistema, e como guiamos os usuários a contribuir com contexto e ajudar a melhorar o sistema. Acreditamos que acertar em ambos é o que fará o Glossia se destacar em um espaço que está rapidamente sendo preenchido com soluções de "basta conectar um LLM". O sistema é onde precisamos codificar décadas de teoria linguística nas primitivas que estão emergindo no mundo agêntico. E a experiência do usuário ao redor é como garantimos que o contexto correto seja realmente capturado, refinado e reintroduzido no ciclo.

Eugene Nida, um dos fundadores dos estudos contemporâneos de tradução, argumentou que a boa tradução não trata de correspondência palavra por palavra. Seu conceito de [equivalência dinâmica](https://en.wikipedia.org/wiki/Dynamic_equivalence) diz que o relacionamento entre o público-alvo e a mensagem traduzida deve parecer idêntico ao relacionamento entre o público original e a fonte. Essa é uma bela ideia, mas requer uma compreensão contextual profunda: quem está lendo, qual enquadramento cultural trazem, qual tom o original pretendia atingir. São exatamente esses tipos de coisas que precisam existir em algum lugar onde um modelo possa acessá-las.

## O que precisamos capturar e como

Uma das primeiras coisas que exploramos é qual informação precisa ser capturada e como estruturá-la para que os agentes possam realmente usá-la. Quanto mais pensamos nisso, mais percebemos que não se tratava de um arquivo de configuração plano ou uma página de configurações. Era necessário ser um grafo. Especificamente, um **[grafo acíclico dirigido](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Por que um DAG? Porque **o contexto não é plano**A voz da sua marca influencia sua terminologia. Sua terminologia molda como você escreve sobre funcionalidades específicas. As expectativas do seu público informam o nível de formalidade, o que por sua vez afeta a escolha de palavras. Essas relações têm direção e hierarquia e não retornam a si mesmas.

Aqui já existem tecnologias anteriores. Gráficos de conhecimento vêm sendo utilizados há anos em sistemas de IA para representar relações estruturadas entre conceitos. Mais recentemente, [gráficos de contexto](https://grokipedia.com/page/context-graph) extenderam essa ideia ao adicionar camadas de contexto dinâmicas, exatamente o tipo de coisa que os agentes precisam para tomar decisões informadas. E no mundo multiagente, [os DAGs tornaram-se um padrão fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependências de tarefas e fluxo de informações.

Mas aqui está a parte que me empolga: **cada nó neste gráfico precisa ser versionado**. Quando você altera a voz da sua marca, você não deve perder acesso à versão anterior. Quando atualiza uma entrada de terminologia, o sistema deve saber qual conteúdo foi produzido sob a antiga definição e quais partes podem precisar ser revisitadas. Isso é o que nos permite otimizar o fluxo de trabalho agêntico para que ele seja acionado apenas nas partes que são realmente impactadas por uma mudança, em vez de reprocessar tudo.

## Bidirecional por design

Acreditamos que a relação entre os nós de contexto e o conteúdo precisa ser direcional e precisa funcionar em ambas as direções.

Olhando de um lado: você precisa saber como o conteúdo está conectado ao contexto. Quando uma peça de contexto muda (digamos, sua voz de marca muda para ser mais casual), quais posts de blog, descrições de produto ou artigos de ajuda foram escritos na versão anterior? São esses que precisam ser revisitados ou retraduzidos. Isso é a **direção para frente, do contexto ao conteúdo**.

Do outro lado: quando um linguista analisa uma peça de conteúdo e se pergunta por que uma escolha específica foi feita, ele deve ser capaz de rastreá-la de volta ao contexto que guiou a decisão. Qual definição de voz estava ativa? Qual regra de terminologia se aplicou? Essa **rastreabilidade para trás** é o que permite aos humanos entender o que os agentes fizeram e iterar sobre isso com confianza.

NASA chama isso [traceabilidade bidirecional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): a capacidade de seguir uma associação entre entidades em qualquer direção. É um princípio da engenharia de sistemas, e acaba por ser exatamente o que você precisa quando você está tentando criar um ciclo de feedback entre o contexto linguístico e o conteúdo gerado.

Esta qualidade bidirecional é o que torna **refinamento progressivo** possível. Um linguista pode revisar um pedaço de conteúdo, ver o contexto que o moldou, decidir que a definição de voz precisa de ajuste, e criar o ajuste. O sistema então sabe exatamente qual outro conteúdo é afetado pela mudança. É um ciclo apertado, e é profundamente humano.

## Além de um único repositório

Há outra dimensão neste grafo que eu acho particularmente interessante. **Não pode viver em um único repositório.** O grafo de contexto precisa ser compartilhável entre projetos e, potencialmente, entre organizações.

Pense nisso: uma empresa tem uma voz de marca. Essa voz se aplica a cada produto, cada site, cada artigo de suporte. Ela não vive em um único repositório. É uma preocupação transversal. Você pode definir sua voz centralizada no nível da organização e depois aplicar sobrescritas no nível do projeto para um produto ou público específico. Isso é **herança de escopo,**o mesmo padrão ao qual estamos acostumados na programação, mas aplicado ao contexto linguístico.

E este contexto precisa ser versionado corretamente. Você não pode apenas alterar a definição de voz e apagar a versão anterior. Há muito o que aprender de como [Git gerencia o versionamento](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) através de armazenamento endereçável por conteúdo e DAGs. O modelo de commits, branches e diffs do Git é fundamentalmente sobre rastrear como as coisas mudam ao longo do tempo enquanto preserva o acesso a cada estado anterior. Isso é exatamente o que precisamos para o contexto linguístico.

Acreditemos, acreditamos que uma mudança de voz deve ocorrer através de algo a que chamamos de *solicitação de mudança de voz*. Muito como um pull request cria um espaço para discussão em torno de mudanças de código, uma solicitação de mudança de voz cria um espaço para discutir mudanças linguísticas. Por que estamos mudando para um tom mais conversacional? Que impacto isso terá? Que conteúdo será afetado? Essas são conversas que valem a pena ter antes que a mudança se propague.

## Onde os humanos se tornam mais criativos, não menos relevantes

E é aqui que as coisas começam a ficar realmente interessantes. Em vez de eliminar humanos, que é a narrativa que muita gente defende quando fala de IA, este sistema **dá a humanos um papel mais criativo**.

Imagine uma equipe de linguistas e estrategistas de conteúdo tendo uma sessão onde discutem ideias sobre a direção linguística da marca. Podem explorar conceitos, debater mudanças de tom, referenciar contexto cultural ao qual nenhum modelo tem acesso. Então, em vez de atualizar manualmente centenas de arquivos, capturam suas decisões como ajustes ao gráfico de contexto. O sistema cuida da propagação.

Ou leve isso um pouco além: imagine sessões com agentes onde um linguista trabalha com um assistente de IA para explorar ideias linguísticas. "E se tornássemos as mensagens de erro mais empáticas?" O agente simula o impacto, mostra como o contexto atual mudaria, e apresenta uma prévia de como o conteúdo atualizado poderia parecer. O linguista refina, ajusta e, quando está satisfeito, envia uma solicitação de alteração de contexto. Isso seria incrível?

**Isso não é sobre substituir o linguista.** Se trata de fornecer a eles melhores ferramentas para fazer o que eles já sabem fazer bem: tomar decisões sutis e culturalmente informadas sobre a linguagem. O sistema gerencia as partes mecânicas (propagação, análise de impacto, consistência) enquanto as pessoas se concentram nas partes criativas (voz, tom, ressonância cultural).

Volto sempre ao que Nida quis dizer com equivalência dinâmica. O objetivo não é a precisão linguística em um sentido mecânico. Trata-se de criar a mesma relação sentida entre o leitor e o conteúdo, independentemente da língua. Isso exige bom gosto, julgamento e consciência cultural. Coisas nas quais os humanos são notavelmente bons, e com as quais os modelos ainda lutam. O trabalho do sistema é garantir que essas perspectivas humanas sejam capturadas, estruturadas e reutilizáveis.

## O que vem a seguir

Em um post complementar, entraremos em detalhes mais técnicos e discutiremos o papel que os ambientes sandbox terão para habilitar experiências que ainda não foram vistas neste espaço, e por que estamos investindo pesadamente em APIs. Existe toda uma dimensão em torno da homologação, pré-visualização e teste de alterações linguísticas antes que elas sejam publicadas, sobre a qual estamos ansiosos para nos aprofundar.

Se qualquer uma desses pontos ressoar com você, seja um linguista frustrado com as ferramentas atuais, um desenvolvedor que tenha enfrentado dificuldades com fluxos de trabalho de localização, ou apenas alguém que pense profundamente sobre como a linguagem e a tecnologia se cruzam, gostaríamos de ouvir de você.