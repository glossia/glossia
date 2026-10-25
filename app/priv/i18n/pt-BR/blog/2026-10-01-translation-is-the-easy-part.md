%{
  title: "A tradução é a parte fácil",
  slug: "translation-is-the-easy-part",
  summary:
    "Como conversas sobre idiomas, entrega de software e confiança levaram María José e mim a criar o Glossia.",
  author: "pedro"
}
---

Idiomas são uma ferramenta excelente e pouco apreciada para acessibilidade e para levar produtos de tecnologia a novos mercados. Quando seu produto fala com comunidades cuja língua principal não é o inglês, você sinaliza que pensou nelas. Isso pode estabelecer uma conexão muito profunda.

Infelizmente, fazer seu produto e sua marca falarem em vários idiomas é algo que muitas equipes não podem arcar. Elas muitas vezes se veem à procura de escolher dois de três: **qualidade, velocidade e custo**.

Se elas querem que as traduções mantenham o ritmo da entrega de software, podem investir em uma equipe dedicada para manter a qualidade, mas isso tem um custo. Ou podem confiar mais no tradutor automático, avançando rápido mas aceitando qualidade menor. Se escolherem qualidade e baixo custo, confiam na tradução humana sem uma equipe dedicada, geralmente sacrificando velocidade. Ao longo do caminho, elas acabam com sistemas complicados empurrando e puxando traduções entre seus repositórios e ferramentas de terceiros.

Desde o surgimento dos [grandes modelos de linguagem](https://en.wikipedia.org/wiki/Large_language_model), minha esposa, [María José](https://www.linkedin.com/in/mariajosesalmeron/), e eu conversamos bastante sobre se eles poderiam ajudar a pararmos de fazer esses compromissos. Ela ama idiomas e está profundamente imersa na indústria de localização. Eu sou um construtor.

Tuist é a minha principal ocupação. Quando tentei traduzir o produto e suas superfícies de marketing, encontrei-me lidando com soluções complicadas. Nenhuma delas mantinha o ritmo da nossa velocidade de entrega, e algumas levavam a conflitos que eram um pesadelo para resolver. Eu tive aquele momento de "isso parece errado" muitas vezes.

## ## Das conversas para Glossia

Toda semana, discutíamos novos padrões emergentes em torno das capacidades de modelos de linguagem. Vimos cada vez mais desenvolvedores construindo seus próprios pipelines de tradução. No seu núcleo, esses pipelines instavam um modelo: idioma de entrada, tradução de saída, e depois siga.

Parecia compreensível. É assim que nós, construtores, operamos. Mas alguém mais próximo de idiomas e dos processos ao redor deles poderia ver como isso poderia dar errado, de inconsistências no mínimo até más traduções no máximo.

Desenvolvedores estão se movendo cada vez mais rápido. Eles não podem desacelerar para introduzir um sistema cujos fluxos de trabalho subjacentes foram projetados muito antes da internet, migraram para um navegador e ainda lutam para atender às necessidades de equipes de software.

É assim que começou a ideia de criar Glossia. De um lado, apostamos que os modelos ficariam melhores em idiomas além do inglês e na tradução. Do outro, criaríamos um sistema, inicialmente focado em conteúdo de software, que se sentisse plug-and-play. Algo rodando ao fundo, combinando com sua velocidade de entrega e dando a você a confiança de que a saída está correta e pronta para produção.

Muitos desenvolvedores tratam a tradução como uma solução de um-prompt. Alguns tokens, inglês para dentro, tradução para fora, e pronto. Mas quando você conversa com eles, percebe que eles não sabem se a saída é precisa, captura a voz da organização deles naquele idioma ou comunica a mensagem pretendida de forma eficaz.

Tenho um pipeline similar na Tuist, traduzindo para idiomas como o japonês, e faço isso com uma enorme falta de confiança. Idiomas não são lógica. Podemos escrever testes para garantir que o formato esteja correto, mas isso não nos diz **se as palavras estão corretas**.

“A tradução é a parte fácil,” como minha esposa gosta de dizer.

Então nos aventuramos a descobrir como o sistema ideal poderia se parecer. Chamamos de Glossia, e estamos começando a abri-lo para pessoas e organizações interessadas em ajudar a iterar sobre ele junto.

## ## Decidindo o que traduzir

A primeira peça na qual focamos foi ajudar as pessoas a decidir o que traduzir. O custo da tradução está diminuindo e continuará diminuindo, mas nunca será zero. Organizações ainda devem ser seletivas sobre os idiomas nas quais investem.

Às vezes, essa escolha segue diretamente de uma decisão de negócios. Outras vezes, equipes têm uma ideia vaga de suas comunidades e fazem uma avaliação educada. Acreditamos que havia muito o que aprender com as pessoas que visitam seus sites ou usam seus aplicativos. Suas preferências de idioma, combinadas com informações sobre as regiões a partir das quais usam seus produtos, podem te dar uma base melhor para essas decisões.

A primeira funcionalidade que implementamos na Glossia foi análises. Adicione uma linha de código ao seu site, e a análise começa a fluir para sua conta. Apresentamos essas informações em torno da decisão que você precisa tomar: quais idiomas você deve investir a seguir?

No futuro, exploraremos como trazer experimentos para a dimensão de idioma de um produto. Imagine medir com que frequência as pessoas clicam em uma chamada para ação quando uma página usa vozes diferentes no mesmo idioma. Não seria legal? Comparar variantes tradicionalmente se concentrou em torno de decisões de produto e design, mas idiomas também fazem parte do produto.

## ## Da zero à tradução

Assim que você decide traduzir um projeto, o próximo passo é configurá-lo. Como desenvolvedor, odeio processos que vêm com muito atrito. Combinamos que ir da zero à tradução deve, idealmente, levar um passo. É esse o nível de experiência que buscamos.

A configuração geralmente envolve duas coisas. Primeiro, extrair o conteúdo do repositório para que ele possa ser traduzido, uma vez que muitas vezes começa como strings literais no código. Segundo, configurar o projeto para escolher o conteúdo certo com base no idioma. Isso pode vir do dispositivo do usuário ou, em casos mais sofisticados, uma preferência que eles escolheram.

Automatizar isso de forma confiável há alguns anos teria sido um pesadelo. As coisas mudaram, e agentes podem ser bastante eficazes nisso.

O processo funciona assim: você conecta seu repositório do GitHub, seleciona os idiomas nos quais quer traduzir e, após algum tempo, um pull request abre com as alterações. Depois que você merge-o, as traduções começam a acontecer. É isso.

Guardamos as traduções no repositório, juntamente com as verificações de formato e outras validações que você já executa como parte da [integração contínua](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). O pipeline de tradução alimenta os resultados dessas verificações de volta ao agente de tradução. Isso elimina uma classe inteira de problemas em que uma plataforma abre um pull request e te deixa para lidar com verificações falhas ou conflitos de merge.

Em combinação com outros mecanismos para construir confiança, é isso que pode permitir o merge das traduções automaticamente. É esse o modelo em que acreditamos. Pouco faz sentido solicitar a um desenvolvedor que verifique se um pull request de tradução está verde e clique em um botão, especialmente quando ele não consegue avaliar o idioma por si mesmo. Sempre consideramos essa cerimônia extra como um sinal de que o design pode ser melhor.

Acreditamos que o melhor sistema de tradução é aquele que funciona sem você ter que pensar nele.

## Traduzindo apenas o que mudou

O sistema de tradução merece sua própria seção. Tokens ainda não são gratuitos. Traduzir tudo o tempo todo é lento, caro e uma perda de recursos.

Para resolver isso, criamos um sistema de arquivo de bloqueio que nos diz se algo precisa ser traduzido. Chamamos isso de **tradução incremental**. A ideia não é nova: sistemas de build a usaram há muito tempo para evitar recompilar tudo a cada build. Adaptamos a ideia para idiomas.

O sistema leva em conta todo o contexto que afeta uma tradução específica. Parte desse contexto vive no repositório. Parte vive na Glossia e se estende por vários repositórios. Construímos uma árvore de dependências e usamos [árvores Merkle](https://en.wikipedia.org/wiki/Merkle_tree) para calcular hashes que nos dizem se as entradas de uma tradução mudaram.

O arquivo de bloqueio preserva essa árvore. Ele pode explicar por que algo foi enviado para tradução, ou por que não foi, em vez de deixar as pessoas adivinhando.

[`L10N.md`](/docs/reference/l10n-md) fornece contexto de localização aos nossos agentes de tradução, assim como `AGENTS.md` fornece instruções aos agentes de codificação. Eles suportam contexto mais específico em diretórios aninhados, bem como sobreposições de idioma em todos os níveis.

Para informações que se aplicam a mais de um repositório, como terminologia compartilhada, o servidor é a fonte da verdade. O sistema garante que use o contexto certo e o reflita no arquivo de bloqueio. Quando esse contexto muda, podemos mapear a alteração de volta às traduções que a usaram e precisam ser atualizadas.

## Construindo confiança nas palavras

O sistema é projetado para convergir para um nível de qualidade. Para chegar lá, temos várias ferramentas.

A primeira são verificações adversariais que rodam após a tradução. Imagine um colega revisando o código que você incluiu em um pull request. Aqui, as verificações trazem conhecimento linguístico para a revisão. Por exemplo, uma tradução não deve adicionar ou remover significado da fonte. Isso pode acontecer porque os modelos de linguagem nem sempre produzem a mesma saída a partir das mesmas entradas.

À medida que aprendemos mais com nossos usuários e nossas próprias pesquisas sobre modelos e sistemas existentes, adicionaremos mais verificações automatizadas ao pipeline. Cada uma deve aumentar a confiança que você pode ter em uma tradução.

A ideia é alcançar um ponto em que você confia o suficiente no sistema a ponto de não sentir a necessidade de revisar cada pull request. Essa confiança depende tanto do sistema quanto dos modelos. Podemos ajudar a escolher modelos com base no idioma de destino, porque nem todos os modelos são igualmente bons nos mesmos idiomas.

Mesmo com essas verificações em vigor, você pode precisar alterar um trecho traduzido. Pode ser uma correção única, terminologia que ainda não foi escrita no contexto, ou um dos muitos cenários que ainda precisamos encontrar.

Alguém deve ser capaz de contribuir com essas alterações diretamente para o repositório. Mas também pensamos que o sistema deve processar essas contribuições como feedback e sugerir como reconciliá-las com seu contexto. Isso pode significar adicionar um termo ao glossário ou ajustar a voz.

Isso é algo que um ser humano pode fazer assincronamente, sem interromper a tradução contínua. O sistema deve ajudar você a torná-lo mais eficaz em seu trabalho aprendendo com o que as pessoas dizem. Poderíamos estender isso para pessoas sugerindo feedback diretamente do produto. Não seria legal?

Essas correções também precisam ser levadas em conta para que traduções futuras não as sobrescrevam. Uma chamada de tradução sem estado não tem conhecimento das alterações que as pessoas fizeram antes dela. Em sistemas tradicionais, memórias de tradução ajudam a desempenhar esse papel. A necessidade que elas atendem não desaparece só porque a tecnologia muda.

## Onde vamos daqui para frente

Essa é a Glossia. Já a usamos para traduzir a Glossia, e estou trabalhando na configuração para traduzir a documentação do Tuist, o site de marketing e o painel para os idiomas de nossas comunidades.

María José e eu estamos construindo a Glossia em nossos horários livres, seguindo uma curiosidade que faz parte de nossas conversões há anos.

Na programação, muitas pessoas estão questionando o papel dos programadores e como ele irá evoluir. Acredito que a indústria de localização se beneficiaria de um questionamento semelhante de suas pressuposições e modelos. Como podemos ajudar nossa indústria a traduzir mais, mais rápido e a um custo menor, sem comprometer a qualidade?

Ainda não temos respostas para todas as perguntas. Mas acreditamos que estamos indo na direção certa, com a simplicidade e atenção ao ofício que gostaríamos de aplicar a tudo o que fazemos.

Se isso ressoa com você, [vamos conversar](mailto:pedro@glossia.ai).
