%{
  title: "A tradução é a parte fácil",
  slug: "translation-is-the-easy-part",
  summary:
    "Como as conversas sobre idiomas, entrega de software e confiança levaram María José e eu a construir a Glossia.",
  author: "pedro"
}
---

Os idiomas são uma ferramenta importante e subestimada para a acessibilidade e para levar produtos de tecnologia a novos mercados. Quando seu produto se comunica com comunidades cuja língua principal não é inglês, você sinaliza que pensou nelas. Isso pode estabelecer uma conexão muito profunda.

Infelizmente, fazer seu produto e sua marca falarem vários idiomas é algo de que muitas equipes não podem arcar. Elas frequentemente se veem forçadas a escolher duas de três: **qualidade, velocidade e custo**.

Se querem que as traduções acompanhem a entrega de software, podem investir em uma equipe dedicada para manter a qualidade, mas isso tem um custo. Ou podem depender mais da tradução automática, encurtando o caminho mas aceitando menor qualidade. Se escolherem qualidade e baixo custo, confiando em tradução humana sem uma equipe dedicada, geralmente sacrificam a velocidade. Ao longo do processo, acabam com sistemas enredados empurrando e puxando traduções entre seus repositórios e ferramentas de terceiros.

Desde o surgimento [de grandes modelos de linguagem](https://en.wikipedia.org/wiki/Large_language_model), minha esposa, [María José](https://www.linkedin.com/in/mariajosesalmeron/) e eu conversamos bastante sobre se eles poderiam nos ajudar a parar de fazer essas trocas. Ela ama idiomas e está profundamente imersa na indústria de localização. Eu sou um construtor.

O Tuist é meu principal trabalho. Quando tentei traduzir o produto e suas superfícies de marketing,descobri que me envolvi com soluções enredadas. Nenhuma delas manteve o ritmo da nossa velocidade de entrega, e algumas levaram a conflitos que eram pesadelos para resolver. Tive a sensação de 'isso está errado' muitas vezes.

## De conversas para o Glossia

Semana após semana, discutíamos novos padrões emergentes em torno das capacidades de modelos de linguagem. Vimos desenvolvedores cada vez mais construindo seus próprios pipelines de tradução. No centro, esses pipelines incentivavam um modelo: idioma de entrada, tradução de saída, e continuar.

Parecia compreensível. É assim que construtores operamos. Mas alguém mais próximo de idiomas e dos processos em torno deles pode ver como pode dar errado, desde inconsistências até o melhor, até traduções erradas no pior.

Os desenvolvedores estão se movendo cada vez mais rápido. Eles não podem desacelerar para introduzir um sistema cujos fluxos de trabalho subjacentes foram projetados muito antes da internet, portados para um navegador e ainda lutam para atender às necessidades de equipes de software.

É assim que a ideia de construir o Glossia começou. De um lado, apostamos em modelos melhorando em idiomas além do inglês e em tradução. De outro, construiríamos um sistema, inicialmente focado em conteúdo de software, que parecia plug and play. Algo rodando em segundo plano, compatível com sua velocidade de entrega, e te dando confiança de que a saída está correta e pronta para produção.

Muitos desenvolvedores tratam a tradução como uma solução de um único prompt. Alguns tokens, inglês para entrada, tradução para saída, e chamar de concluído. Mas quando você conversa com eles, percebe que eles não sabem se a saída é precisa, captura a voz da organização em aquele idioma, ou comunica a mensagem pretendida efetivamente.

Tenho um pipeline similar no Tuist, traduzindo para idiomas como japonês, e faço isso com uma enorme falta de confiança. Linguagens não são lógica. Podemos escrever testes para garantir que o formato está correto, mas isso não nos diz **se as palavras estão certas**.

“Traduzir é a parte fácil,” como minha esposa gosta de dizer.

Então, embarcamos em descobrir como o sistema correto deveria parecer. Chamamos de Glossia, e estamos começando a abri-lo para pessoas e organizações interessadas em ajudar-nos a iterar sobre ele juntos.

## Decidir o que traduzir

O primeiro aspecto em que nos focamos foi ajudar as pessoas a decidirem o que traduzir. O custo de tradução está descendo e continuará descendo, mas nunca será zero. As organizações ainda devem ser seletivas sobre os idiomas em que investem.

Às vezes, essa escolha segue diretamente de uma decisão de negócios. Outras vezes, as equipes têm uma ideia vaga de suas comunidades e fazem uma estimativa informada. Pensamos que há muito o que aprender com as pessoas que visitam seus sites ou usam seus aplicativos. Suas preferências de idioma, combinadas com informações sobre as regiões de onde usam seus produtos, podem te dar uma base melhor para essas decisões.

O primeiro recurso que lançamos no Glossia foi a análise. Adicione uma linha de código ao seu site e a análise começa a fluir para sua conta. Apresentamos essas informações em torno da decisão que você precisa tomar: quais idiomas você deve investir a seguir?

No futuro, exploraremos como trazer experimentos para a dimensão de idioma de um produto. Imagine medir com que frequência as pessoas clicam em uma chamada para ação quando uma página usa vozes diferentes no mesmo idioma. Isso não seria legal? Comparar variantes tradicionalmente girou em torno de decisões de produto e design, mas idiomas também são parte do produto.

## Do zero à tradução

Uma vez que você decidiu traduzir um projeto, o próximo passo é configurá-lo. Como desenvolvedor, rejeito processos que trazem muita fricção. Concordamos que ir do zero à tradução deve idealmente levar um passo. É o nível de experiência pelo qual buscamos.

A configuração geralmente envolve duas coisas. Primeiro, extrair o conteúdo do repositório para que ele possa ser traduzido, pois geralmente começa como strings literais no código. Segundo, configurar o projeto para escolher o conteúdo correto com base no idioma. Isso pode vir do dispositivo do usuário ou, em casos mais sofisticados, uma preferência que escolheram.

Automatizar isso de forma confiável há alguns anos teria sido um pesadelo. As coisas mudaram e os agentes podem ser bastante eficazes nisso.

O processo é assim: você conecta seu repositório GitHub, seleciona os idiomas para os quais deseja traduzir e, após algum tempo, um pull request se abre com as alterações. Uma vez que você o mescla, as traduções começam a acontecer. É isso.

Mantemos as traduções no repositório, ao lado das verificações de formato e outras validações que você já executa como parte do [continuous integration](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). O pipeline de tradução alimenta os resultados dessas verificações de volta ao agente de tradução. Isso elimina uma classe inteira de problemas em que uma plataforma abre um pull request e deixa você lidar com verificações que falharam ou conflitos de mesclagem.

Juntado com outros mecanismos para construir confiança, isso é o que torna possível mesclar traduções automaticamente. É o modelo em que acreditamos. Há pouco valor em pedir a um desenvolvedor para verificar se um pull request de tradução está verde e clicar em um botão, especialmente quando ele mesmo não pode avaliar o idioma. Sempre vimos essa cerimônia extra como um sinal de que o design poderia ser melhor.

Acreditamos que o melhor sistema de tradução é aquele que funciona sem que você precise pensar nele.

## Traduzindo apenas o que mudou

O sistema de tradução merece uma seção própria. Os tokens ainda não são gratuitos. Traduzir tudo o tempo todo é lento, caro e desperdiça recursos.

Para resolver isso, criamos um sistema de lock file que nos diz se algo precisa de tradução. Chamamos isso de **tradução incremental**. A ideia não é nova: sistemas de build a utilizam há muito tempo para evitar recompilar tudo em cada build. Adaptamos isso para idiomas.

O sistema considera todo o contexto que afeta uma tradução específica. Parte desse contexto vive no repositório. A outra parte vive no Glossia e abrange múltiplos repositórios. Construímos uma árvore de dependência e usamos [Merkle trees](https://en.wikipedia.org/wiki/Merkle_tree) para calcular hashes que nos dizem se as entradas de uma tradução mudaram.

O lock file preserva essa árvore. Pode explicar por que algo foi enviado para tradução, ou por que não, em vez de deixar as pessoas adivinhando.

[`L10N.md`](/docs/reference/l10n-md) arquivos fornecem contexto de localização para nossos agentes de tradução, muito como `AGENTS.md` arquivos fornecem instruções para agentes de codificação. Eles suportam contexto mais específico em diretórios aninhados, bem como sobreposições de idioma em todos os níveis.

Para informações que se aplicam a mais de um repositório, como terminologias compartilhadas, o servidor é a fonte da verdade. O sistema garante que use o contexto correto e reflita-o no lock file. Quando esse contexto muda, podemos mapear a alteração de volta às traduções que a usaram e precisam ser atualizadas.

## Construindo confiança nas palavras

O sistema é projetado para convergir para um nível de qualidade. Para chegar lá, temos várias ferramentas.

A primeira são verificações adversariais executadas após a tradução. Pense em um colega revisando o código que você incluiu em um pull request. Aqui, as verificações trazem conhecimento linguístico para a revisão. Por exemplo, uma tradução não deve adicionar ou remover significado da fonte. Isso pode acontecer porque os modelos de linguagem nem sempre produzem a mesma saída a partir das mesmas entradas.

À medida que aprendemos mais com nossos usuários e com nossa própria pesquisa sobre modelos e sistemas existentes, adicionaremos mais verificações automatizadas ao pipeline. Cada uma deve aumentar a confiança que você possa ter em uma tradução.

A ideia é chegar a um ponto em que você confie no sistema o suficiente para não sentir a necessidade de revisar cada pull request. Essa confiança depende tanto do sistema quanto dos modelos. Podemos ajudar a escolher modelos com base no idioma-alvo, porque não todos são igualmente bons nos mesmos idiomas.

Mesmo com essas verificações em vigor, você pode precisar alterar uma peça traduzida. Pode ser uma correção pontual, terminologia que ainda não foi escrita no contexto, ou um dos muitos cenários que ainda encontraremos.

Alguém deve poder contribuir com essas alterações diretamente para o repositório. Mas também acreditamos que o sistema deve processar essas contribuições como feedback e sugerir como reconciliá-las com seu contexto. Isso pode significar adicionar um termo ao glossário ou ajustar a voz.

Isso é algo que um ser humano pode fazer assincronamente, sem interromper a tradução contínua. O sistema deve ajudar você a torná-lo mais eficaz em seu trabalho aprendendo com o que as pessoas têm a dizer. Poderíamos estender isso para que as pessoas sugiram feedback diretamente do produto. Isso não seria legal?

Essas correções também precisam ser levadas em conta para que traduções futuras não as sobrescrevam. Uma chamada de tradução sem estado não tem conhecimento das alterações feitas pelas pessoas antes dela. Em sistemas tradicionais, as memórias de tradução ajudam a preencher esse papel. A necessidade que atendem não desaparece apenas porque a tecnologia muda.

## Para onde vamos daqui

Isso é o Glossia. Já o usamos para traduzir o Glossia e estou trabalhando em configurá-lo para traduzir a documentação, o site de marketing e o painel do Tuist nos idiomas de nossas comunidades.

María José e eu estamos construindo o Glossia em nosso tempo livre, seguindo uma curiosidade que faz parte de nossas conversas há anos.

Na programação, muitas pessoas estão questionando o papel dos programadores e como ele evoluirá. Acredito que a indústria de localização se beneficiaria de questionar suas pressuposições e modelos da mesma maneira. Como podemos ajudar nossa indústria a traduzir mais, mais rápido e a menor custo, sem comprometer a qualidade?

Ainda não temos respostas para todas as perguntas. Mas acreditamos que estamos indo na direção certa, com a simplicidade e atenção ao ofício que gostamos de aplicar em tudo o que fazemos.

Se isso ressoar com você, [Vamos conversar](mailto:pedro@glossia.ai).
