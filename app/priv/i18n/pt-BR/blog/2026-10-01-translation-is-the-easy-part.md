%{
  title: "A tradução é a parte fácil",
  slug: "translation-is-the-easy-part",
  summary:
    "Como conversas sobre idiomas, entrega de software e confiança levaram María José e mim a construir Glossia.",
  author: "pedro"
}
---

Idiomas são uma ferramenta excelente e subestimada para acessibilidade e para levar produtos de tecnologia a novos mercados. Quando seu produto se dirige a comunidades cujo idioma principal não é o inglês, você sinaliza que pensou nelas. Isso pode estabelecer uma conexão muito profunda.

Infelizmente, fazer seu produto e marca falarem vários idiomas é algo com que muitas equipes não conseguem lidar. Elas frequentemente se veem forçadas a escolher dois de três: **qualidade, velocidade e custo**.

Se elas querem que as traduções mantenham o ritmo da entrega de software, podem investir em uma equipe dedicada de pessoas para manter a qualidade, mas isso tem um custo. Ou podem confiar mais fortemente em tradução automática, movendo-se rápido mas aceitando qualidade mais baixa. Se escolherem qualidade e baixo custo, confiando em tradução humana sem uma equipe dedicada, geralmente sacrificam a velocidade. Ao longo do caminho, acabam com sistemas convolutos empurrando e puxando traduções entre seus repositórios e ferramentas de terceiros.

Desde a emergência de [grandes modelos de linguagem](https://en.wikipedia.org/wiki/Large_language_model), minha esposa, [María José](https://www.linkedin.com/in/mariajosesalmeron/), e eu conversamos bastante sobre se eles poderiam nos ajudar a parar de fazer esses tradeoffs. Ela ama idiomas e está profundamente inserida na indústria de localização. Eu sou um construtor.

Tuist é meu trabalho atual. Quando tentei traduzir o produto e suas superfícies de marketing, me deparei com soluções convolutas. Nenhuma delas acompanhou nossa velocidade de entrega, e algumas levaram a conflitos que eram um pesadelo para resolver. Eu vivia o momento de “isso parece errado” muitas vezes.

## De conversas ao Glossia

Toda semana, discutíamos novos padrões emergentes em torno das capacidades de modelos de linguagem. Vimos mais e mais desenvolvedores construindo suas próprias linhas de tradução. No núcleo delas, essas linhas disparam um modelo: idioma de entrada, tradução de saída, e seguir em frente.

Parecia compreensível. É assim que operamos nós construtores. Mas alguém mais próximo dos idiomas e dos processos ao redor deles poderia ver como isso poderia dar errado, desde inconsistências no melhor cenário até erros de tradução no pior cenário.

Os desenvolvedores estão se movendo cada vez mais rápido. Eles não podem desacelerar para introduzir um sistema cujos fluxos de trabalho subjacentes foram projetados muito antes da internet, transferidos para um navegador e ainda lutam para atender às necessidades de equipes de software.

Foi assim que a ideia de construir o Glossia começou. De um lado, apostávamos em modelos melhorando em idiomas outros que o inglês e em tradução. De outro, construiríamos um sistema, inicialmente focado em conteúdo de software, que parecia plug and play. Algo rodando em segundo plano, correspondendo à sua velocidade de entrega e dando confiança de que a saída está correta e pronta para produção.

Muitos desenvolvedores tratam a tradução como uma solução de um único prompt. Alguns tokens, inglês de entrada, tradução de saída, e pronto. Mas quando você conversa com eles, percebe que eles não sabem se a saída é precisa, captura a voz da organização deles naquele idioma, ou comunica a mensagem pretendida eficazmente.

Eu tenho uma pipeline similar no Tuist, traduzindo para idiomas como o japonês, e faço isso com uma enorme falta de confiança. Idiomas não são lógica. Podemos escrever testes para garantir que o formato esteja correto, mas isso não nos diz **se as palavras estão corretas**.

“A tradução é a parte fácil,” como minha esposa gosta de dizer.

Então nos embarcamos em descobrir como o sistema certo poderia parecer. Chamamos isso de Glossia, e estamos começando a abri-lo para pessoas e organizações interessadas em nos ajudar a iterar nele juntas.

## Decidindo o que traduzir

A primeira parte em que nos concentramos foi ajudar pessoas a decidirem o que traduzir. O custo da tradução está diminuindo e continuará diminuindo, mas nunca será zero. Organizações ainda devem ser seletivas sobre os idiomas em que investem.

Às vezes, essa escolha segue diretamente de uma decisão de negócios. Outras vezes, as equipes têm uma ideia vaga de suas comunidades e fazem uma suposição informada. Acreditamos que havia muito a aprender com as pessoas que visitam seus sites ou usam seus aplicativos. Suas preferências de idioma, combinadas com informações sobre as regiões de onde usam seus produtos, podem dar uma base melhor para essas decisões.

O primeiro recurso que implementamos no Glossia foi a análise. Adicione uma linha de código ao seu site e a análise começa a fluir para sua conta. Apresentamos essas informações em torno da decisão que você precisa tomar: em quais idiomas você deve investir a seguir?

A longo prazo, exploraremos como trazer experimentos para a dimensão de linguagem de um produto. Imagine medir com que frequência as pessoas clicam em uma chamada para ação (call to action) quando uma página usa vozes diferentes no mesmo idioma. Não seria legal? Comparar variantes tradicionalmente gravitou em torno de decisões de produto e design, mas idiomas também fazem parte do produto.

## De zero a tradução

Uma vez que você decidiu traduzir um projeto, o próximo passo é configurá-lo. Como desenvolvedor, eu detesto processos que trazem muita fricção. Concordamos que ir de zero a tradução deveria idealmente levar um passo. É o nível de experiência para o qual nos esforçamos.

A configuração geralmente envolve duas coisas. Primeiro, extrair o conteúdo do repositório para que possa ser traduzido, já que geralmente começa como strings literais no código. Segundo, configurar o projeto para escolher o conteúdo certo baseado no idioma. Isso pode vir do dispositivo do usuário ou, em casos mais sofisticados, uma preferência que escolheram.

Automatizar isso de forma confiável há alguns anos teria sido um pesadelo. As coisas mudaram, e os agentes podem ser bastante eficazes nisso.

O processo funciona assim: você conecta seu repositório GitHub, seleciona os idiomas para os quais deseja traduzir e, depois de um tempo, uma pull request abre com as alterações. Assim que você faz o merge, as traduções começam a acontecer. É só isso.

Nós mantemos as traduções no repositório, juntamente com as verificações de formato e outras validações que você já executa como parte da [integração contínua](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). O pipeline de tradução devolve os resultados dessas verificações de volta para o agente de tradução. Isso elimina uma classe inteira de problemas em que uma plataforma abre um pull request e te deixa lidar com verificações falhas ou conflitos de merge.

Combinado com outros mecanismos para construir confiança, isso é o que torna possível fazer o merge de traduções automaticamente. Esse é o modelo no qual acreditamos. Há pouco valor em pedir a um desenvolvedor para verificar se um pull request de tradução está verde e clicar em um botão, especialmente quando eles não podem avaliar a linguagem sozinhos. Sempre vi essa cerimônia extra como um sinal de que o design poderia ser melhor.

Acreditamos que o melhor sistema de tradução é aquele que funciona sem você precisar pensar nisso.

## Traduzindo apenas o que mudou

O sistema de tradução merece sua própria seção. Os tokens ainda não são gratuitos. Traduzir tudo o tempo todo é lento, caro e um desperdício de recursos.

Para resolver isso, construímos um sistema de lock file que nos diz se algo precisa de tradução. Chamamos isso de **tradução incremental**. A ideia não é nova: sistemas de build a usaram há muito tempo para evitar recompilar tudo em cada build. Adaptamos isso para linguagens.

O sistema leva em consideração todo o contexto que afeta uma tradução particular. Parte desse contexto mora no repositório. Outra parte reside no Glossia e abrange vários repositórios. Construímos uma árvore de dependência e usamos [árvores de Merkle](https://en.wikipedia.org/wiki/Merkle_tree) para calcular hashes que nos dizem se as entradas de uma tradução mudaram.

O lock file preserva essa árvore. Ele pode explicar por que algo foi enviado para tradução, ou por que não, em vez de deixar as pessoas adivinhando.

Os [`L10N.md`](/docs/reference/l10n-md) fornecem contexto de localização para nossos agentes de tradução, muito como `AGENTS.md` fornecem instruções para agentes de codificação. Eles suportam contexto mais específico em diretórios aninhados, bem como sobrescritas de idioma em todos os níveis.

Para informações que se aplicam a mais de um repositório, como terminologia compartilhada, o servidor é a fonte da verdade. O sistema garante que usa o contexto certo e reflete isso no lock file. Quando esse contexto muda, podemos mapear a mudança de volta às traduções que o utilizaram e precisam ser atualizadas.

## Construindo confiança nas palavras

O sistema é projetado para convergir para um nível de qualidade. Para chegar lá, temos várias ferramentas.

A primeira são verificações adversariais que são executadas após a tradução. Imagine um colega revisando o código que você incluiu em um pull request. Aqui, as verificações trazem conhecimento linguístico para a revisão. Por exemplo, uma tradução não deve adicionar ou remover significado da fonte. Isso pode acontecer porque os modelos de linguagem nem sempre produzem a mesma saída das mesmas entradas.

À medida que aprendemos mais com nossos usuários e nossa própria pesquisa em modelos e sistemas existentes, adicionaremos mais verificações automatizadas ao pipeline. Cada uma deve aumentar a confiança que você pode ter em uma tradução.

A ideia é chegar a um ponto onde você confia no sistema o suficiente para não sentir a necessidade de revisar cada pull request. Essa confiança depende tanto do sistema quanto dos modelos. Podemos ajudar a escolher modelos com base no idioma-alvo, porque nem todos os modelos são igualmente bons nos mesmos idiomas.

Mesmo com essas verificações em vigor, você pode precisar alterar uma peça traduzida. Pode ser uma correção única, terminologia que ainda não foi escrita no contexto ou um dos muitos cenários que ainda precisamos enfrentar.

Alguém deveria ser capaz de contribuir para essas mudanças diretamente para o repositório. Mas também achamos que o sistema deveria processar essas contribuições como feedback e sugerir como reconciliá-las com seu contexto. Isso pode significar adicionar um termo ao glossário ou ajustar a voz.

Isso é algo que um humano pode fazer de forma assíncrona, sem interromper a tradução contínua. O sistema deve ajudar você a torná-lo mais eficaz em sua tarefa ao aprender o que as pessoas têm a dizer. Poderíamos estender isso para pessoas sugerindo feedback diretamente do produto. Não seria legal?

Essas correções também precisam ser levadas em conta para que traduções futuras não as sobrescrevam. Uma chamada de tradução sem estado não tem conhecimento das mudanças feitas pelas pessoas antes dela. Em sistemas tradicionais, memórias de tradução ajudam a preencher esse papel. A necessidade que elas atendem não desaparece apenas porque a tecnologia muda.

## A partir daqui

Isso é o Glossia. Já o usamos para traduzir o Glossia, e estou trabalhando para configurá-lo para traduzir a documentação, o site de marketing e o dashboard da Tuist para os idiomas de nossas comunidades.

María José e eu estamos construindo o Glossia em nosso tempo livre, seguindo uma curiosidade que tem sido parte de nossas conversas por anos.

No programação, muitas pessoas estão questionando o papel dos programadores e como ele evoluirá. Acredito que a indústria de localização se beneficiaria de um questionamento similar de suas pressuposições e modelos. Como podemos ajudar nossa indústria a traduzir mais, mais rápido e a um custo menor, sem comprometer a qualidade?

Ainda não temos respostas para todas as perguntas. Mas acreditamos que estamos indo na direção certa, com a simplicidade e atenção ao ofício que gostamos de aplicar em tudo o que fazemos.

Se isso ressoa com você, [vamos conversar](mailto:pedro@glossia.ai).
