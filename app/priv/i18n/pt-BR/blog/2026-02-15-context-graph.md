%{
  title: "O grafo de contexto: codificando décadas de teoria linguística para a era dos agentes",
  summary:
    "Modelos de linguagem são poderosos, mas precisam do contexto correto para produzir excelente conteúdo. Estamos projetando um grafo versionado e dirigido para capturar conhecimento linguístico e compartilhá-lo com agentes, e acreditamos que isso é o que fará o Glossia se destacar.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Tenho pensado bastante sobre o que faz a diferença entre conteúdo que soa gerado por uma máquina e conteúdo que parece ter sido escrito por alguém que entende o público, a marca e as nuances culturais por trás de cada palavra. A resposta sempre retorna ao mesmo ponto: **contexto**.

Os modelos de linguagem estão ficando melhores em idiomas, e apostamos nessa trajetória continuar. Eles ainda não estão totalmente lá, mas o ritmo de melhoria é difícil de ignorar. O que ainda falta, no entanto, é o sistema que fica entre o modelo e o conteúdo. A coisa que diz ao modelo *quem* você é, *como* você fala, *o que* importa nesta frase específica, e *por que* essa frase existir no primeiro lugar. Esse é o problema em que trabalhamos na Glossia, e eu acho que é o mais interessante no setor atualmente.

## Três elementos, dois que controlamos

Quando olho para o que é necessário para viabilizar uma abordagem genuinamente nova para conteúdo monolíngue e multilíngue, vejo três elementos:

1. **Modelos que são bons em idiomas.** Eles ainda não estão totalmente lá, mas estão melhorando rápido e apostamos nessa tendência. Não precisamos construir um modelo de fundação. Precisamos estar prontos para usá-los bem quando chegarem lá.
2. **Um sistema para modelar e compartilhar o contexto que os agentes precisam.** Esta é a peça que fica entre o modelo e o conteúdo. A camada que captura sua voz, sua terminologia, seu tom, suas expectativas de público e oferece tudo isso ao agente de forma estruturada.
3. **O contexto que vem dos usuários.** Humanos trazem julgamento, consciência cultural e direção criativa. Nenhum sistema pode totalmente substituir isso. Mas um sistema pode facilitar o registro e a reutilização.

Dessas três, duas estão sob nosso controle: o próprio sistema e como orientamos os usuários a contribuir com contexto e ajudar a melhorar o sistema. Acreditamos que acertar em ambas é o que fará com que o Glossia se destaque em um cenário que está rapidamente preenchendo com soluções de "simplesmente conecte um LLM". O sistema é onde precisamos codificar décadas de teoria linguística nos primitivos que estão surgindo no mundo dos agentes. E a experiência do usuário ao redor é como garantimos que o contexto correto seja realmente capturado, refinado e alimentado de volta ao ciclo.

Eugene Nida, um dos fundadores dos estudos modernos de tradução, argumentou que uma boa tradução não se trata de correspondência palavra por palavra. Seu conceito de [equivalência dinâmica](https://en.wikipedia.org/wiki/Dynamic_equivalence) diz que a relação entre o público-alvo e a mensagem traduzida deve parecer-se com a relação entre o público original e a fonte. Essa é uma bela ideia, mas exige compreensão contextual profunda: quem está lendo, que enquadramento cultural eles trazem, qual tom a original pretendia. Essas são exatamente as coisas que precisam estar em algum lugar onde um modelo possa acessá-las.

## O que precisamos capturar, e como

Uma das primeiras coisas que temos explorado é o tipo de informação que precisa ser capturada e como estruturar para que os agentes possam realmente usá-la. Quanto mais pensamos nisso, mais percebemos que isso não era um arquivo de configuração plano ou uma página de configurações. Precisava ser um grafo. Especificamente, um **[grafo acíclico dirigido](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**,".

Por que um DAG? Porque **o contexto não é plano**. A voz da sua marca influencia sua terminologia. Sua terminologia define como você escreve sobre recursos específicos. As expectativas de seu público informam o nível de formalidade, o que por sua vez afeta a escolha de palavras. Essas relações têm direção e hierarquia, e elas não retornam a si mesmas.

Há trabalhos prévios aqui. Gráficos de conhecimento têm sido usados há anos em sistemas de IA para representar relacionamentos estruturados entre conceitos. Mais recentemente, [gráficos de contexto](https://grokipedia.com/page/context-graph) estenderam essa ideia ao adicionar camadas de contexto dinâmico, exatamente o tipo de coisa que os agentes precisam para tomar decisões informadas. E no mundo multiagente, [os DAGs tornaram-se um padrão fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependências de tarefas e fluxo de informações.

Mas é a parte que mais me anima: **cada nó neste grafo precisa ser versionado**. Quando você muda a voz da marca, você não deve perder acesso à versão anterior. Quando atualiza uma entrada de terminologia, o sistema deve saber qual conteúdo foi produzido sob a definição antiga e quais partes podem precisar ser revistas. Isso nos permite otimizar o fluxo de trabalho agêntico para que ele seja acionado apenas para as partes realmente impactadas por uma mudança, em vez de reprocessar tudo.

## Bidirecional por design

Acreditamos que a relação entre os nós de contexto e o conteúdo precisa ser direcional e precisa funcionar nos dois sentidos.

Considerando de um lado: você precisa saber como o conteúdo se conecta ao contexto. Quando uma peça de contexto muda (digamos, seu tom de voz da marca muda para um tom mais casual), quais posts de blog, descrições de produtos ou artigos de ajuda foram escritos sob a versão anterior? São esses que precisam ser revisitados ou retraduzidos. Isso é o **direção para frente, do contexto ao conteúdo**.

Do outro lado: quando um tradutor analisa uma peça de conteúdo e se pergunta por que uma escolha específica foi feita, eles devem poder rastreá-la de volta ao contexto que guiou a decisão. Que definição de tom de voz estava ativa? Que regra de terminologia se aplicava? Isso **rastreabilidade reversa** é o que permite que humanos entendam o que os agentes fizeram e iterem sobre isso com confiança.

A NASA chama isso de [traceabilidade bidirecional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): a capacidade de seguir uma associação entre entidades em qualquer direção. É um princípio da engenharia de sistemas, e resulta ser exatamente o que você precisa quando tenta criar um ciclo de feedback entre o contexto linguístico e o conteúdo gerado.

Essa qualidade bidirecional é o que torna **refinamento progressivo** possível. Um linguista pode revisar um conteúdo, ver o contexto que o moldou, decidir que a definição de voz precisa de ajuste e realizar esse ajuste. O sistema então sabe exatamente quais outros conteúdos são afetados pela mudança. É um laço apertado e profundamente humano.

## Além de um único repositório

Há outra dimensão neste grafo que considero particularmente interessante. **Não pode viver em um único repositório.** O grafo de contexto precisa ser compartilhável entre projetos e, potencialmente, entre organizações.

Pense nisso: uma empresa possui uma voz de marca. Essa voz se aplica a cada produto, a cada site, a cada artigo de suporte. Não vive em um único repositório. É uma preocupação transversal. Você pode definir sua voz principal no nível da organização e aplicar sobreposições no nível do projeto para um produto ou público específico. Isso é **herança de escopo**, o mesmo padrão ao qual estamos acostumados na programação, mas aplicado ao contexto linguístico.

E este contexto precisa ser versionado adequadamente. Você não pode apenas alterar a definição de voz e apagar a versão anterior. Há muito a aprender com como [Git lida com versionamento](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) através de armazenamento endereçável por conteúdo e DAGs. O modelo do Git de commits, ramificações e diffs é fundamentalmente sobre rastrear como as coisas mudam ao longo do tempo enquanto preserva acesso a cada estado anterior. Isso é exatamente o que precisamos para o contexto linguístico.

De fato, pensamos que uma mudança de voz deve acontecer através de algo que estamos chamando de uma *solicitação de alteração de voz*. Muito parecido com uma pull request que cria um espaço para discussão sobre alterações de código, uma solicitação de alteração de voz cria um espaço para discutir mudanças linguísticas. Por que Estamos optando por um tom mais conversacional? Que impacto isso terá? Qual conteúdo será afetado? Essas são conversas que valem a pena ter antes que a mudança se propague.

## Onde os humanos se tornam mais criativos, não menos relevantes

E é aqui que as coisas começam a ficar realmente interessantes. Em vez de eliminar humanos, que é a narrativa que muitas pessoas defendem ao falar de IA, este sistema **dá aos humanos um papel mais criativo**.

Imagine uma equipe de linguistas e estrategistas de conteúdo com uma sessão em que discutam ideias sobre a direção linguística da marca. Eles pourraient explorar conceitos, debater mudanças de tom, referenciar contexto cultural que nenhum modelo tem acesso. E então, em vez de atualizar manualmente centenas de arquivos, capturam as decisões como ajustes ao grafo de contexto. O sistema cuida da propagação.

Ou leve isso um passo além: imagine sessões agênticas em que um linguista trabalha com um assistente de IA para explorar ideias linguísticas. \\"E se tornássemos as mensagens de erro mais empáticas?\\" O agente simula o impacto, mostra como o contexto atual mudaria, e antecipa o que o conteúdo atualizado pode parecer. O linguista refina, ajusta e, quando satisfeito, submete uma solicitação de alteração de contexto. Não seria incrível?

**Isso não se trata de substituir o linguista.** Trata-se de fornecer a eles melhores ferramentas para fazerem o que já são excelentes em: tomar decisões linguísticas matizadas e culturalmente informadas. O sistema cuida das partes mecânicas (propagação, análise de impacto, consistência), enquanto os humanos focam nas partes criativas (voz, tom, ressonância cultural).

Volto frequentemente ao que Nida queria dizer com equivalência dinâmica. O objetivo não é a precisão linguística em um sentido mecânico. Trata-se de criar a mesma relação sentida entre o leitor e o conteúdo, seja qual for a língua. Isso exige bom gosto, julgamento e consciência cultural. Coisas em que os humanos são excepcionalmente bons e em que os modelos ainda têm dificuldade. O papel do sistema é garantir que esses insights humanos sejam capturados, estruturados e reutilizáveis.

## O que vem a seguir

Em uma postagem subsequente, abordaremos com mais detalhes e falaremos sobre o papel que os ambientes sandbox terão na viabilizar experiências que ainda não foram vistas neste espaço, e por que estamos investindo fortemente em APIs. Há uma dimensão inteira sobre o staging, pré-visualização e teste de mudanças linguísticas antes que elas entrem em produção, o que estamos empolgados para aprofundar.

Se qualquer um desses pontos ressoar com você, seja um linguista frustrado com o atual conjunto de ferramentas, um desenvolvedor que tenha se debatido com fluxos de trabalho de localização, ou apenas alguém que reflita profundamente sobre como a linguagem e a tecnologia se cruzam, gostaríamos de ouvir de você.