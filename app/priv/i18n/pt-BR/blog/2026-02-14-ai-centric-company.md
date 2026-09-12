%{
  title:
    "Construindo uma empresa centrada em IA para desafiar uma indústria que não consegue se reinventar",
  summary:
    "Empresas de localização estabelecidas têm o capital, mas não a liberdade para inovar. Estamos desenvolvendo o Glossia do zero em torno da IA e dos agentes, não apenas no produto, mas também em como operamos todo o negócio.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs e agentes estão transformando tudo. Não apenas o que o software pode fazer, mas como as empresas são construídas para criar esse software. Em [Glossia](https://glossia.ai), vemos isso como uma oportunidade de uma geração para repensar como o conteúdo chega em todos os idiomas. Mas também sabemos que ter uma boa ideia de produto não é suficiente. Você precisa de uma organização que seja ágil o suficiente para fazer a diferença.

Essa segunda parte é o que este post aborda.

## O dilema do inovador, se desenrolando em tempo real

O setor de localização é grande e bem financiado. Empresas como Smartling, Phrase, Crowdin e Lokalise vêm construindo ferramentas e serviços há anos. Elas têm clientes, receita, fluxos de trabalho estabelecidos e equipes que sabem como vender e suportar seus produtos.

Então, por que uma pequena, focada equipe sequer tentaria?

Por causa de algo que Clayton Christensen descreveu em [O Dilema do Inovador](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): as empresas estabelecidas lutam para adotar inovação disruptiva, não por falta de recursos, mas porque seus modelos de negócios existentes, expectativas dos clientes e estruturas organizacionais impedem isso.

Essas empresas construíram seus produtos em torno de memórias de tradução, preço por palavra e fluxos de trabalho de tradutores humanos. Seus clientes criaram modelos mentais e processos em torno desses blocos de base. Mudar a fundação significa quebrar promessas a clientes existentes, requalificar equipes e repensar modelos de receita. Mesmo com as melhores intenções e o capital para investir, a inércia organizacional é enorme.

Eles precisam de capacidade de inovação e comprometimento da força de trabalho para abraçar novas ideias. Mas ainda mais difícil é precisarem que seus clientes existentes acompanhem a jornada. E esses clientes estão investidos no modelo antigo.

Esta é a oportunidade que vemos. Não apesar de ter menos recursos, mas por isso. Não temos legado a proteger, sem fluxos de trabalho a preservar, sem clientes a migrar. Podemos projetar tudo do zero.

> \[\!NOTE\]
> O dilema do inovador não é sobre tecnologia. Trata-se de incentivos. Empresas estabelecidas otimizam para o que seus clientes atuais querem, o que torna quase impossível perseguir algo fundamentalmente diferente.

## A IA no centro, não nas bordas

A maioria das empresas adota a IA apenas acoplando-a a processos existentes. Um chatbot aqui, um motor de sugestões ali. Vamos na outra direção: projetamos a empresa inteira para ser centrada na IA desde o primeiro dia.

Isso significa que a IA não é um recurso do produto. Ela molda como construímos, vendemos, damos suporte e operamos. Cada decisão que tomamos começa com uma pergunta: um agente consegue fazer isso?

O próprio produto é um agente que reside no seu terminal, lê seus arquivos fonte, gera traduções, executa seus checks de CI e itera até a saída passar. Essa é a parte que as pessoas veem. Mas, por trás, a mesma filosofia orienta o negócio.

## Uma equipe pequena, delegando tudo o mais a agentes

Estamos deliberadamente mantendo a equipe pequena e permanecendo assim por tanto tempo quanto fizer sentido.

Isso não é sobre economizar dinheiro. É sobre eliminar uma categoria inteira de trabalho que não produz valor para os usuários.

Quanto mais humanos você adiciona, mais coordenação você precisa. Você constrói sistemas de confiança, modelos de permissão, cadeias de aprovação. Você gerencia conflitos, alinha prioridades, agenda reuniões. Tudo isso é energia criativa que vai para manter uma organização humana em vez de construir um produto.

A maneira como fazemos isso funcionar é delegando tudo o resto a agentes. Análise de marketing, síntese de feedbacks de clientes, pesquisa competitiva, elaboração de conteúdo, monitoramento operacional: o trabalho rotineiro de operar o negócio é cada vez mais feito por agentes que projetamos, revisamos e melhoramos.

## Escolhas de tecnologia deliberadas

Somos muito intencionais em relação à nossa stack porque isso afeta diretamente o quão rápido podemos nos mover e como o software se comporta para as equipes que o auto-hospedam.

**Para o agente (CLI):** Escolhemos Rust. Ele compila binários únicos e portáveis em todas as plataformas, sem dependências de tempo de execução para o usuário.

**Para o servidor:** Escolhemos [Elixir](https://elixir-lang.org) e o [Erlang](https://www.erlang.org) tempo de execução. A natureza funcional do Elixir o torna uma ótima opção para cargas de trabalho de agentes. A VM Erlang é amplamente testada para concorrência e tolerância a falhas. E aqui está um bônus: um agente de IA pode introspecionar o sistema Erlang em execução para entender o que está acontecendo, coletar insights e até mesmo corrigir problemas em produção.

**Para distribuição:** O Glossia é de código aberto sob a [Licença O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Equipes que desejam executá-lo por conta própria podem instalar o chart do Helm no repositório em qualquer cluster Kubernetes. O mesmo código alimenta o serviço hospedado na glossia.ai e qualquer implantação auto-hospedada.

> \[\!IMPORTANTE\]
> Somos intencionais em evitar a complexidade técnica que os engenheiros tendem a buscar precocemente, antes que seja justificada. Cada dependência e cada camada de infraestrutura deve justificar seu peso.

## O que isso desbloqueia

Operar a empresa desta forma não é apenas uma questão de eficiência. Isso altera o que podemos oferecer e a velocidade com que aprendemos.

**Acessível a mais equipes.** A indústria de localização tornou as suas ferramentas inacessíveis com preços complexos, taxas por palavra e ciclos de vendas corporativas. Se o seu fluxo de trabalho de tradução exigir processos de compras, negociações de preços e um gerente de projeto, a maioria das pequenas equipes lançará apenas em inglês. Ao construir uma organização eficiente e lançar o software de código aberto para que as equipes possam autohospedar, podemos tornar a Glossia genuinamente acessível.

**Inovação mais rápida.** Queremos explorar muitas ideias. Novas interfaces para o agente, melhores loops de feedback, novas formas de integrar os linguistas ao fluxo de trabalho. Uma empresa tradicional precisaria contratar pessoal, alinhar equipes e agendar revisões do roadmap. Nós simplesmente tentamos coisas. A distância entre uma ideia e um experimento implantado é medida em horas, não em trimestres.

## Desafiar como trabalhamos, não apenas o que construímos

Não estamos emocionalmente apegados às velhas formas de fazer as coisas. Estamos ativamente questionando o que significa revisão de código quando um agente escreve a maioria do código. Como funciona a colaboração quando a equipe humana é pequena e os agentes fazem o trabalho rotineiro. Como corrigir um bug quando o agente pode inspecionar o sistema em execução.

Cometemos erros. Continuaremos cometê-los. Mas, mantendo uma mente aberta sobre como projetamos e gerimos a empresa, continuamos descobrindo ideias que influenciam o produto. A forma como operamos não está separada do que construímos. São a mesma coisa.

[McKinsey recentemente descreveu](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) o que eles chamam de "a organização agêntica", um novo modelo operacional onde agentes de IA se tornam participantes de primeira classe em como uma empresa funciona. Não a consideramos um modelo. É apenas como trabalhamos.

## A aposta

Apostamos que uma pequena equipe com as ferramentas certas, a mentalidade certa e sem bagagem organizacional pode superar empresas com centenas de funcionários e milhões em financiamento. Não em todas as frentes, mas na única que importa: entregar uma experiência de localização fundamentalmente melhor.

A indústria não pode se reinventar. Nós podemos.