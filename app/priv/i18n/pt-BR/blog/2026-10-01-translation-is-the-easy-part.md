%{
  title: "A tradução é a parte fácil",
  slug: "translation-is-the-easy-part",
  summary:
    "Como conversas sobre idiomas, entrega de software e confiança levaram María José e eu a construir Glossia.",
  author: "pedro"
}
---

Os idiomas são uma ferramenta excelente e pouco valorizada para acessibilidade e para levar produtos de tecnologia a novos mercados. Quando seu produto fala com comunidades cuja língua principal não é o inglês, você sinaliza que pensou neles. Isso pode estabelecer uma conexão muito profunda.

Infelizmente, fazer seu produto e sua marca falarem vários idiomas é algo onde muitas equipes não podem investir. Elas muitas vezes se vêem tendo que escolher duas das três: **qualidade, velocidade e custo**.

Se eles querem que as traduções se mantenham ao passo com a entrega de software, podem investir em uma equipe dedicada de pessoas para manter a qualidade, mas isso vem a um custo. Ou podem depender mais da tradução automática, movendo-se rápido mas aceitando menor qualidade. Se eles escolherem qualidade e baixo custo, dependendo de tradução humana sem uma equipe dedicada, geralmente sacrificam a velocidade. Ao longo do caminho, acabam com sistemas convolutos empurrando e puxando traduções entre seus repositórios e ferramentas de terceiros.

Desde [modelos de linguagem grandes](https://en.wikipedia.org/wiki/Large_language_model) surgiram, minha esposa, [María José](https://www.linkedin.com/in/mariajosesalmeron/), e eu conversamos bastante sobre se eles poderiam ajudar a pararmos de fazer essas concessões. Ela ama línguas e está profundamente imersa no setor de localização. Sou um construtor.

Tuist é meu trabalho principal. Quando tentei traduzir o produto e suas superfícies de marketing, me vi lidando com soluções convolutas. Nenhuma delas se manteve com a nossa velocidade de entrega, e algumas levaram a conflitos que eram um pesadelo para resolver. Eu tive aquele momento de “isso parece errado” muitas vezes.

## De conversas para Glossia

Toda semana, discutíamos novos padrões emergentes em torno das capacidades de modelos de linguagem. Vimos cada vez mais desenvolvedores construindo seus próprios pipelines de tradução. No seu centro, esses pipelines acionavam um modelo: idioma de origem entra, tradução sai, e depois continua.

Parecia compreensível. É assim que nós construtores operamos. Mas alguém mais próximo das línguas e dos processos ao redor delas podia ver como poderia dar errado, de inconsistências no melhor dos casos a traduções errôneas no pior dos casos.

Desenvolvedores estão se movendo cada vez mais rápido. Eles não podem desacelerar para introduzir um sistema cujos fluxos de trabalho subjacentes foram projetados muito antes da internet, transferidos para um navegador, e ainda lutam para atender às necessidades de equipes de software.

Foi assim que a ideia de construir Glossia começou. De um lado, apostaríamos em modelos ficando melhores em idiomas além do inglês e na tradução. Do outro, construiríamos um sistema, inicialmente focado em conteúdo de software, que parecia ser plug and play. Algo funcionando ao fundo, correspondendo à sua velocidade de entrega, e dando confiança de que a saída está correta e pronta para a produção.

Muitos desenvolvedores tratam a tradução como uma solução de um único prompt. Alguns tokens, inglês entra, tradução sai, e chamar de concluído. Mas quando conversam com eles, você percebe que eles não sabem se a saída é precisa, captura a voz de sua organização naquele idioma, ou comunica a mensagem desejada efetivamente.

Tenho um pipeline similar na Tuist, traduzindo para idiomas como o japonês, e faço isso com uma enorme falta de confiança. Línguas não são lógica. Podemos escrever testes para garantir que o formato está correto, mas isso não nos diz **se as palavras estão corretas**.

«A tradução é a parte fácil,» como minha esposa gosta de dizer.

Então embarcamos em descobrir o que o sistema certo poderia parecer. Chamamos de Glossia, e estamos começando a abrir para pessoas e organizações interessadas em nos ajudar a iterar sobre isso juntas.

## Decidir o que traduzir

O primeiro ponto no qual nos concentramos foi ajudar as pessoas a decidirem o que traduzir. O custo da tradução está descendo e continuará a descer, mas nunca será zero. As organizações ainda devem ser seletivas sobre os idiomas em que investem.

Às vezes, essa escolha segue diretamente de uma decisão de negócios. Outras vezes, as equipes têm uma ideia vaga de suas comunidades e fazem uma suposição educada. Pensamos que havia muito a aprender com as pessoas que visitam seus sites ou usam seus aplicativos. Suas preferências de idioma, combinadas com informações sobre as regiões onde usam seus produtos, podem lhes dar uma melhor base para essas decisões.

A primeira característica que aterrissamos na Glossia foi a analítica. Adicione uma linha de código ao seu site, e a analítica começa a fluir para sua conta. Apresentamos essas informações em torno da decisão que precisa tomar: para quais idiomas você deve investir a seguir?

A longo prazo, exploraremos como trazer experimentos para a dimensão linguística de um produto. Imagine medir com que frequência as pessoas clicam em um chamado para ação quando uma página usa vozes diferentes no mesmo idioma. Isso não seria legal? Comparar variantes tradicionalmente gravitou em torno de decisões de produto e design, mas os idiomas são parte do produto também.

## Do zero para tradução

Uma vez que você decidiu traduzir um projeto, o próximo passo é definí-lo. Como um desenvolvedor, desgosto de processos que vêm com muita fricção. Concordamos que ir do zero para a tradução deve idealmente levar um passo. Esse é o nível de experiência para o qual tendemos.

Configurar geralmente envolve duas coisas. Primeiro, extrair o conteúdo do repositório para que ele possa ser traduzido, já que muitas vezes começa como strings literais no código. Segundo, configurar o projeto para escolher o conteúdo certo com base no idioma. Isso pode vir do dispositivo do usuário ou, em casos mais sofisticados, uma preferência que ele escolheu.

Automatizar isso confiavelmente há anos teria sido um pesadelo. As coisas mudaram, e os agentes podem ser bastante eficazes nisso.

O processo segue assim: você conecta seu repositório GitHub, seleciona os idiomas para os quais deseja traduzir e, após um tempo, um pull request se abre com as mudanças. Uma vez que você o mescla, as traduções começam a acontecer. Isso é tudo.

Armazenamos as traduções no repositório, ao lado das verificações de formato e outras validações que você já executa como parte da [integração contínua](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). O pipeline de tradução alimenta os resultados dessas verificações de volta para o agente de tradução. Isso remove toda uma classe de problemas em que uma plataforma abre um pull request e deixa você lidar com verificações falhas ou conflitos de mesclagem.

Combinado com outros mecanismos para construir confiança, isso é o que torna possível mesclar traduções automaticamente. É o modelo em que acreditamos. Não há muito valor em pedir a um desenvolvedor para verificar se um pull request de tradução está verde e clicar em um botão, especialmente quando ele não consegue avaliar o idioma por si só. Sempre vimos essa cerimônia extra como um sinal de que o design poderia ser melhor.

Acreditamos que o melhor sistema de tradução é aquele que funciona sem você ter que pensar sobre isso.

## Traduzindo apenas o que mudou

O sistema de tradução merece sua própria seção. Tokens ainda não são gratuitos. Traduzir tudo o tempo todo é lento, caro e um desperdício de recursos.

Para resolver isso, criamos um sistema de arquivo de bloqueio que nos diz se algo precisa ser traduzido. Chamamos isso de **tradução incremental**. A ideia não é nova: sistemas de compilação já têm um longo tempero usando isso para evitar recompilar tudo em cada build. Adaptamos isso para idiomas.

O sistema leva em consideração todo o contexto que afeta uma tradução específica. Parte desse contexto vive no repositório. Outra parte vive na Glossia e abrange múltiplos repositórios. Criamos uma árvore de dependência e usamos [árvores de Merkle](https://en.wikipedia.org/wiki/Merkle_tree) para calcular hashes que nos dizem se as entradas de uma tradução mudaram.

O arquivo de bloqueio preserva essa árvore. Ele pode explicar por que algo foi enviado para tradução, ou por que não foi, em vez de deixar as pessoas adivinhando.

[`L10N.md`](/docs/reference/l10n-md) arquivos fornecem contexto de localização a nossos agentes de tradução, muito como `AGENTS.md` arquivos fornecem instruções a agentes de codificação. Eles suportam contextos mais específicos em diretórios aninhados, bem como substituições de idioma em cada nível.

Para informações que se aplicam a mais de um repositório, como terminologia compartilhada, o servidor é a fonte da verdade. O sistema garante que usa o contexto correto e reflete isso no arquivo de bloqueio. Quando esse contexto muda, mapeamos a alteração de volta para as traduções que a usaram e precisam ser atualizadas.

## Construindo confiança nas palavras

O sistema é projetado para convergir em direção a um nível de qualidade. Para chegar lá, temos várias ferramentas.

A primeira são verificações adversariais que rodam após a tradução. Pense em um colega revisando o código que você incluiu em um pull request. Aqui, as verificações trazem conhecimento linguístico para a revisão. Por exemplo, uma tradução não deve adicionar ou remover significado da fonte. Isso pode acontecer porque modelos de linguagem nem sempre produzem a mesma saída com as mesmas entradas.

À medida que aprendemos mais com nossos usuários e nossas próprias pesquisas sobre modelos e sistemas existentes, adicionaremos mais verificações automatizadas ao pipeline. Cada uma deve aumentar a confiança que você pode ter em uma tradução.

A ideia é chegar a um ponto onde você confiança o suficiente no sistema para não sentir necessidade de passar por cada pull request. Essa confiança depende tanto do sistema quanto dos modelos. Podemos ajudar a selecionar modelos com base no idioma alvo, porque nem todos os modelos são igualmente bons nos mesmos idiomas.

Mesmo com essas verificações em vigor, você pode precisar alterar uma peça traduzida. Pode ser uma correção única, terminologia que ainda não foi escrita no contexto, ou uma das muitas situações com as quais ainda nos deparar.

Alguém deve ser capaz de contribuir essas alterações diretamente para o repositório. Mas também achamos que o sistema deve processar essas contribuições como feedback e sugerir como reconciliá-las com seu contexto. Isso pode significar adicionar um termo ao glossário ou ajustar a voz.

Isso é algo que um humano pode fazer assincronamente, sem interromper a tradução contínua. O sistema deve ajudar você a torná-lo mais eficaz no trabalho dele, aprendendo com o que as pessoas têm a dizer. Poderíamos estender isso para pessoas sugerirem feedback diretamente do produto. Isso não seria legal?

Essas correções também precisam ser consideradas para que traduções futuras não as sobrescrevam. Uma chamada de tradução sem estado não tem conhecimento das alterações que as pessoas fizerem antes dela. Em sistemas tradicionais, as memórias de tradução ajudam a preencher esse papel. A necessidade que atendem não desaparece apenas porque a tecnologia muda.

## Para onde vamos daqui

Isso é Glossia. Já a usamos para traduzir a Glossia, e estou trabalhando para configurá-la para traduzir a documentação, o site de marketing e o painel da Tuist para os idiomas de nossas comunidades.

María José e eu estamos construindo a Glossia em nosso tempo livre, seguindo uma curiosidade que tem sido parte de nossas conversas por anos.

Na programação, muitas pessoas estão questionando o papel dos programadores e como ele evoluirá. Penso que a indústria de localização se beneficiaria de um questionamento similar de suas suposições e modelos. Como podemos ajudar nossa indústria a traduzir mais, mais rápido e a um custo menor, sem comprometer a qualidade?

Ainda não temos respostas para todas as perguntas. Mas acreditamos que estamos indo na direção certa, com a simplicidade e atenção ao ofício que gostamos de derramar em tudo o que fazemos.

Se isso ressoar com você, [vamos conversar](mailto:pedro@glossia.ai).
