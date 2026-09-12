%{
  title: "O grafo de contexto: codificando décadas de teoria linguística para a era dos agentes",
  summary:
    "Os modelos de linguagem são poderosos, mas precisam do contexto adequado para gerar conteúdo excelente. Estamos projetando um grafo direcionado e versionado para capturar conhecimento linguístico e compartilhá-lo com agentes, e acreditamos que isso é o que fará o Glossia se destacar.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Estou pensando muito sobre o que faz a diferença entre conteúdo que soa gerado por máquina e conteúdo que parece ter sido escrito por alguém que entende o público, a marca e as nuances culturais por trás de cada palavra. A resposta continua voltando para a mesma coisa: **contexto**.

Os modelos de linguagem estão melhorando nas línguas, e apostamos nessa trajetória continuar. Eles ainda não estão totalmente lá, mas o ritmo de melhoria é difícil de ignorar. O que falta, contudo, é o sistema que fica entre o modelo e o conteúdo. A coisa que diz ao modelo *quem* você é, *como* você fala, *o que* importa nesta frase em particular, e *por que* essa frase existe em primeiro lugar. É o problema em que estamos trabalhando na Glossia, e acho que é o mais interessante atualmente no espaço.

## Três elementos, dois que controlamos

Quando olho no que é necessário para permitir uma abordagem genuinamente nova para conteúdo monolíngue e multilíngue, vejo três elementos:

1. **Modelos que são bons em idiomas.** Eles ainda não estão totalmente lá, mas estão melhorando rápido e estamos apostando nessa tendência. Não precisamos construir um modelo de fundação. Precisamos estar prontos para usá-los bem quando chegarem.
2. **Um sistema para modelar e compartilhar o contexto que os agentes precisam.** Isso é a peça que fica entre o modelo e o conteúdo. A camada que captura sua voz, sua terminologia, seu tom, suas expectativas do público e serve tudo isso ao agente de forma estruturada.
3. **O contexto que vem dos usuários.** Os humanos trazem julgamento, consciência cultural e direção criativa. Nenhum sistema pode substituir isso totalmente. Mas um sistema pode facilitar a captura e reutilização.

Desses três, temos dois sob nosso controle: o próprio sistema e como guiamos os usuários para contribuir com contexto e ajudar a melhorar o sistema. Acreditamos que acertar em ambos é o que fará a Glossia se destacar em um espaço que está rapidamente lotado de soluções de "apenas conectar um LLM". O sistema é onde precisamos codificar décadas de teoria linguística nas primitivas que emergem no mundo dos agentes. E a experiência do usuário em torno disso é como garantimos que o contexto correto seja realmente capturado, refinado e reintegrado ao ciclo.

Eugene Nida, um dos fundadores dos estudos modernos de tradução, argumentou que uma boa tradução não se trata de correspondência palavra por palavra. Seu conceito de [equivalência dinâmica](https://en.wikipedia.org/wiki/Dynamic_equivalence) diz que a relação entre o público-alvo e a mensagem traduzida deve ser a mesma que a relação entre o público original e a fonte. É uma ideia bela, mas requer entendimento contextual profundo: quem está lendo, que enquadramento cultural trazem, que tom o original buscava. Estes são exatamente os tipos de coisas que precisam existir em algum lugar onde um modelo possa acessá-las.

## O que precisamos capturar, e como

Uma das primeiras coisas que estamos explorando é qual informação precisa ser capturada, e como estruturá-la para que os agentes possam realmente usá-la. Quanto mais pensamos sobre isso, mais percebemos que não se tratava de um arquivo de configuração plano ou de uma página de configurações. Precisava ser um grafo. Especificamente, um **[grafo acíclico dirigido](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Por que uma DAG? Porque **o contexto não é plano**. Sua voz de marca influencia sua terminologia. Sua terminologia molda como você escreve sobre recursos específicos. As expectativas do seu público determinam o nível de formalidade, o que por sua vez afeta a escolha de palavras. Essas relações têm direção e hierarquia, e não retornam a si mesmas.

Há precedentes aqui. Gráficos de conhecimento vêm sendo utilizados há anos em sistemas de IA para representar relacionamentos estruturados entre conceitos. Mais recentemente, [gráficos de contexto](https://grokipedia.com/page/context-graph) têm ampliado essa ideia ao adicionar camadas de contexto dinâmico, exatamente o que os agentes precisam para tomar decisões informadas. E no mundo multi-agente, [DAGs se tornaram um padrão fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependências de tarefas e fluxo de informações.

Mas é essa parte que mais me emociona: **cada nó neste gráfico precisa ser versionado**. Quando você altera sua voz de marca, não deve perder acesso à versão anterior. Quando você atualiza uma entrada de terminologia, o sistema deve saber qual conteúdo foi produzido sob a definição antiga e quais partes podem precisar ser revisitadas. Isso é o que permite otimizar o fluxo de trabalho de agentes para que seja acionado apenas para as partes realmente impactadas por uma mudança, em vez de reprocessar tudo.

## Bidirecional por design

Acreditamos que a relação entre nós de contexto e conteúdo precisa ser direcional e funcionar nas duas direções.

Analisando de um lado: você precisa saber como o conteúdo está conectado ao contexto. Quando um item de contexto muda (digamos, sua voz de marca passa a ser mais informal), quais posts de blog, descrições de produtos ou artigos de ajuda foram escritos na versão anterior? São estes que precisam ser revisados ou retraduzidos. Isso é o **direção direta, do contexto para o conteúdo**,.

Do outro lado: quando um linguista analisa um trecho de conteúdo e deseja saber por que uma escolha específica foi feita, ele deve ser capaz de rastrear de volta ao contexto que guiou a decisão. Qual definição de voz estava ativa? Qual regra terminológica se aplicou? Isso **rastreabilidade reversa** é o que permite aos humanos compreender o que os agentes fizeram e iterar com confiança sobre isso.

NASA chama isso [rastreamento bidirecional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): a capacidade de seguir uma associação entre entidades em ambas as direções. É um princípio da engenharia de sistemas, e acaba sendo exatamente o que você precisa quando vocês tentam criar um loop de feedback entre contexto linguístico e conteúdo gerado.

Essa qualidade bidirecional é o que torna **refinamento progressivo** possível. Um linguista pode revisar um trecho de conteúdo, ver o contexto que o moldou, decidir que a definição de voz precisa de ajuste e criar esse ajuste. O sistema então sabe exatamente quais outros conteúdos são afetados pela mudança. É um loop apertado, e é profundamente humano.

## Além de um único repositório

Existe outra dimensão neste gráfico que eu acho particularmente interessante. **Ele não pode viver em um único repositório.** O grafo de contexto precisa ser compartilhável entre projetos e, potencialmente, entre organizações.

Pense nisso: uma empresa tem uma voz da marca. Essa voz se aplica a cada produto, a cada site, a cada artigo de suporte. Ela não vive em um único repositório. É uma preocupação transversal. Você pode definir sua voz principal no nível da organização e depois aplicar sobrescritas no nível do projeto para um produto ou público específico. Isso é **herança de escopo**, o mesmo padrão ao qual estamos acostumados na programação, mas aplicado ao contexto linguístico.

E esse contexto precisa ser versionado adequadamente. Você não pode apenas alterar a definição de voz e apagar a versão anterior. Há muito a aprender em como [Git gerencia de versões](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) , através de armazenamento endereçável por conteúdo e DAGs. O modelo do Git de commits, branches e diffs é fundamentalmente sobre rastrear como as coisas mudam ao longo do tempo, preservando o acesso a cada estado anterior. É exatamente o que precisamos para o contexto linguístico.

De fato, acreditamos que uma mudança de voz deve ocorrer através de algo que chamamos de uma *solicitação de mudança de voz*. Muito parecido com uma solicitação de merge que cria um espaço para discussão em torno de alterações de código, uma solicitação de mudança de voz cria um espaço para discutir mudanças linguísticas. Por que estamos mudando para um tom mais conversacional? Qual será o impacto disso? Quais conteúdos serão afetados? Estas são conversas que valem a pena ter antes que a mudança se propague.

## Onde os humanos se tornam mais criativos, não menos relevantes

E é aí que as coisas começam a ficar realmente interessantes. Em vez de eliminar humanos, que é a narrativa que muita gente sustenta quando fala de IA, este sistema **dá aos humanos um papel mais criativo**.

Imagine uma equipe de linguistas e estrategistas de conteúdo em uma sessão em que discutem ideias sobre a direção linguística da marca. Eles poderiam explorar conceitos, debater mudanças de tom, consultar o contexto cultural a que nenhum modelo tem acesso. E então, ao invés de atualizar manualmente centenas de arquivos, eles registram suas decisões como ajustes ao grafo de contexto. O sistema cuida da propagação.

Ou dê um passo adiante: imagine sessões com agentes onde um linguista trabalha com um assistente de IA para explorar ideias linguísticas. \\"E se tornássemos as mensagens de erro mais empáticas?\\" O agente simula o impacto, mostra como o contexto atual mudaria, antecipa como o conteúdo atualizado poderia parecer. O linguista refina, ajusta e, quando satisfeito, submete uma solicitação de alteração de contexto. Isso não seria ótimo?

**Isso não é sobre substituir o linguista.** Trata-se de lhes dar melhores ferramentas para fazer o que eles já são excelentes: tomar decisões linguísticas matizadas, informadas culturalmente. O sistema cuida dos aspectos mecânicos (propagação, análise de impacto, consistência), enquanto os humanos focam nos aspectos criativos (voz, tom, ressonância cultural).

Volto sempre ao que Nida quis dizer com equivalência dinâmica. O objetivo não é a precisão linguística em um sentido mecânico. É criar a mesma relação sentida entre leitor e conteúdo, independentemente do idioma. Isso requer gosto, julgamento e consciência cultural. Coisas com as quais os humanos são notavelmente bons, e com as quais os modelos ainda têm dificuldade. O papel do sistema é garantir que esses insights sejam capturados, estruturados e reutilizáveis.

## O que vem a seguir

Em um post de acompanhamento, entraremos em mais detalhes técnicos e conversaremos sobre o papel que os sandboxes desempenharão na habilitação de experiências que ainda não foram vistas neste espaço, e por que estaremos investindo pesadamente em APIs. Existe toda uma dimensão em torno do staging, da prévia e do teste de alterações linguísticas antes que elas entrem em produção que estamos animados para explorar.

Se qualquer uma dessas ressoar com você, seja um linguista frustrado com as ferramentas atuais, um desenvolvedor que teve dificuldade com fluxos de trabalho de localização, ou apenas alguém que pensa profundamente sobre como a linguagem e a tecnologia se intersectam, gostaríamos muito de ouvir de você.