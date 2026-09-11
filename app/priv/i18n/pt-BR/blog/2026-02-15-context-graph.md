%{
  title: "O grafo de contexto: codificando décadas de teoria linguística para a era agêntica",
  summary:
    "Modelos de linguagem são potentes, mas precisam do contexto certo para produzir conteúdo excelente. Estamos projetando um grafo direcionado e versionado para capturar conhecimento linguístico e compartilhá-lo com agentes, e acreditamos que isso é o que fará a Glossia se destacar.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Tenho pensado bastante sobre o que faz a diferença entre o conteúdo que soa gerado por máquina e o conteúdo que parece ter sido escrito por alguém que entende o público, a marca e as nuances culturais por trás de cada palavra. A resposta continua voltando para a mesma coisa: **contexto**.

Os modelos de linguagem estão se tornando melhores nas línguas e estamos apostando que essa trajetória continuará. Eles ainda não estão totalmente lá, mas o ritmo de melhoria é difícil de ignorar. O que ainda falta, porém, é o sistema que fica entre o modelo e o conteúdo. O que diz ao modelo *quem* você é, *como* você fala, *o que* importa nesta frase específica, e *por que* aquela frase existe no primeiro lugar. Esse é o problema no qual trabalhamos na Glossia, e acho que é o mais interessante do espaço atualmente.

## Três elementos, dois que controlamos

Quando olho para o que é necessário para habilitar uma abordagem genuinamente nova para conteúdo monolíngue e multilíngue, vejo três elementos:

1. **Modelos que são bons em línguas.** Ainda não estão totalmente lá, mas estão melhorando rapidamente e estamos apostando nessa tendência. Não precisamos construir um modelo de fundação. Precisamos estar prontos para usá-los bem quando chegarem lá.
2. **Um sistema para modelar e compartilhar o contexto que os agentes precisam.** Essa é a peça que fica entre o modelo e o conteúdo. A camada que captura sua voz, sua terminologia, seu tom, as expectativas de seu público e entrega tudo isso ao agente de forma estruturada.
3. **O contexto que vem dos usuários.** Os seres humanos trazem julgamento, consciência cultural e direção criativa. Nenhum sistema pode substituir completamente isso. Mas um sistema pode tornar fácil capturá-lo e reutilizá-lo.

Dos três, temos dois que controlamos: o sistema em si e como orientamos os usuários a contribuir com contexto e nos ajudar a melhorar o sistema. Acreditamos que acertar em ambos é o que fará do Glossia um destaque em um espaço que rapidamente está enche-se de soluções "apenas conecte um LLM". O sistema é onde precisamos codificar décadas de teoria linguística nos princípios que estão surgindo no mundo agêntico. E a experiência do usuário em torno dele é como garantimos que o contexto certo realmente seja capturado, refinado e retroalimentado no ciclo.

Eugene Nida, um dos fundadores dos estudos modernos de tradução, argumentou que a boa tradução não se trata de correspondência palavra por palavra. Seu conceito de [equivalência dinâmica](https://en.wikipedia.org/wiki/Dynamic_equivalence) afirma que a relação entre o público-alvo e a mensagem traduzida deve se sentir a mesma que a relação entre o público original e a fonte. É uma bela ideia, mas requer compreensão contextual profunda: quem está lendo, que quadro cultural eles trazem, qual era o tom da original. São exatamente desse tipo de coisas que precisam viver em algum lugar onde um modelo possa acessá-las.

## O que precisamos capturar, e como

Uma das primeiras coisas que estamos explorando são quais informações precisam ser capturadas e como estruturá-las para que os agentes possam realmente usá-las. Quanto mais pensamos sobre isso, mais percebemos que isso não era um arquivo de configuração plano ou uma página de configurações. Precisava ser um grafo. Especificamente, um **[grafo acíclico dirigido](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Por que um DAG? Porque **o contexto não é plano**. Sua voz de marca influencia sua terminologia. Sua terminologia molda como você escreve sobre recursos específicos. Suas expectativas do público informam o nível de formalidade, o que, por sua vez, afeta a escolha das palavras. Essas relações possuem direção e hierarquia, e não retornam a si mesmas.

Existem trabalhos anteriores aqui. Grafos de conhecimento têm sido utilizados há anos em sistemas de IA para representar relações estruturadas entre conceitos. Mais recentemente, [grafos de contexto](https://grokipedia.com/page/context-graph) têm estendido essa ideia ao adicionar camadas de contexto dinâmicas, exatamente o tipo de coisa que os agentes precisam para tomar decisões informadas. E no mundo multiagente, [DAGs tornaram-se um padrão fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependências de tarefas e fluxo de informações.

Mas é aqui que está a parte que me emociona: **cada nó neste grafo precisa ser versionado**. Quando você altera a voz da marca, você não deve perder acesso à versão anterior. Quando você atualiza uma entrada de terminologia, o sistema deve saber qual conteúdo foi produzido sob a definição antiga e quais partes podem precisar ser revistas. Isso nos permite otimizar o fluxo de trabalho agêntico para que ele seja acionado apenas para os conteúdos realmente impactados por uma mudança, e não para reprocessar tudo.

## Bidirecional por design

Acreditamos que a relação entre nós de contexto e conteúdo precisa ser direcional, e precisa funcionar em ambas as direções.

Vindo de um lado: você precisa saber como o conteúdo está conectado ao contexto. Quando uma peça de contexto muda (diga, sua voz de marca muda para ser mais casual), quais posts de blog, descrições de produto ou artigos de ajuda foram escritos na versão anterior? São aqueles que precisam ser revistos ou retraduzidos. Este é o **direção direta, do contexto para o conteúdo**.

Do outro lado: quando um linguista examina uma peça de conteúdo e se questiona por que uma escolha específica foi tomada, ele deve poder rastreá-la de volta ao contexto que guiou a decisão. Qual definição de voz estava ativa? Qual regra de terminologia foi aplicada? Isto **rastreabilidade reversa** é o que permite aos humanos entender o que os agentes fizeram e iterar sobre isso com confiança.

A NASA chama isso [rastreamento bidirecional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): a capacidade de seguir uma associação entre entidades em ambas as direções. É um princípio da engenharia de sistemas, e acaba por ser exatamente o que você precisa quando tenta criar um loop de feedback entre contexto linguístico e conteúdo gerado.

Esta qualidade bidirecional é o que torna **refinamento progressivo** possível. Um linguista pode revisar um conteúdo, ver o contexto que o moldou, decidir que a definição de voz precisa de ajuste, e criar esse ajuste. O sistema então sabe exatamente qual outro conteúdo é afetado pela mudança. É um loop apertado, e é profundamente humano.

## Além de um único repositório

Há outra dimensão neste grafo que acho particularmente interessante. **Não pode viver em um único repositório.** O gráfico de contexto precisa ser compartilhável entre projetos e, potencialmente, entre organizações.

Pense nisso: uma empresa tem uma voz de marca. Essa voz se aplica a cada produto, cada site, cada artigo de suporte. Ela não vive em um único repositório. É uma preocupação transversal. Você pode definir sua voz central no nível da organização, e depois aplicar sobrescritas no nível do projeto para um produto ou público específico. Isso é **herança de escopo**, o mesmo padrão a que estamos acostumados em programação, mas aplicado ao contexto linguístico.

E este contexto precisa ser versionado corretamente. Você não pode apenas alterar a definição de voz e apagar a versão anterior. Há muito a aprender sobre como [Git lida com versionamento](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) por meio de armazenamento endereçável por conteúdo e DAGs. O modelo do Git de commits, branches e diffs é fundamentalmente sobre rastrear como as coisas mudam ao longo do tempo, preservando o acesso a todos os estados anteriores. Isso é exatamente o que precisamos para o contexto linguístico.

De fato, acreditamos que uma mudança de voz deve acontecer através de algo a que chamamos de *solicitação de mudança de voz*. Muito como um pull request cria um espaço para discussão sobre mudanças de código, uma solicitação de mudança de voz cria um espaço para discutir mudanças linguísticas. Por que estamos migrando para um tom mais conversacional? Qual o impacto? Que conteúdos serão afetados? Essas são conversas que valem a pena ter antes que a mudança se propague.

## Onde humanos se tornam mais criativos, não menos relevantes

E é aí que as coisas começam a ficar de verdade interessantes. Em vez de eliminar humanos, o que é a narrativa que muitas pessoas defendem quando falam sobre IA, esse sistema **dá aos humanos um papel mais criativo**.

Imagine uma equipe de linguistas e estrategistas de conteúdo em uma sessão discutindo ideias sobre a direção linguística da marca. Eles podem explorar conceitos, debater mudanças de tom, referenciar contexto cultural a que nenhum modelo tem acesso. E então, em vez de atualizar manualmente centenas de arquivos, capturam suas decisões como ajustes ao grafo de contexto. O sistema cuida da propagação.

Ou leve isso um passo adiante: imagine sessões agênticas onde um linguista trabalha com um assistente de IA para explorar ideias linguísticas. "E se tornássemos as mensagens de erro mais empáticas?" O agente simula o impacto, mostra como o contexto atual mudaria e antecipa como o conteúdo atualizado ficaria. O linguista refina, ajusta e, quando está satisfeito, submete um pedido de alteração de contexto. Não seria incrível?

**Isso não é sobre substituir o linguista.** Trata-se de oferecer-lhes melhores ferramentas para fazer o que eles já são ótimos: tomar decisões sobre a linguagem que sejam nuanceadas e culturalmente informadas. O sistema cuida das partes mecânicas (propagação, análise de impacto, consistência), enquanto os humanos focam nas partes criativas (voz, tom, ressonância cultural).

Estou sempre voltando ao que Nida pretendia com a equivalência dinâmica. O objetivo não é a precisão linguística em um sentido mecânico; é sobre criar a mesma relação sentida entre leitor e conteúdo, independentemente do idioma. Isso exige bom gosto, discernimento e consciência cultural. Coisas nas quais os humanos são excepcionalmente bons, e nas quais os modelos ainda lutam. O papel do sistema é assegurar que esses insights humanos sejam capturados, estruturados e reutilizáveis.

## O que vem a seguir

Em uma postagem de acompanhamento, nos aprofundaremos tecnicamente e falaremos sobre o papel que as caixas de areia desempenharão ao habilitar experiências que ainda não foram vistas neste espaço, e por que estamos investindo fortemente em APIs. Há toda uma dimensão em torno do estágio, pré-visualização e teste de alterações linguísticas antes delas ir ao ar, sobre a qual estamos entusiasmados para explorar.

Se qualquer parte disso ressoar com você, seja um linguista frustrado com as ferramentas atuais, um desenvolvedor que lutou com fluxos de localização, ou apenas alguém que pensa profundamente sobre como a linguagem e a tecnologia se cruzam, adorariamos ouvir de você.