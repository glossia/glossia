%{
  title: "O grafo de contexto: codificando décadas de teoria linguística para a era dos agentes",
  summary:
    "Os modelos de linguagem são poderosos, mas precisam do contexto adequado para produzir conteúdo excelente. Estamos projetando um grafo versionado e direcionado para capturar conhecimento linguístico e compartilhá-lo com agentes, e acreditamos que isso é o que fará a Glossia se destacar.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Estive pensando bastante sobre o que faz a diferença entre conteúdo que soa como gerado por máquina e conteúdo que parece escrito por alguém que entende o público, a marca e as nuances culturais por trás de cada palavra. A resposta retorna sempre para o mesmo ponto: **context**.

Os modelos de linguagem estão se tornando melhores em idiomas e apostamos nessa trajetória continuar. Eles ainda não estão totalmente lá, mas o ritmo de evolução é difícil de ignorar. O que falta, contudo, é o sistema que fica entre o modelo e o conteúdo. A coisa que diz ao modelo *quem* você é, *como* você fala, *o que* importa nesta frase em particular, e *por que* essa frase existe em primeiro lugar. Esse é o problema com o qual estamos trabalhando na Glossia e, na minha opinião, é o mais interessante no setor atualmente.

## Três elementos, dois sob nosso controle

Ao analisar o que é necessário para habilitar uma abordagem genuinamente nova para conteúdo monolíngue e multilíngue, identifico três elementos:

1. **Modelos proficientes em línguas.** Eles ainda não estão totalmente prontos, mas estão evoluindo rapidamente e estamos apostando nessa tendência. Não precisamos desenvolver um modelo de base. Precisamos estar prontos para utilizá-los de forma eficaz quando chegar o momento.
2. **Um sistema para modelar e compartilhar o contexto que os agentes precisam.** Esta é a peça que fica entre o modelo e o conteúdo. A camada que captura sua voz, sua terminologia, seu tom, suas expectativas do público, e serve tudo isso ao agente de forma estruturada.
3. **O contexto que vem dos usuários.** Humanos trazem julgamento, consciência cultural e direção criativa. Nenhum sistema pode substituir isso totalmente. Mas um sistema pode tornar fácil capturar e reutilizar.

Desses três, dois estão sob nosso controle: o próprio sistema e como orientamos os usuários a contribuir contexto e ajudar a melhorar o sistema. Acreditamos que acertar os dois é o que fará o Glossia se destacar em um espaço que rapidamente está ficando cheio de soluções de "apenas conecte um LLM". O sistema é onde precisamos codificar décadas de teoria linguística nas primitivas que estão emergindo no mundo dos agentes. E a experiência do usuário ao redor dele é como garantimos que o contexto correto seja realmente capturado, refinado e reintegrado ao ciclo.

Eugene Nida, um dos fundadores dos estudos modernos de tradução, argumentou que a boa tradução não se trata de correspondência palavra por palavra. Seu conceito de [equivalência dinâmica](https://en.wikipedia.org/wiki/Dynamic_equivalence) diz que a relação entre o público-alvo e a mensagem traduzida deve ser a mesma que a relação entre o público original e a fonte. É uma ideia bonita, mas requer compreensão contextual profunda: quem está lendo, que quadro cultural eles trazem, que tom o original buscava. Estes são exatamente os tipos de coisas que precisam viver em algum lugar onde um modelo possa acessá-las.

## O que precisamos capturar, e como

Uma das primeiras coisas que estamos explorando é o que informações precisam ser capturadas e como estruturá-las para que os agentes possam realmente usá-las. Quanto mais pensamos sobre isso, mais percebemos que isso não era um arquivo de configuração plano ou uma página de configurações. Precisava ser um grafo. Especificamente, um **[grafo acíclico direcionado](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Por que um DAG? Porque **contexto não é plano**. Sua voz de marca influencia sua terminologia. Sua terminologia define como você escreve sobre recursos específicos. As expectativas do seu público informam o nível de formalidade, o que por sua vez afeta a escolha das palavras. Essas relações têm direção e hierarquia, e não retornam a si mesmas.

Aqui há estado da arte. Grafos de conhecimento têm sido usados há anos em sistemas de IA para representar relações estruturadas entre conceitos. Mais recentemente, [grafos de contexto](https://grokipedia.com/page/context-graph) têm estendido essa ideia ao adicionar camadas de contexto dinâmicas, exatamente o tipo de coisa que os agentes precisam para tomar decisões informadas. E no mundo multi-agente, [Os DAGs se tornaram um padrão fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependências de tarefas e fluxo de informações.

Mas aqui está a parte que me emociona: **cada nó neste grafo precisa ser versionado**. Quando você muda sua voz de marca, não deve perder acesso à versão anterior. Quando atualiza uma entrada de terminologia, o sistema deve saber qual conteúdo foi produzido sob a definição antiga e quais peças podem precisar ser revistas. Isso é o que nos permite otimizar o fluxo de trabalho agencial para que ele seja acionado apenas para as peças que são realmente impactadas por uma mudança, em vez de reprocesar tudo.

## Bidirecional por design

Acreditamos que a relação entre os nós de contexto e o conteúdo precisa ser direcional, e precisa funcionar em ambos os sentidos.

Analisando de um lado: você precisa saber como o conteúdo está conectado ao contexto. Quando uma peça de contexto muda (por exemplo, sua voz da marca muda para ser mais casual), quais postagens de blog, descrições de produtos ou artigos de ajuda foram escritos sob a versão anterior? Estes são os que precisam ser revisitados ou re-traduzidos. Este é o **direção para frente, do contexto para o conteúdo**.

Do outro lado: quando um linguista examina uma peça de conteúdo e questiona por que uma escolha específica foi feita, ele deve poder rastrear de volta ao contexto que guiou a decisão. Que definição de voz estava ativa? Qual regra de terminologia se aplicou? Isso **rastreabilidade reversa** é o que permite aos humanos entender o que os agentes fizeram e iterar com confiança sobre isso.

A NASA chama isso [rastreabilidade bidirecional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): a capacidade de acompanhar uma associação entre entidades em qualquer direção. É um princípio da engenharia de sistemas, e acabou por ser exatamente o que você precisa quando tenta criar um ciclo de feedback entre o contexto linguístico e o conteúdo gerado.

Essa característica bidirecional é o que torna **refinamento progressivo** possível. Um linguista pode revisar um conteúdo, ver o contexto que o moldou, decidir que a definição de voz precisa de ajuste e criar esse ajuste. O sistema então sabe exatamente quais outros conteúdos são afetados pela mudança. É um ciclo curto e profundamente humano.

## Além de um único repositório

Existe outra dimensão neste grafo que eu considero particularmente interessante. **Não pode viver em um único repositório.** O grafo de contexto precisa ser compartilhável entre projetos, e potencialmente entre organizações.

Pense nisso: uma empresa tem uma voz de marca. Essa voz se aplica em cada produto, em cada site, em cada artigo de suporte. Não vive em um repositório. É uma preocupação transversal. Você pode definir sua voz principal no nível da organização, depois aplicar ajustes no nível do projeto para um produto ou público específico. Isso é **herança de escopo,**, o mesmo padrão a que estamos acostumados em programação, mas aplicado ao contexto linguístico.

E esse contexto precisa ser versionado corretamente. Você não pode apenas alterar a definição de voz e apagar a versão anterior. Há muito a aprender sobre o jeito como [Git gerencia versionamento](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) por meio de armazenamento endereçável por conteúdo e DAGs. O modelo de commits, branches e diffs do Git é fundamentalmente sobre rastrear como as coisas mudam ao longo do tempo, preservando o acesso a cada estado anterior. Isso é exatamente o que precisamos para o contexto linguístico.

Na verdade, acreditamos que uma mudança de tom deve ocorrer por meio de algo que chamamos de uma *solicitação de mudança de tom*. Muito como uma pull request cria um espaço para discussão em torno de mudanças de código, uma solicitação de mudança de tom cria um espaço para discutir alterações linguísticas. Por que estamos mudando para um tom mais conversacional? Que impacto isso terá? Qual conteúdo será afetado? Essas são conversas que valem a pena ter antes que a mudança se propague.

## Onde os humanos se tornam mais criativos, e não menos relevantes

E é aqui que as coisas começam a ficar realmente interessantes. Em vez de eliminar humanos, o que é a narrativa que muita gente defende ao falar de IA, este sistema **dá aos humanos um papel mais criativo**.

Imagine uma equipe de linguistas e estrategistas de conteúdo em uma sessão onde discutem ideias sobre a direção linguística da marca. Eles poderiam explorar conceitos, debater mudanças de tom, referenciar contexto cultural que nenhum modelo tem acesso. E então, em vez de atualizar manualmente centenas de arquivos, eles capturam suas decisões como ajustes ao grafo de contexto. O sistema se encarrega da propagação.

Ou vamos dar um passo adiante: imagine sessões agênticas onde um linguista trabalha com um assistente de IA para explorar ideias linguísticas. O que se conseguissem tornar as mensagens de erro mais empáticas? O agente simula o impacto, mostra como o contexto atual mudaria, antecipa como o conteúdo atualizado poderia parecer. O linguista refinaria, ajustaria e, quando satisfeito, submeteria uma solicitação de alteração de contexto. Não seria incrível?

**Isso não se trata de substituir o linguista.** Trata-se de dar-lhes melhores ferramentas para fazer o que eles já são ótimos: tomar decisões nuanceadas e culturalmente informadas sobre a linguagem. O sistema cuida das partes mecânicas (propagação, análise de impacto, consistência), enquanto os humanos se concentram nas partes criativas (voz, tom, ressonância cultural).

Volvo frequentemente ao que Nida pretendia com a equivalência dinâmica. O objetivo não é a precisão linguística em um sentido mecânico. É criar a mesma relação sentida entre leitor e conteúdo, independentemente da língua. Isso exige bom gosto, julgamento e consciência cultural. Coisas com as quais os humanos são notavelmente bons, e que os modelos ainda têm dificuldade. A função do sistema é garantir que esses insights sejam capturados, estruturados e reutilizáveis.

## O que vem a seguir

Em um artigo de acompanhamento, entraremos mais no técnico e falaremos sobre o papel que os ambientes sandbox desempenharão ao habilitar experiências ainda não vistas neste espaço, e por que estamos investindo fortemente em APIs. Existe uma dimensão completa envolvendo o staging, pré-visualização e testagem de alterações linguísticas antes do lançamento, que estamos ansiosos para explorar.

Se qualquer parte disso ressoar com você, seja porque é um linguista frustrado com as ferramentas atuais, um desenvolvedor que lutou com fluxos de trabalho de localização ou apenas alguém que reflete profundamente sobre como linguagem e tecnologia se cruzam, adoraríamos ouvir de você.