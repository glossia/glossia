%{
  title: "A tradução é a parte fácil",
  slug: "translation-is-the-easy-part",
  summary:
    "Como conversas sobre línguas, entrega de software e confiança levaram María José e eu a construir Glossia.",
  author: "pedro"
}
---
As línguas são uma ferramenta excelente e pouco valorizada para acessibilidade e para levar produtos de tecnologia a novos mercados. Quando seu produto se comunica com comunidades cujos idiomas principais não são o inglês, você sinaliza que as considerou. Isso pode estabelecer uma conexão muito profunda.

Infelizmente, fazer seu produto e sua marca se comunicar em vários idiomas é algo de que muitas equipes não se dão ao luxo. Elas frequentemente se veem tendo que escolher dois de três: **qualidade, velocidade e custo**,

Se quiserem que as traduções acompanhem o ritmo da entrega de software, podem investir em uma equipe dedicada para manter a qualidade, mas isso implica um custo. Ou podem confiar mais na tradução automática, avançando rápido, mas aceitando qualidade menor. Se escolherem qualidade e baixo custo, dependendo de tradução humana sem equipe dedicada, geralmente sacrificam a velocidade. Ao longo disso, acabam com sistemas intrincados empurrando e puxando traduções entre seus repositórios e ferramentas de terceiros.

Desde [modelos de linguagem de grande porte](https://en.wikipedia.org/wiki/Large_language_model) emergiram, minha esposa, [María José](https://www.linkedin.com/in/mariajosesalmeron/), e conversamos bastante sobre se eles poderiam nos ajudar a parar de fazer esses trade-offs. Ela ama idiomas e está profundamente integrada na indústria de localização. Eu sou um construtor.

Tuist é meu principal trabalho. Quando tentei traduzir o produto e suas superfícies de marketing, me vi lidando com soluções convolutas. Nenhuma delas acompanhava nosso ritmo de entrega, e algumas levavam a conflitos que eram um pesadelo para resolver. Passei por aquele momento de "isso me parece errado" muitas vezes.

## Das conversas para o Glossia

Toda semana, discutíamos novos padrões emergentes em torno das capacidades dos modelos de linguagem. Vimos cada vez mais desenvolvedores construindo seus próprios pipelines de tradução. No fundo, esses pipelines baseavam-se em um modelo: idioma de entrada, tradução para saída, e então continuar.

Parecia compreensível. É assim que operamos os construtores. Mas alguém mais próximo dos idiomas e dos processos em torno deles poderia ver como isso poderia dar errado, desde inconsistências no mínimo para traduções erradas no máximo.

Os desenvolvedores estão cada vez mais rápidos. Eles não podem parar para introduzir um sistema cujos fluxos de trabalho subjacentes foram projetados muito antes da internet, transferiram para um navegador e ainda lutam para atender às necessidades das equipes de software.

Foi assim que a ideia de construir o Glossia começou. De um lado, apostamos que os modelos ficariam melhores em idiomas além do inglês e na tradução. De outro, construiríamos um sistema, inicialmente focado em conteúdo de software, que parecia plug and play. Algo rodando em segundo plano, alinhando sua velocidade de entrega e dando a você a confiança de que a saída está correta e pronta para produção.

Muitos desenvolvedores tratam a tradução como uma solução de um único prompt. Eles inserem alguns tokens, inglês para dentro, tradução para fora, e consideram feito. Mas, ao conversar com eles, percebe-se que geralmente não sabem se a saída é precisa, reflete a voz da organização deles naquele idioma, ou transmite a mensagem pretendida de forma eficaz.

Tenho um pipeline similar na Tuist, traduzindo para idiomas como o japonês, e faço isso com uma enorme falta de confiança. Idiomas não são lógica. Podemos escrever testes para garantir que o formato está correto, mas isso não nos diz **se as palavras estão certas**.

“A tradução é a parte fácil,” como minha esposa gosta de dizer.

Então, embarcamos em descobrir o que o sistema ideal poderia parecer. Chamamos de Glossia e começamos a abri-lo para pessoas e organizações interessadas em nos ajudar a melhorar o sistema em conjunto.

## Decidir o que traduzir

O primeiro ponto em que nos concentramos foi ajudar as pessoas a decidir o que traduzir. O custo da tradução está diminuindo e continuará diminuindo, mas nunca será zero. As organizações ainda devem ser seletivas sobre os idiomas em que investem.

Às vezes, essa escolha segue diretamente de uma decisão de negócio. Outras vezes, as equipes têm uma noção aproximada de suas comunidades e fazem uma suposição educada. Pensávamos que havia muito o que aprender com as pessoas que visitam seus sites ou usam seus aplicativos. Suas preferências de idioma, combinadas com informações sobre as regiões de onde utilizam seus produtos, podem dar uma base melhor para essas decisões.

A primeira funcionalidade que implementamos no Glossia foi a análise. Adicione uma linha de código ao seu site e as análises começam a fluir para sua conta. Apresentamos essas informações em torno da decisão que você precisa tomar: em quais idiomas você deve investir a seguir?

No futuro, exploraremos como trazer experimentos para a dimensão do idioma de um produto. Imagine medir com que frequência as pessoas clicam em um chamado para ação quando uma página usa diferentes vozes no mesmo idioma. Não seria legal? Comparar variantes tradicionalmente concentra-se em decisões de produto e design, mas os idiomas também fazem parte do produto.

## Do zero para a tradução

Assim que você decide traduzir um projeto, o próximo passo é configurá-lo. Como desenvolvedor, não gosto de processos que trazem muito atrito. Concordamos que ir do zero para a tradução deve idealmente levar apenas um passo. Esse é o nível de experiência que buscamos.

A configuração geralmente envolve duas coisas. Primeiro, extrair o conteúdo do repositório para que possa ser traduzido, pois frequentemente começa como strings literais no código. Segundo, configurar o projeto para selecionar o conteúdo correto com base no idioma. Isso pode vir do dispositivo do usuário ou, em casos mais avançados, uma preferência que eles escolheram.

Automatizar isso de forma confiável há alguns anos teria sido um pesadelo. As coisas mudaram, e os agentes podem ser bastante eficazes nisso.

O processo funciona assim: você conecta seu repositório GitHub, seleciona os idiomas para os quais deseja traduzir e, após algum tempo, um pull request abre com as alterações. Assim que você faz o merge, as traduções começam a ocorrer. Foi tudo.

Manteremos as traduções no repositório, ao lado das verificações de formato e outras validações que você já executa como parte da [inegração contínua](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). O pipeline de tradução devolve os resultados dessas verificações de volta ao agente de tradução. Isso elimina uma classe inteira de problemas em que uma plataforma abre uma pull request e deixa você lidar com verificações falhas ou conflitos de mesclagem.

Combinado com outros mecanismos para construir confiança, isso é o que torna possível mesclar traduções automaticamente. Isso é o modelo em que acreditamos. Não há muito valor em pedir a um desenvolvedor que verifique se uma pull request de tradução está verde e clique em um botão, especialmente quando eles não podem avaliar o idioma sozinhos. Sempre consideramos esse ritual extra como um sinal de que o design poderia ser melhor.

Acreditamos que o melhor sistema de tradução é aquele que funciona sem você ter que pensar nele.

## Traduzindo apenas o que mudou

O sistema de tradução merece sua própria seção. Tokens ainda não são gratuitos. Traduzir tudo o tempo todo é lento, caro e um desperdício de recursos.

Para resolver isso, criamos um sistema de arquivos de bloqueio que nos diz se algo precisa de tradução. Chamamos isso **tradução incremental**. A ideia não é nova: sistemas de compilação já a utilizam há muito tempo para evitar a recompilação de tudo em cada compilação. Nós a adaptamos para idiomas.

O sistema leva em conta todo o contexto que afeta uma determinada tradução. Parte desse contexto vive no repositório. Parte vive no Glossia e abrange múltiplos repositórios. Nós construímos uma árvore de dependências e usamos [árvores de Merkle](https://en.wikipedia.org/wiki/Merkle_tree) para calcular hashes que indicam se as entradas de uma tradução mudaram.

O arquivo de bloqueio preserva essa árvore. Ele pode explicar por que algo foi enviado para tradução, ou por que não foi, em vez de deixar as pessoas adivinhando.

[`L10N.md`](/docs/reference/l10n-md) arquivos fornecem contexto de localização aos nossos agentes de tradução, muito como `AGENTS.md` os arquivos fornecem instruções aos agentes de codificação. Eles suportam contexto mais específico em diretórios aninhados, bem como substituições de idioma em cada nível.

Para informações que se aplicam a mais de um repositório, como terminologia compartilhada, o servidor é a fonte da verdade. O sistema garante que ele use o contexto certo e reflita-o no lockfile. Quando esse contexto muda, podemos mapear a mudança de volta às traduções que o usaram e precisam ser atualizadas.

## Construindo confiança nas palavras

O sistema foi projetado para convergir em direção a um nível de qualidade. Para chegar lá, temos várias ferramentas.

A primeira são verificações adversariais que rodam após a tradução. Pense em um colega revisando o código que você incluiu em um pull request. Aqui, as verificações trazem conhecimento linguístico para a revisão. Por exemplo, uma tradução não deve adicionar ou remover significado da fonte. Isso pode acontecer porque os modelos de linguagem nem sempre produzem a mesma saída das mesmas entradas.

À medida que aprendemos mais de nossos usuários e nossas próprias pesquisas sobre modelos e sistemas existentes, vamos adicionar mais verificações automatizadas ao pipeline. Cada uma deve aumentar a confiança que você tem em uma tradução.

A ideia é chegar a um ponto em que você confie suficientemente no sistema para não sentir a necessidade de passar por cada pull request. Essa confiança depende tanto do sistema quanto dos modelos. Podemos ajudar a escolher modelos baseado no idioma alvo, porque nem todos os modelos são igualmente bons nos mesmos idiomas.

Mesmo com essas verificações em vigor, você pode precisar alterar um trecho traduzido. Pode ser uma correção pontual, um termo de terminologia que ainda não foi inserido no contexto ou um dos muitos cenários que ainda podem surgir.

Alguém deveria ser capaz de contribuir diretamente com essas alterações ao repositório. Mas também achamos que o sistema deve processar essas contribuições como feedback e sugerir como conciliá-las com seu contexto. Isso pode significar adicionar um termo ao glossário ou ajustar a voz.

Isso é algo que um humano pode fazer assincronamente, sem interromper a tradução contínua. O sistema deve ajudá-lo a ser mais eficaz no seu trabalho aprendendo o que as pessoas têm a dizer. Poderíamos estender isso para que as pessoas sugiram feedback diretamente do produto. Não seria legal?

Essas correções também precisam ser consideradas para que futuras traduções não as sobreponham. Uma chamada de tradução sem estado não tem conhecimento das alterações realizadas anteriormente. Em sistemas tradicionais, as memórias de tradução ajudam a preencher esse papel. A necessidade que atendem não desaparece apenas porque a tecnologia muda.

## Onde vamos a partir daqui

Esta é a Glossia. Já a usamos para traduzi-la e estou trabalhando para configurá-la para traduzir a documentação do Tuist, o site de marketing e o painel nas línguas das nossas comunidades.

María José e eu estamos construindo a Glossia em nosso tempo livre, seguindo uma curiosidade que faz parte das nossas conversas há anos.

Na programação, muitas pessoas estão questionando o papel dos programadores e como ele evoluirá. Acredito que a indústria de localização se beneficiaria de um questionamento similar das suas suposições e modelos. Como podemos ajudar nossa indústria a traduzir mais, de forma mais rápida e com menor custo, sem comprometer a qualidade?

Ainda não temos respostas para todas as perguntas. Mas acreditamos que estamos no caminho certo, com a simplicidade e cuidado que dedicamos a tudo o que fazemos.

Se isso ressoa com você, [vamos conversar](mailto:pedro@glossia.ai).