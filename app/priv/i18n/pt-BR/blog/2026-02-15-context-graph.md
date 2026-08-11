%{
  title: "O grafo de contexto: codificando décadas de teoria linguística para a era dos agentes",
  summary: "Os modelos de linguagem são poderosos, mas precisam do contexto adequado para produzir conteúdo de alta qualidade. Estamos desenvolvendo um grafo direcionado e versionado para registrar conhecimento linguístico e compartilhá-lo com agentes, e acreditamos que isso diferenciará a Glossia.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Tenho refletido muito sobre o que diferencia um conteúdo que parece gerado por máquina de um conteúdo que parece ter sido escrito por alguém que compreende o público, a marca e as nuances culturais por trás de cada palavra. A resposta sempre retorna ao mesmo ponto: **contexto**.

Os modelos de linguagem estão cada vez melhores no uso de diferentes idiomas, e apostamos na continuidade dessa evolução. Eles ainda não atingiram todo o seu potencial, mas é difícil ignorar o ritmo de aprimoramento. O que ainda falta, porém, é o sistema que fica entre o modelo e o conteúdo. Algo que informe ao modelo *quem* você é, *como* você se comunica, *o que* importa nesta frase específica e *por que* essa frase existe. Esse é o problema no qual estamos trabalhando na Glossia, e acredito que seja o mais interessante dessa área neste momento.

## Três elementos, dois sob nosso controle

Quando analiso o que é necessário para viabilizar uma abordagem realmente nova para conteúdos monolíngues e multilíngues, identifico três elementos:

1. **Modelos com bom domínio de idiomas.** Eles ainda não atingiram todo o seu potencial, mas estão evoluindo rapidamente, e apostamos nessa tendência. Não precisamos desenvolver um modelo fundacional. Precisamos estar preparados para utilizá-los bem quando estiverem prontos.
2. **Um sistema para modelar e compartilhar o contexto necessário aos agentes.** Essa é a parte que fica entre o modelo e o conteúdo. É a camada que registra sua voz, terminologia, tom e expectativas do público, e disponibiliza tudo isso ao agente de forma estruturada.
3. **O contexto fornecido pelos usuários.** As pessoas contribuem com discernimento, consciência cultural e direcionamento criativo. Nenhum sistema pode substituir isso por completo. No entanto, um sistema pode facilitar o registro e a reutilização desse contexto.

Desses três elementos, há dois sob nosso controle: o próprio sistema e a forma como orientamos os usuários a fornecer contexto e a nos ajudar a aprimorá-lo. Acreditamos que acertar em ambos é o que fará a Glossia se destacar em um mercado que rapidamente se enche de soluções do tipo "basta conectar um modelo de linguagem de grande escala". É no sistema que precisamos codificar décadas de teoria linguística nos elementos fundamentais que estão surgindo no universo dos agentes. A experiência do usuário que o acompanha é o que garante que o contexto adequado seja efetivamente registrado, refinado e reincorporado ao ciclo.

Eugene Nida, um dos fundadores dos estudos modernos da tradução, argumentava que uma boa tradução não se resume à correspondência palavra por palavra. Seu conceito de [equivalência dinâmica](https://en.wikipedia.org/wiki/Dynamic_equivalence) afirma que a relação entre o público-alvo e a mensagem traduzida deve produzir uma experiência equivalente à relação entre o público original e o texto de origem. É uma ideia elegante, mas que exige uma compreensão contextual profunda: quem está lendo, qual é sua perspectiva cultural e qual tom o texto original pretendia transmitir. Esses são exatamente os tipos de informação que precisam estar disponíveis em algum lugar acessível ao modelo.

## O que precisamos registrar e como

Uma das primeiras questões que começamos a explorar foi quais informações precisam ser registradas e como estruturá-las para que os agentes possam utilizá-las de forma efetiva. Quanto mais refletíamos sobre isso, mais percebíamos que não se tratava de um arquivo de configuração simples nem de uma página de configurações. Precisava ser um grafo. Mais especificamente, um **[grafo acíclico direcionado](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Por que um grafo acíclico direcionado? Porque **o contexto não é plano**. A voz da sua marca influencia sua terminologia. Sua terminologia determina como você escreve sobre funcionalidades específicas. As expectativas do seu público definem o nível de formalidade, que, por sua vez, afeta a escolha das palavras. Essas relações têm direção e hierarquia, e não formam ciclos entre si.

Há precedentes para isso. Grafos de conhecimento são usados há anos em sistemas de inteligência artificial para representar relações estruturadas entre conceitos. Mais recentemente, os [grafos de contexto](https://grokipedia.com/page/context-graph) ampliaram essa ideia ao adicionar camadas dinâmicas de contexto, exatamente o que os agentes precisam para tomar decisões fundamentadas. E, no universo dos sistemas multiagentes, os [grafos acíclicos dirigidos (DAGs) tornaram-se um padrão fundamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) para modelar dependências entre tarefas e o fluxo de informações.

Mas esta é a parte que mais me entusiasma: **cada nó desse grafo precisa ter controle de versão**. Quando a voz da sua marca mudar, você não deve perder o acesso à versão anterior. Quando uma entrada de terminologia for atualizada, o sistema deve saber quais conteúdos foram produzidos com a definição antiga e quais partes talvez precisem ser revisadas. Isso nos permite otimizar o fluxo de trabalho baseado em agentes para que ele seja acionado apenas para as partes realmente afetadas por uma mudança, em vez de reprocessar tudo.

## Bidirecional desde a concepção

Acreditamos que a relação entre os nós de contexto e o conteúdo precisa ter direcionalidade e funcionar nos dois sentidos.

Por um lado, é necessário saber como o conteúdo está conectado ao contexto. Quando parte do contexto muda, por exemplo, quando a voz da sua marca passa a ser mais informal, quais publicações do blog, descrições de produtos ou artigos de ajuda foram escritos com a versão anterior? São esses conteúdos que precisam ser revisados ou traduzidos novamente. Essa é a **direção direta, do contexto para o conteúdo**.

Por outro lado, quando um linguista analisa um conteúdo e se pergunta por que determinada escolha foi feita, ele deve conseguir rastreá-la até o contexto que orientou a decisão. Qual definição de voz estava ativa? Qual regra de terminologia foi aplicada? Essa **rastreabilidade reversa** permite que as pessoas entendam o que os agentes fizeram e aprimorem o processo com confiança.

A Administração Nacional da Aeronáutica e Espaço (NASA) chama isso de [rastreabilidade bidirecional](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): a capacidade de acompanhar uma associação entre entidades em qualquer direção. É um princípio da engenharia de sistemas e, ao que tudo indica, é exatamente o necessário para criar um ciclo de retroalimentação entre o contexto linguístico e o conteúdo gerado.

Essa característica bidirecional é o que torna possível o **refinamento progressivo**. Um linguista pode revisar um conteúdo, consultar o contexto que o definiu, concluir que a definição de voz precisa ser ajustada e criar esse ajuste. O sistema então sabe exatamente quais outros conteúdos foram afetados pela mudança. É um ciclo preciso e profundamente humano.

## Além de um único repositório

Há outra dimensão desse grafo que considero particularmente interessante. **Ele não pode existir em um único repositório.** O grafo de contexto precisa ser compartilhável entre projetos e, possivelmente, entre organizações.

Considere o seguinte: uma empresa tem uma voz de marca. Essa voz se aplica a todos os produtos, sites e artigos de suporte. Ela não pertence a um único repositório. É um aspecto transversal. A voz principal pode ser definida no nível da organização, com substituições aplicadas no nível do projeto para um produto ou público específico. Isso é **herança de escopo**, o mesmo padrão usado em programação, mas aplicado ao contexto linguístico.

Além disso, esse contexto precisa ter um controle de versão adequado. Não basta alterar a definição de voz e eliminar a versão anterior. Há muito a aprender com a forma como o [Git gerencia versões](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) por meio de armazenamento endereçável por conteúdo e grafos acíclicos dirigidos. O modelo de commits, branches e diffs do Git trata essencialmente de acompanhar como as coisas mudam ao longo do tempo, preservando o acesso a todos os estados anteriores. É exatamente disso que precisamos para o contexto linguístico.

Na verdade, acreditamos que uma mudança de voz deva ocorrer por meio do que estamos chamando de *solicitação de alteração de voz*. Assim como uma pull request cria um espaço para discutir alterações no código, uma solicitação de alteração de voz cria um espaço para discutir mudanças linguísticas. Por que estamos adotando um tom mais conversacional? Qual será o impacto? Qual conteúdo será afetado? Essas são conversas importantes que devem acontecer antes que a mudança se propague.

## Onde as pessoas se tornam mais criativas, não menos relevantes

E é aqui que as coisas começam a ficar realmente interessantes. Em vez de eliminar a participação humana, como sugere a narrativa que muitas pessoas promovem ao falar sobre inteligência artificial, esse sistema **oferece às pessoas um papel mais criativo**.

Imagine uma equipe de linguistas e estrategistas de conteúdo em uma sessão para discutir ideias sobre a direção linguística da marca. Eles poderiam explorar conceitos, debater mudanças de tom e considerar contextos culturais aos quais nenhum modelo tem acesso. Em seguida, em vez de atualizar manualmente centenas de arquivos, registrariam suas decisões como ajustes no grafo de contexto. O sistema cuidaria da propagação.

Ou podemos ir além: imagine sessões agênticas nas quais um linguista trabalha com um assistente de inteligência artificial para explorar ideias linguísticas. "E se tornássemos as mensagens de erro mais empáticas?" O agente simula o impacto, mostra como o contexto atual mudaria e apresenta uma prévia de como o conteúdo atualizado poderia ficar. O linguista refina e ajusta o resultado e, quando estiver satisfeito, envia uma solicitação de alteração de contexto. Não seria interessante?

**Não se trata de substituir o linguista.** Trata-se de oferecer ferramentas melhores para que exerça aquilo que já faz muito bem: tomar decisões criteriosas e culturalmente informadas sobre a linguagem. O sistema cuida das partes mecânicas (propagação, análise de impacto e consistência), enquanto as pessoas se concentram nas partes criativas (voz, tom e ressonância cultural).

Continuo voltando ao que Nida propunha com a equivalência dinâmica. O objetivo não é a precisão linguística em um sentido mecânico. Trata-se de criar a mesma relação percebida entre o leitor e o conteúdo, independentemente do idioma. Isso exige sensibilidade, discernimento e consciência cultural. São aspectos nos quais as pessoas são excepcionalmente competentes e com os quais os modelos ainda têm dificuldade. A função do sistema é garantir que essas percepções humanas sejam registradas, estruturadas e reutilizáveis.

## Próximos passos

Em uma publicação futura, entraremos em mais detalhes técnicos e abordaremos o papel que os sandboxes terão na viabilização de experiências ainda inéditas nesse espaço, além dos motivos pelos quais estamos investindo fortemente em interfaces de programação de aplicações. Há toda uma dimensão relacionada à preparação, à visualização prévia e ao teste de mudanças linguísticas antes que entrem em produção, e estamos entusiasmados para explorá-la.

Se alguma dessas ideias fizer sentido para você, seja você um linguista insatisfeito com as ferramentas atuais, um desenvolvedor que já enfrentou dificuldades com fluxos de trabalho de localização ou simplesmente alguém que reflete profundamente sobre a interseção entre linguagem e tecnologia, teremos prazer em conversar.