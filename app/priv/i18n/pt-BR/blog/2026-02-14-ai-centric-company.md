%{
  title: "Construindo uma empresa centrada em IA para desafiar um setor que não consegue se reinventar",
  summary: "Empresas de localização consolidadas têm capital, mas não a liberdade para inovar. Estamos projetando o Glossia do zero em torno de IA e agentes, não apenas no produto, mas na forma como operacionalizamos todo o negócio.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs e agentes estão transformando tudo. Não apenas o que o software pode fazer, mas como as empresas são construídas para criar esse software. Em [Glossia](https://glossia.ai), vemos isso como uma oportunidade para repensar como o conteúdo chega a cada idioma. Mas também sabemos que ter uma boa ideia de produto não basta. Precisa-se de uma organização que consiga se mover rápido o suficiente para ser relevante.

É sobre essa segunda parte.

## O dilema do inovador, acontecendo em tempo real

O mercado de localização é grande e bem financiado. Empresas como Smartling, Phrase, Crowdin e Lokalise vêm construindo ferramentas e serviços há anos. Têm clientes, receita, fluxos de trabalho estabelecidos e equipes que sabem vender e dar suporte aos seus produtos.

Então, por que uma equipe de duas pessoas tentaria mesmo assim?

Por causa de algo que Clayton Christensen descreveu em [The Innovator's Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): empresas estabelecidas têm dificuldade em adotar inovação disruptiva, não por falta de recursos, mas porque seus modelos de negócios existentes, expectativas dos clientes e estruturas organizacionais impedem que isso ocorra.

Essas empresas construíram seus produtos em torno de memórias de tradução, precificação por palavra e fluxos de trabalho de tradutores humanos. Seus clientes construíram modelos mentais e processos em torno desses blocos de construção. Mudar a base significa quebrar promessas a clientes existentes, requalificar equipes e repensar modelos de receita. Mesmo com as melhores intenções e o capital para investir, a inércia organizacional é enorme.

Precisam de capacidade de inovação e comprometimento da força de trabalho para abraçar novas ideias. Mas ainda mais difícil do que isso, precisam que seus clientes existentes também venham junto. E esses clientes estão investidos no modelo antigo.

Este é o espaço que vemos. Não apesar de ter menos recursos, mas sim por isso mesmo. Não temos legado a proteger, não temos fluxos de trabalho a preservar, não temos clientes para migrar. Podemos projetar tudo do zero.

> \[\!NOTE\]
> O dilema do inovador não é sobre tecnologia. Trata-se de incentivos. Empresas estabelecidas otimizam o que seus clientes atuais querem, o que torna quase impossível buscar algo fundamentalmente diferente.

## IA no centro, não nas bordas

A maioria das empresas adota IA aplicando-a a processos existentes. Um chatbot aqui, um motor de sugestões ali. Vamos na direção oposta: desenhamos a empresa inteira para ser centrada em IA desde o primeiro dia.

Isso significa que a IA não é um recurso do produto. Ela molda como construímos, vendemos, damos suporte e operamos. Cada decisão que tomamos começa com uma pergunta: um agente pode fazer isso?

O produto em si é um agente que vive no seu terminal, lê seus arquivos de origem, gera traduções, executa suas validações de CI e itera até a saída ser aprovada. É essa a parte que as pessoas veem. Mas por trás disso, a mesma filosofia gerencia o negócio.

## Duas pessoas, zero sobrecarga organizacional

Estamos deliberadamente mantendo a equipe o mais pequena possível. No momento, somos apenas duas pessoas. Nosso objetivo é permanecer com duas ou três pessoas pelo máximo de tempo que podermos.

Isso não é sobre economizar dinheiro (embora ajude). Trata-se de eliminar toda uma categoria de trabalho que não produz valor para os usuários.

Quanto mais humanos você adiciona, mais coordenação é necessária. Você cria sistemas de confiança, modelos de permissão, cadeias de aprovação. Você gerencia conflitos, alinha prioridades, agenda reuniões. Tudo isso é energia criativa que vai para manter uma organização humana em vez de construir um produto.

Com duas pessoas, pulamos tudo isso. Confiamos um no outro plenamente. Temos acesso a tudo. Não há sobrecarga, não há política, não há processo pelo processo.

A forma como fazemos isso funcionar em escala é delegando tudo o mais a agentes.

## Discord, um agente de IA e uma única linha de comando

Aqui está algo que pode soar incomum: nossa interface principal de negócios é um servidor [Discord](https://discord.com).

Temos um agente de IA conectado a ele, alimentado pelo [OpenAI](https://openai.com), com acesso a todas as ferramentas de que precisamos para conduzir o negócio. Em vez de alternar entre dashboards web, plataformas de análise e painéis de administração, falamos com o agente. Texto e voz são a unidade de interação.

Através do agente, um de nós pode:

- Consultar insights de marketing e de produto
- Inspecionar servidores de produção
- Conduzir pesquisas de mercado
- Coletar feedback dos clientes
- Realizar análise competitiva através da navegação web
- Redigir conteúdo, revisar textos e publicar

Nenhum de nós depende do outro para fazer qualquer uma dessas coisas. O agente tem acesso às nossas APIs, bancos de dados e ferramentas de monitoramento. Ele pode navegar pela web, ler documentação e sintetizar informações. É um servidor Discord, uma instância OpenAI e uma chave LLM. Isso é o sistema operacional da empresa.

> \[\!TIP\]
> Se você está construindo uma pequena equipe e quer reduzir a sobrecarga de coordenação, considere tornar texto e voz a sua interface primária para operações de negócios. Um agente compartilhado em um canal de chat pode substituir dezenas de dashboards e eliminar a necessidade da maioria das ferramentas internas.

## Escolhas tecnológicas deliberadas

Somos muy intencionais quanto à nossa pilha tecnológica porque isso afeta diretamente a rapidez com que nos movemos e com que pouco custo podemos operar.

**Para o agente (CLI):** Escolhemos Go. Ele compila em binários únicos e portáteis para todas as plataformas, sem dependências em tempo de execução para o usuário.

**Para o servidor:** Escolhemos [Elixir](https://elixir-lang.org) e o runtime da [Erlang](https://www.erlang.org). A natureza funcional do Elixir o torna excelente para cargas de trabalho de agentes. A máquina virtual Erlang foi submetida a testes rigorosos para concorrência e tolerância a falhas. E aqui vai um bônus: um agente de IA pode introspecionar o sistema Erlang em execução para entender o que está acontecendo, coletar insights e até corrigir problemas em produção.

**Para infraestrutura:** Tudo roda em um único VPS. Não apenas o servidor de produção do Glossia, mas todos os serviços periféricos também: [PostgreSQL](https://www.postgresql.org/) para o banco de dados, [Plausible](https://plausible.io) para análises amigáveis à privacidade, [Grafana](https://grafana.com) para telemetria e observabilidade. Tudo é implantado a partir de definições de infraestrutura controladas por versão que descrevem como e onde o deploy acontece.

Isso mantém os custos extremamente baixos. Não dependemos de serviços de nuvem de terceiros, bancos de dados gerenciados ou provedores de plataforma como serviço. Temos algumas dependências externas, mas apenas para coisas que levariam muito tempo para replicarmos e onde o custo faz sentido.

Quando chegar a hora de escalar entre servidores, evoluiremos o modelo. Mas acreditamos que podemos chegar bem longe com essa configuração. E ir rápido importa mais do que crescer grande por enquanto.

> \[\!IMPORTANT\]
> Somos muito deliberados ao evitar a complexidade técnica que engenheiros tendem a buscar precocemente. Kubernetes, microsserviços, implantações multi-região. Nenhum disso é necessário nesta etapa, e tudo isso nos atrasaria.

## O que isso desbloqueia

Operar a empresa assim não é apenas uma questão de eficiência. Muda o que podemos oferecer e o quanto rápido podemos aprender.

**Mais barato para os usuários.** A indústria de localização tornou suas ferramentas inacessíveis por meio de precificação complexa, taxas por palavra e ciclos de vendas corporativas. Se seu fluxo de trabalho de tradução exigir aprovação de compras, negociações de preços e um gerente de projeto, a maioria das pequenas equipes só vai lançar em inglês. Ao manter nossos custos operacionais próximos a zero, podemos oferecer algo genuinamente acessível.

**Inovação mais rápida.** Queremos explorar muitas ideias. Novas interfaces para o agente, melhores ciclos de feedback, novas formas de integrar linguistas ao fluxo de trabalho. Uma empresa tradicional precisaria contratar pessoal, alinhar equipes e agendar revisões de roadmap. Nós apenas testamos. A distância entre uma ideia e um experimento implantado é medida em horas, não em trimestres.

## Desafiando como trabalhamos, não apenas o que construímos

Não estamos emocionalmente apegados às formas antigas de fazer as coisas. Estamos questionando ativamente o que significa a revisão de código quando um agente escreve a maior parte do código. Como funciona a colaboração quando há apenas duas pessoas. Como corrigir um bug quando o agente pode inspecionar o sistema em execução.

Cometemos erros. Continuaremos cometendo-os. Mas, mantendo a mente aberta sobre como projetamos e conduzimos o negócio, escolhemos descobrir ideias que influenciam o produto. A forma como operamos não está separada do que construímos. São a mesma coisa.

[McKinsey recentemente descreveu](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) o que chamam de «organização agêntica», um novo modelo operacional onde os agentes de IA tornam-se participantes de primeira classe na forma como uma empresa opera. Não pensamos nisso como um modelo. É apenas como trabalhamos.

## A aposta

Apostamos que uma equipe de duas pessoas, com as ferramentas certas, a mentalidade certa e sem lastro organizacional, pode superar empresas com centenas de funcionários e milhões em financiamento. Não em todas as frentes, mas na que importa: entrega de uma experiência de localização fundamentalmente melhor.

O setor não pode se reinventar. Nós podemos.