%{
  title: "A tradução é a parte fácil",
  slug: "translation-is-the-easy-part",
  summary:
    "Como as conversas sobre idiomas, entrega de software e confiança levaram María José e mim a construir o Glossia.",
  author: "pedro"
}
---

Idiomas são uma excelente e pouco valorizada ferramenta para acessibilidade e para levar produtos de tecnologia a novos mercados. Quando seu produto se dirige a comunidades cuja língua principal não é o inglês, você sinaliza que as considerou. Isso pode estabelecer uma conexão muito profunda.

Infelizmente, fazer seu produto e marca falarem vários idiomas é algo que muitas equipes não podem pagar. Elas muitas vezes se veem tendo que escolher dois dos três: **qualidade, velocidade e custo**.

Se eles quiserem que as traduções acompanhem a entrega de software, podem investir em uma equipe dedicada para manter a qualidade, mas isso tem um custo. Ou podem depender mais da tradução automática, avançando rápido, mas aceitando qualidade menor. Se escolherem qualidade e baixo custo, dependendo de tradução humana sem uma equipe dedicada, geralmente sacrificam a velocidade. No caminho, acabam com sistemas complexos empurrando e puxando traduções entre seus repositórios e ferramentas de terceiros.

Desde que os [grandes modelos de linguagem](https://en.wikipedia.org/wiki/Large_language_model) emergiram, minha esposa, [María José](https://www.linkedin.com/in/mariajosesalmeron/), e eu conversamos bastante sobre se eles poderiam nos ajudar a parar de fazer essas concessões. Ela adora idiomas e está profundamente envolvida na indústria de localização. Sou um construtor.

Tuist é minha principal ocupação. Quando tentei traduzir o produto e suas superfícies de marketing, me vi lidando com soluções convolutas. Nenhum deles se manteve ao passo com nossa velocidade de entrega, e alguns levaram a conflitos que eram um pesadelo para resolver. Eu tive esse momento de 'isto parece errado' muitas vezes.

## ## De conversas para o Glossia

Toda semana, discutíamos novos padrões emergentes ao redor das capacidades de modelos de linguagem. Vimos cada vez mais desenvolvedores criando seus próprios pipelines de tradução. No essencial, esses pipelines acionavam um modelo: idioma fonte entra, tradução sai, depois continue.

Parecia compreensível. É assim que nós, construtores, operamos. Mas alguém mais próximo dos idiomas e dos processos ao redor deles poderia ver como poderia dar errado, desde inconsistências no melhor até traduções erradas no pior.

Devolvedores estão acelerando cada vez mais. Eles não podem desacelerar para introduzir um sistema cujos fluxos de trabalho subjacentes foram projetados muito antes da internet, movidos para um navegador e ainda lutam para atender às necessidades de equipes de software.

É assim que a ideia de construir o Glossia começou. De um lado, apostávamos em modelos ficando melhores em idiomas outros que o inglês e em tradução. De outro, construiríamos um sistema, inicialmente focado em conteúdo de software, que parecia ser plug-and-play. Algo rodando ao fundo, igualando sua velocidade de entrega e dando confiança de que a saída está certa e pronta para produção.

Muitos desenvolvedores tratam a tradução como uma solução de um único prompt. Alguns tokens, inglês entra, tradução sai, e pronto. Mas quando você conversa com eles, percebe que eles não sabem se a saída é precisa, captura a voz de sua organização nesse idioma, ou comunica a mensagem pretendida efetivamente.

Tenho um pipeline similar no Tuist, traduzindo para idiomas como o japonês, e faço isso com uma enorme falta de confiança. Idiomas não são lógica. Podemos escrever testes para garantir que o formato está correto, mas isso não nos diz **se as palavras estão certas**.

“A tradução é a parte fácil,” como minha esposa gosta de dizer.

Então nos dedizamos a descobrir o que o sistema certo poderia parecer. Chamamos isso de Glossia, e estamos começando a abri-lo para pessoas e organizações interessadas em nos ajudar a iterar juntas nele.

## ## Decidir o que traduzir

A primeira parte em que nos focamos foi ajudar as pessoas a decidir o que traduzir. O custo da tradução está descendo e continuará descendo, mas nunca será zero. As organizações ainda devem ser seletivas sobre os idiomas em que investem.

Às vezes essa escolha segue diretamente de uma decisão de negócios. Outas vezes, as equipes têm uma ideia vaga de suas comunidades e fazem uma suposição informada. Pensávamos que havia muito para aprender com as pessoas que visitam seus sites ou usam seus aplicativos. Suas preferências de idioma, combinadas com informações sobre as regiões a partir das quais usam seus produtos, podem lhe dar uma base melhor para essas decisões.

A primeira funcionalidade que lançamos no Glossia foi a análise. Adicione uma linha de código ao seu site, e as análises começam a fluir para sua conta. Apresentamos essas informações ao redor da decisão que você precisa tomar: em quais idiomas você deve investir a seguir?

A long prazo, exploraremos como trazer experimentos para a dimensão de idioma de um produto. Imagine medir com que frequência as pessoas clicam em uma chamada para ação quando uma página usa vozes diferentes no mesmo idioma. Não seria legal? Comparar variantes tradicionalmente girou ao redor de decisões de produto e design, mas os idiomas fazem parte do produto também.

## ## Do zero para a tradução

Uma vez que decidiu traduzir um projeto, o próximo passo é configurar. Como desenvolvedor, não gosto de processos que trazem muita fricção. Acordamos que ir do zero para a tradução deveria idealmente levar apenas um passo. É o nível de experiência no qual buscamos.

A configuração geralmente envolve duas coisas. Primeiro, extrair o conteúdo do repositório para que possa ser traduzido, já que geralmente começa como strings literais no código. Segundo, configurar o projeto para escolher o conteúdo certo com base no idioma. Isso pode vir do dispositivo do usuário ou, em casos mais sofisticados, uma preferência escolhida por eles.

Automatizar isso confiavelmente alguns anos atrás teria sido um pesadelo. As coisas mudaram, e os agentes podem ser bastante efetivos nisso.

O processo se passa assim: você conecta seu repositório do GitHub, seleciona os idiomas para os quais quer traduzir e, depois de um tempo, um pull request abre com as alterações. Uma vez que o mescla, as traduções começam a acontecer. É só isso.

Mantemos as traduções no repositório, ao lado das verificações de formato e outras validações que você já executa como parte de [integração contínua](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). O pipeline de tradução devolve os resultados dessas verificações ao agente de tradução. Isso elimina uma classe inteira de problemas em que uma plataforma abre um pull request e deixa você lidar com verificações falhadas ou conflitos de mesclagem.

Combinado com outros mecanismos para construir confiança, isso é o que torna possível mesclar traduções automaticamente. Esse é o modelo em que acreditamos. Não há grande valor em pedir para um desenvolvedor verificar se um pull request de tradução está no verde e clicar em um botão, especialmente quando ele não consegue avaliar o idioma por conta própria. Sempre enxergamos essa cerimônia extra como um sinal de que o design poderia ser melhor.

Acreditamos que o melhor sistema de tradução é aquele que funciona sem você ter que pensar sobre ele.

## Traduzindo apenas o que mudou

O sistema de tradução merece sua própria seção. Tokens ainda não são grátis. Traduzir tudo o tempo todo é lento, caro e desperdiça recursos.

Para resolver isso, criamos um sistema de arquivo de bloqueio que nos diz se algo precisa ser traduzido. Chamamos isso de **tradução incremental**. A ideia não é nova: sistemas de compilação já usam isso há muito tempo para evitar recompilar tudo a cada build. Adaptamos isso para idiomas.

O sistema leva em conta todo o contexto que afeta uma tradução específica. Parte desse contexto vive no repositório. Parte vive no Glossia e abrange múltiplos repositórios. Criamos uma árvore de dependência e usamos [árvores Merkle](https://en.wikipedia.org/wiki/Merkle_tree) para calcular hashes que nos dizem se as entradas de uma tradução mudaram.

O arquivo de bloqueio preserva essa árvore. Ele pode explicar por que algo foi enviado para tradução, ou por que não foi, em vez de deixar as pessoas adivinhando.

[`L10N.md`](/docs/reference/l10n-md) arquivos fornecem contexto de localização para nossos agentes de tradução, muito como `AGENTS.md` arquivos fornecem instruções para agentes de codificação. Eles suportam mais contexto específico em diretórios aninhados, além de substituições de idioma em todos os níveis.

Para informações que se aplicam a mais de um repositório, como terminologia compartilhada, o servidor é a fonte da verdade. O sistema garante que ele usa o contexto certo e o reflete no arquivo de bloqueio. Quando esse contexto muda, podemos mapear a mudança de volta para as traduções que o usaram e precisam ser atualizadas.

## Aprendendo confiança nas palavras

O sistema é projetado para convergir para um nível de qualidade. Para chegar lá, temos várias ferramentas.

A primeira são verificações adversariais que rodam após a tradução. Pense em um colega revisando o código que você incluiu em um pull request. Aqui, as verificações trazem conhecimento linguístico para a revisão. Por exemplo, uma tradução não deve adicionar ou remover significado da fonte. Isso pode acontecer porque modelos de linguagem nem sempre produzem a mesma saída a partir das mesmas entradas.

À medida que aprendemos mais com nossos usuários e nossa própria pesquisa em modelos e sistemas existentes, adicionaremos mais verificações automatizadas ao pipeline. Cada uma delas deve aumentar a confiança que você pode ter em uma tradução.

A ideia é chegar a um ponto em que você confie no sistema lo suficiente a ponto de não sentir a necessidade de revisar cada pull request. Essa confiança depende tanto do sistema quanto dos modelos. Podemos ajudar a escolher modelos com base no idioma alvo, porque não todos os modelos são igualmente bons para os mesmos idiomas.

Mesmo com essas verificações em vigor, você pode precisar alterar uma peça traduzida. Pode ser uma correção pontual, terminologia que ainda não foi escrita no contexto ou um dos muitos cenários com os quais ainda precisamos lidar.

Alguém deve poder contribuir com essas alterações diretamente para o repositório. Mas também achamos que o sistema deve processar essas contribuições como feedback e sugerir como conciliá-las com o contexto. Isso pode significar adicionar um termo ao glossário ou ajustar a voz.

Isso é algo que um humano pode fazer assincronamente, sem interromper a tradução contínua. O sistema deve ajudá-lo a torná-lo mais eficaz em seu trabalho aprendendo com o que as pessoas dizem. Poderíamos estender isso para as pessoas sugerindo feedback diretamente no produto. Não seria legal?

Essas correções também precisam ser levadas em conta para que futuras traduções não as sobrescrevam. Uma chamada de tradução stateless não tem conhecimento das alterações feitas pelas pessoas antes dela. Em sistemas tradicionais, as memórias de tradução ajudam a preencher esse papel. A necessidade que elas servem não desaparece apenas porque a tecnologia muda.

## Onde vamos a partir daqui

Esse é o Glossia. Já o usamos para traduzir o Glossia, e estou trabalhando em configurá-lo para traduzir a documentação, o site de marketing e o painel da Tuist para os idiomas de nossas comunidades.

María José e eu estamos construindo o Glossia em nosso tempo livre, seguindo uma curiosidade que faz parte de nossas conversas há anos.

Na programação, muitas pessoas estão questionando o papel dos programadores e como ele evoluirá. Acho que o setor de localização se beneficiaria de uma revisão similar de suas pressuposições e modelos. Como podemos ajudar nosso setor a traduzir mais, mais rápido e a um custo menor, sem comprometer a qualidade?

Ainda não temos respostas para todas as perguntas. Mas acreditamos que estamos indo na direção certa, com a simplicidade e atenção ao ofício que gostamos de colocar em tudo o que fazemos.

Se isso ressoar com você, [vamos conversar](mailto:pedro@glossia.ai).
