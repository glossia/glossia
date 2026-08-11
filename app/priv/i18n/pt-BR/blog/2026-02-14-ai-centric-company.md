%{
  title: "Construindo uma empresa centrada em IA para desafiar um setor que não consegue se reinventar",
  summary: "As empresas de localização estabelecidas têm capital, mas não a liberdade para inovar. Estamos projetando a Glossia do zero em torno de IA e agentes, não apenas no produto, mas também na forma como administramos toda a empresa.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Modelos de linguagem de grande escala e agentes estão transformando tudo. Não apenas o que o software pode fazer, mas também como as empresas são estruturadas para criar esse software. Na [Glossia](https://glossia.ai), vemos isso como uma oportunidade única em uma geração para repensar como o conteúdo chega a todos os idiomas. Mas também sabemos que uma boa ideia de produto não é suficiente. É necessária uma organização capaz de avançar com rapidez suficiente para fazer a diferença.

É sobre essa segunda parte que trata este artigo.

## O dilema da inovação em tempo real

O setor de localização é grande e bem financiado. Empresas como Smartling, Phrase, Crowdin e Lokalise desenvolvem ferramentas e serviços há anos. Elas têm clientes, receita, fluxos de trabalho consolidados e equipes que sabem como vender e oferecer suporte aos seus produtos.

Então, por que uma equipe de duas pessoas sequer tentaria?

Por causa de algo que Clayton Christensen descreveu em [O Dilema da Inovação](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): empresas estabelecidas têm dificuldade para adotar inovações disruptivas não porque lhes faltam recursos, mas porque seus modelos de negócios existentes, as expectativas de seus clientes e suas estruturas organizacionais as impedem de fazer isso.

Essas empresas desenvolveram seus produtos em torno de memórias de tradução, cobrança por palavra e fluxos de trabalho com tradutores humanos. Seus clientes estruturaram modelos mentais e processos com base nesses elementos fundamentais. Mudar essa base significa romper compromissos com clientes existentes, capacitar novamente as equipes e repensar os modelos de receita. Mesmo com as melhores intenções e capital para investir, a inércia organizacional é enorme.

Elas precisam de capacidade de inovação e do comprometimento de sua força de trabalho para adotar novas ideias. Mas, ainda mais difícil, precisam que seus clientes atuais acompanhem essa mudança. E esses clientes investiram no modelo antigo.

Essa é a oportunidade que identificamos. Não apesar de termos menos recursos, mas justamente por causa disso. Não temos um legado a proteger, fluxos de trabalho a preservar nem clientes a migrar. Podemos projetar tudo do zero.

> [!NOTE]
> O dilema da inovação não diz respeito à tecnologia. Diz respeito a incentivos. Empresas estabelecidas otimizam seus produtos para atender ao que os clientes atuais desejam, o que torna quase impossível buscar algo fundamentalmente diferente.

## Inteligência artificial no centro, não nas margens

A maioria das empresas adota inteligência artificial como um complemento aos processos existentes. Um chatbot aqui, um mecanismo de sugestões ali. Estamos seguindo na direção oposta: projetando toda a empresa para ser centrada em inteligência artificial desde o primeiro dia.

Isso significa que a inteligência artificial não é um recurso do produto. Ela determina como desenvolvemos, vendemos, oferecemos suporte e operamos. Toda decisão que tomamos começa com uma pergunta: um agente pode fazer isso?

O próprio produto é um agente que reside no seu terminal, lê seus arquivos de origem, gera traduções, executa suas verificações de integração contínua e repete o processo até que o resultado seja aprovado. Essa é a parte que as pessoas veem. Mas, nos bastidores, a mesma filosofia orienta a empresa.

## Duas pessoas, nenhuma sobrecarga organizacional

Mantemos deliberadamente a equipe tão pequena quanto possível. No momento, somos apenas duas pessoas. Nosso objetivo é permanecer com duas ou três pessoas pelo máximo de tempo possível.

Não se trata de economizar dinheiro, embora isso ajude. Trata-se de eliminar toda uma categoria de trabalho que não gera valor para os usuários.

Quanto mais pessoas são adicionadas, maior é a necessidade de coordenação. É preciso criar sistemas de confiança, modelos de permissão e cadeias de aprovação. É preciso administrar conflitos, alinhar prioridades e agendar reuniões. Tudo isso consome energia criativa na manutenção de uma organização humana, em vez de direcioná-la ao desenvolvimento de um produto.

Com duas pessoas, eliminamos tudo isso. Confiamos plenamente um no outro. Temos acesso a tudo. Não há sobrecarga, política interna nem processos criados apenas para justificar outros processos.

Para que isso funcione em escala, delegamos todas as demais tarefas a agentes.

## Discord, um agente de inteligência artificial e uma única linha de comando

Aqui está algo que pode soar incomum: nossa principal interface de negócios é um servidor do [Discord](https://discord.com).

Temos um agente de inteligência artificial conectado a ele, desenvolvido com a [OpenAI](https://openai.com), com acesso a todas as ferramentas necessárias para operar a empresa. Em vez de alternarmos entre painéis web, plataformas de análise e painéis administrativos, conversamos com o agente. Texto e voz são as unidades de interação.

Por meio do agente, qualquer um de nós pode:

- Consultar análises de marketing e produto
- Inspecionar servidores de produção
- Realizar pesquisas de mercado
- Coletar feedback de clientes
- Realizar análises da concorrência por meio da navegação na web
- Elaborar conteúdo, revisar textos e publicar

Nenhum de nós depende do outro para realizar qualquer uma dessas atividades. O agente tem acesso às nossas interfaces de programação de aplicações, aos bancos de dados e às ferramentas de monitoramento. Ele pode navegar na web, ler a documentação e sintetizar informações. É um servidor do Discord, uma instância da OpenAI e uma chave de modelo de linguagem de grande porte. Esse é o sistema operacional da empresa.

> [!TIP]
> Se estiver formando uma equipe pequena e quiser reduzir a sobrecarga de coordenação, considere adotar texto e voz como a principal interface para as operações de negócios. Um agente compartilhado em um canal de conversa pode substituir dezenas de painéis e eliminar a necessidade da maioria das ferramentas internas.

## Escolhas tecnológicas deliberadas

Somos muito criteriosos em relação à nossa stack tecnológica, pois ela afeta diretamente a velocidade com que conseguimos avançar e o baixo custo com que podemos operar.

**Para o agente (interface de linha de comando):** escolhemos Go. Ele é compilado em binários únicos e portáteis entre plataformas, sem dependências de ambiente de execução para o usuário.

**Para o servidor:** escolhemos [Elixir](https://elixir-lang.org) e o ambiente de execução do [Erlang](https://www.erlang.org). A natureza funcional do Elixir o torna muito adequado para cargas de trabalho orientadas a agentes. A máquina virtual do Erlang é amplamente comprovada para concorrência e tolerância a falhas. Há ainda uma vantagem adicional: um agente de inteligência artificial pode examinar internamente o sistema Erlang em execução para entender o que está acontecendo, obter informações relevantes e até corrigir problemas em produção.

**Para a infraestrutura:** tudo é executado em um único servidor virtual privado. Isso inclui não apenas o servidor de produção da Glossia, mas também todos os serviços periféricos: [PostgreSQL](https://www.postgresql.org/) para o banco de dados, [Plausible](https://plausible.io) para análises com foco em privacidade e [Grafana](https://grafana.com) para telemetria e observabilidade. Tudo é implantado a partir de definições de infraestrutura controladas por versão que descrevem o que deve ser executado em cada local.

Isso mantém os custos extremamente baixos. Não dependemos de serviços de nuvem de terceiros, bancos de dados gerenciados ou provedores de plataforma como serviço. Temos algumas dependências externas, mas apenas para recursos cuja reprodução levaria muito tempo e cujo custo é justificável.

Quando chegar o momento de distribuir a operação entre vários servidores, evoluiremos o modelo. No entanto, acreditamos que podemos avançar por muito tempo com essa configuração. Neste momento, avançar rapidamente é mais importante do que operar em grande escala.

> [!IMPORTANT]
> Optamos deliberadamente por evitar a complexidade técnica que engenheiros costumam adotar cedo demais. Kubernetes, microsserviços e implantações em várias regiões. Nada disso é necessário nesta fase, e tudo isso reduziria nossa velocidade.

## O que isso viabiliza

Operar a empresa dessa forma não é apenas uma estratégia de eficiência. Isso muda o que podemos oferecer e a velocidade com que podemos aprender.

**Mais acessível para os usuários.** O setor de localização tornou suas ferramentas inacessíveis por meio de preços complexos, cobranças por palavra e ciclos de vendas empresariais. Se o seu fluxo de trabalho de tradução exigir um processo de compras, negociações de preço e um gerente de projetos, a maioria das equipes pequenas simplesmente lançará o produto apenas em inglês. Ao manter nossos custos operacionais próximos de zero, podemos oferecer algo verdadeiramente acessível.

**Inovação mais rápida.** Queremos explorar muitas ideias. Novas interfaces para o agente, ciclos de feedback melhores, novas formas de integrar linguistas ao fluxo de trabalho. Uma empresa tradicional precisaria ampliar a equipe, alinhar os times e agendar revisões do roadmap. Nós simplesmente testamos as ideias. A distância entre uma ideia e um experimento implantado é medida em horas, não em trimestres.

## Questionar como trabalhamos, não apenas o que desenvolvemos

Não temos apego emocional às antigas formas de fazer as coisas. Questionamos ativamente o que significa revisar código quando um agente escreve a maior parte dele. Como funciona a colaboração quando há apenas duas pessoas. Como corrigir um erro quando o agente pode inspecionar o sistema em execução.

Cometemos erros. Continuaremos cometendo. Mas, ao mantermos a mente aberta sobre como projetamos e administramos a empresa, continuamos descobrindo ideias que influenciam o produto. Nossa forma de operar não está separada do que desenvolvemos. São a mesma coisa.

[A McKinsey descreveu recentemente](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) o que chama de "organização agêntica", um novo modelo operacional no qual agentes de inteligência artificial passam a ser participantes de primeira classe na forma como uma empresa funciona. Não pensamos nisso como um modelo. É simplesmente como trabalhamos.

## A aposta

Apostamos que uma equipe de duas pessoas, com as ferramentas certas, a mentalidade certa e sem entraves organizacionais, pode avançar mais rapidamente do que empresas com centenas de funcionários e milhões em financiamento. Não em todas as frentes, mas naquela que importa: oferecer uma experiência de localização fundamentalmente melhor.

O setor não consegue se reinventar. Nós conseguimos.