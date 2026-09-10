%{
  title:
    "Construindo uma empresa centrada em IA para desafiar um setor que não consegue se reinventar",
  summary:
    "Empresas de localização estabelecidas têm o capital, mas não a liberdade para inovar. Estamos construindo o Glossia do zero em torno de IA e agentes, não apenas no produto, mas em como operamos todo o negócio.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
As LLMs e agentes estão transformando tudo. Não apenas o que o software pode fazer, mas como as empresas são construídas para criar esse software. Na [Glossia](https://glossia.ai), vemos isso como uma oportunidade de uma geração para repensar como o conteúdo alcança cada idioma. Mas também sabemos que ter uma boa ideia de produto não é suficiente. Você precisa de uma organização que possa se mover rápido o suficiente para importar.

A segunda parte é disso que essa postagem trata.

## O dilema do inovador, se jogando em tempo real

A indústria de localização é grande e bem financiada. Empresas como Smartling, Phrase, Crowdin e Lokalise vem construindo ferramentas e serviços há anos. Elas têm clientes, receita, fluxos de trabalho estabelecidos e equipes que sabem como vender e suportar seus produtos.

Então por que uma pequena equipe focada ainda tentaria?

Por causa de algo que Clayton Christensen descreveu em [O Dilema do Inovador](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): empresas estabelecidas lutam para adotar inovação disruptiva, não por falta de recursos, mas porque seus modelos de negócios existentes, expectativas dos clientes e estruturas organizacionais impedem isso.

Essas empresas construíram seus produtos baseados em memórias de tradução, preços por palavra e fluxos de trabalho de tradução humana. Seus clientes construíram modelos mentais e processos em torno desses blocos fundamentais. Mudar a base significa quebrar promessas a clientes existentes, retreinar equipes e repensar modelos de receita. Mesmo com as melhores intenções e o capital para investir, a inércia organizacional é imensa.

Eles precisam de capacidade de inovação e comprometimento de sua força de trabalho para abraçar novas ideias. Mas o mais difícil do que isso é conseguir que seus clientes atuais os acompanhem na jornada. E esses clientes estão investidos no modelo antigo.

Esta é a abertura que vemos. Não apesar de ter menos recursos, mas justamente por causa disso. Não temos legado a proteger, nem fluxos de trabalho a preservar, nem clientes a migrar. Podemos projetar tudo do zero.

> \[\!NOTA\]
> O dilema do inovador não é sobre tecnologia. Trata-se de incentivos. Empresas estabelecidas otimizam para o que seus clientes atuais querem, o que torna quase impossível perseguir algo fundamentalmente diferente.

## A IA no centro, não nas bordas

A maioria das empresas adota a IA acoplando-a aos processos existentes. Um chatbot por aqui, um motor de sugestões ali. Vamos na direção oposta: projetamos toda a empresa para ser centrada na IA desde o primeiro dia.

Isso significa que a IA não é um recurso do produto. Ela define como construímos, vendemos, damos suporte e operamos. Toda decisão que tomamos começa com uma pergunta: um agente consegue fazer isso?

O próprio produto é um agente que vive no seu terminal, lê seus arquivos de origem, gera traduções, executa suas verificações de CI e itera até que a saída seja aprovada. Essa é a parte que as pessoas veem. Mas por trás dele, a mesma filosofia move o negócio.

## Uma pequena equipe, delegando tudo o restante a agentes

Estamos intencionalmente mantendo a equipe pequena e permanecendo assim enquanto fizer sentido.

Isso não é sobre economizar dinheiro. Trata-se de eliminar uma categoria inteira de trabalho que não produz valor para os usuários.

Quanto mais humanos você adiciona, mais coordenação exige. Você cria sistemas de confiança, modelos de permissão, cadeias de aprovação. Você gerencia conflitos, alinha prioridades, agenda reuniões. Tudo isso é energia criativa que vai para manter uma organização humana em vez de construir um produto.

A maneira como fazemos isso funcionar é delegando tudo o restante a agentes. Análise de marketing, síntese de feedback de clientes, pesquisa competitiva, elaboração de conteúdo, monitoramento operacional: o trabalho rotineiro de operar o negócio é cada vez mais feito por agentes que moldamos, revisamos e melhoramos.

## Escolhas tecnológicas deliberadas

Somos muito intencionais quanto à nossa stack, pois isso afeta diretamente a rapidez com que avançamos e como o software se comporta para as equipes que o auto-hospedam.

**Para o agente (CLI):** Escolhemos o Rust. Ele compila em binários únicos e portáveis entre plataformas, sem dependências de tempo de execução para o usuário.

**Para o servidor:** Escolhemos [Elixir](https://elixir-lang.org) e o [Erlang](https://www.erlang.org) tempo de execução. A natureza funcional do Elixir o torna uma excelente escolha para cargas de trabalho de agentes. A VM Erlang é comprovada para concorrência e tolerância a falhas. E aqui está um bônus: um agente de IA pode introspecionar o sistema Erlang em execução para entender o que está ocorrendo, coletar insights e até corrigir problemas em produção.

**Para distribuição:** O Glossia é de código aberto sob a [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Equipes que desejam operá-la por conta própria podem instalar o Helm chart no repositório em qualquer cluster Kubernetes. O mesmo código alimenta o serviço hospedado no glossia.ai e qualquer implantação auto-hospedada.

> \[\!IMPORTANT\]
> Somos deliberados em evitar complexidade técnica que engenheiros tendem a buscar precocemente quando não há necessidade. Cada dependência e cada camada de infraestrutura deve justificar seu peso.

## O que isso desbloqueia

Gerir a empresa desta forma não é apenas uma questão de eficiência. Isso muda o que podemos oferecer e o quão rápido podemos aprender.

**Acessível para mais equipes.** A indústria da localização tornando suas ferramentas inacessíveis por meio de precificação complexa, taxas por palavra e ciclos de vendas corporativos. Se seu fluxo de trabalho de tradução exigir processos de compras, negociações de preços e um gerente de projetos, a maioria das pequenas equipes apenas lançará em inglês. Ao construir uma organização eficiente e disponibilizar o software como código aberto para que as equipes possam auto-hospedar, podemos tornar o Glossia genuinamente acessível.

**Inovação mais rápida.** Queremos explorar muitas ideias. Novas interfaces para o agente, melhores ciclos de feedback, novas formas de integrar tradutores ao fluxo de trabalho. Uma empresa tradicional precisaria aumentar a equipe, alinhar times e agendar revisões do roadmap. Nós apenas testamos coisas. A distância entre uma ideia e um experimento implantado é medida em horas, não trimestres.

## Desafiando o modo como trabalhamos, não apenas o que construímos.

Não estamos emocionalmente apegados às antigas formas de fazer as coisas. Estamos ativamente questionando o que significa revisão de código quando um agente escreve a maior parte do código. Como funciona a colaboração quando a equipe humana é pequena e os agentes realizam o trabalho rotineiro. Como você corrige um bug quando o agente pode inspecionar o sistema em execução.

Cometemos erros. Continuaremos cometendo-os. Mas mantendo uma mentalidade aberta sobre como projetamos e gerenciamos o negócio, continuamos descobrindo ideias que influenciam o produto. A maneira como operamos não é separada do que construímos. Eles são a mesma coisa.

[McKinsey recentemente descreveu.](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) o que eles chamam de "organização agêntica", um novo modelo operacional onde agentes de IA se tornam participantes de primeira classe na forma como uma empresa funciona. Não a consideramos um modelo. É apenas como trabalhamos.

## A aposta

Apostamos que uma pequena equipe com as ferramentas certas, a mentalidade certa e sem bagagem organizacional pode superar empresas com centenas de funcionários e milhões em financiamento. Não em todas as frentes, mas naquilo que importa: oferecer uma experiência de localização fundamentalmente melhor.

A indústria não consegue se reinventar. Nós podemos.