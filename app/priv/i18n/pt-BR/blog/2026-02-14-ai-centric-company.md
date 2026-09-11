%{
  title:
    "Construindo uma empresa centrada em IA para desafiar um setor que não consegue se reinventar",
  summary:
    "Empresas de localização estabelecidas têm capital, mas não a liberdade para inovar. Estamos construindo a Glossia do zero em torno de IA e agentes, não apenas no produto, mas na forma como operamos todo o negócio.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs e agentes estão transformando tudo. Não apenas o que o software pode fazer, mas como as empresas são construídas para criar esse software. Em [Glossia](https://glossia.ai), vemos isso como uma oportunidade de uma geração para repensar como o conteúdo chega a todos os idiomas. Mas também sabemos que ter uma boa ideia de produto não é suficiente. Você precisa de uma organização que seja capaz de se mover rápido o suficiente para fazer a diferença.

É dessa segunda parte que este post trata.

## O dilema do inovador, se desenrolando em tempo real

O setor de localização é vasto e bem financiado. Empresas como Smartling, Phrase, Crowdin e Lokalise vêm construindo ferramentas e serviços há anos. Elas possuem clientes, receita, fluxos de trabalho estabelecidos e equipes que sabem como vender e apoiar seus produtos.

Então por que uma equipe pequena e focada sequer tentaria isso?

Por algo que Clayton Christensen descreveu em [O Dilema do Inovador](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): empresas estabelecidas lutam para adotar inovação disruptiva, não por falta de recursos, mas porque seus modelos de negócios existentes, expectativas dos clientes e estruturas organizacionais impedem que o façam.

Essas empresas construíram seus produtos em torno de memórias de tradução, precificação por palavra e fluxos de trabalho de tradutores humanos. Seus clientes desenvolveram modelos mentais e processos em torno desses blocos fundamentais. Mudar as bases significa quebrar promessas feitas a clientes existentes, retreinar equipes e repensar modelos de receita. Mesmo com as melhores intenções e o capital para investir, a inércia organizacional é enorme.

Precisam de capacidade de inovação e comprometimento de sua força de trabalho para abraçar novas ideias. Mas, ainda mais do que isso, precisam que seus clientes existentes acompanhem a jornada. E esses clientes estão investidos no modelo antigo.

Essa é a abertura que temos. Não apesar de possuir menos recursos, mas por causa disso. Não temos legado a proteger, fluxos de trabalho a preservar ou clientes para migrar. Podemos projetar tudo do zero.

> \[\!NOTE\]
> O dilema do inovador não é sobre tecnologia. É sobre incentivos. Empresas estabelecidas otimizam para o que seus clientes atuais querem, o que torna quase impossível perseguir algo fundamentalmente diferente.

## IA no centro, não nas bordas

A maioria das empresas adota a IA anexando-a a processos existentes. Um chatbot aqui, um motor de sugestões ali. Vamos na direção oposta: projetamos toda a empresa para ser centrada em IA desde o primeiro dia.

Isso significa que a IA não é um recurso do produto. Ela molda como construímos, vendemos, damos suporte e operamos. Todas as decisões que tomamos começam com uma pergunta: um agente consegue fazer isso?

O próprio produto é um agente que habita seu terminal, lê seus arquivos de fonte, gera traduções, executa suas verificações de CI e itera até que a saída passe. É essa parte que as pessoas veem. Mas por trás dela, a mesma filosofia rege o negócio.

## Uma equipe pequena, delegando tudo o resto a agentes

Estamos deliberadamente mantendo a equipe pequena e continuando assim enquanto fizer sentido.

Não se trata de economizar dinheiro. Trata-se de eliminar toda uma categoria de trabalho que não produz valor para os usuários.

Quanto mais humanos você adiciona, mais coordenação você precisa. Você constrói sistemas de confiança, modelos de permissão, cadeias de aprovação. Você gerencia conflitos, alinha prioridades, agenda reuniões. Tudo isso é energia criativa que vai para manter uma organização humana em vez de construir um produto.

A forma como fazemos isso funcionar é delegando tudo o resto a agentes. Análise de marketing, síntese de feedback dos clientes, pesquisa competitiva, redação de conteúdo, monitoramento operacional: o trabalho de rotina de gerenciar o negócio é cada vez mais realizado por agentes que moldamos, revisamos e aprimoramos.

## Escolhas tecnológicas deliberadas

Somos bastante intencionais quanto à nossa pilha, pois ela afeta diretamente o quão rápido podemos avançar e como o software se comporta para as equipes que o auto-hospedam.

**Para o agente (CLI):** Escolhemos Rust. Ele compila em binários únicos e portáveis entre plataformas, sem dependências de tempo de execução para o usuário.

**Para o servidor:** Escolhemos [Elixir](https://elixir-lang.org) e o [Erlang](https://www.erlang.org) tempo de execução. A natureza funcional do Elixir o torna uma excelente escolha para cargas de trabalho agênticas. A VM do Erlang foi testada em combate para concorrência e tolerância a falhas. E aqui está um bônus: um agente de IA pode introspecionar o sistema Erlang em execução para entender o que está acontecendo, reunir insights e até corrigir problemas em produção.

**Para distribuição:** Glossia é de código aberto sob a [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Equipes que desejam executá-lo por conta própria podem instalar o Helm chart no repositório em qualquer cluster Kubernetes. O mesmo código impulsiona o serviço hospedado no glossia.ai e qualquer implantação autohospedada.

> \[\!IMPORTANT\]
> Somos intencionais ao pular complexidade técnica que engenheiros tendem a adotar precocemente quando não é merecida. Cada dependência e cada camada de infraestrutura precisa justificar seu peso.

## O que isso desbloqueia

Gerenciar a empresa dessa maneira não é apenas uma jogada de eficiência. Altera o que podemos oferecer e a rapidez com que aprendemos.

**Acessível a mais equipes.** A indústria de localização tornou suas ferramentas inacessíveis por meio de preços complexos, taxas por palavra e ciclos de vendas corporativos. Se o seu fluxo de trabalho de tradução exigir compras, negociações de preço e a intervenção de um gerente de projeto, a maioria das pequenas equipes simplesmente lançará em inglês. Ao construir uma organização eficiente e disponibilizar o software de código aberto para que as equipes possam autohospedar, podemos tornar o Glossia genuinamente acessível.

**Inovação mais rápida.** Queremos explorar muitas ideias. Novas interfaces para o agente, melhores loops de feedback, novas formas de integrar linguistas ao fluxo de trabalho. Uma empresa tradicional precisaria contratar pessoal, alinhar equipes e agendar revisões de roadmap. Nós apenas testamos. A distância entre uma ideia e um experimento implantado é medida em horas, não em trimestres.

## Desafiando como trabalhamos, não apenas o que construímos

Não estamos emocionalmente apegados às formas antigas de fazer as coisas. Estamos ativamente questionando o que revisão de código significa quando um agente escreve a maior parte do código. Como funciona a colaboração quando a equipe humana é pequena e os agentes fazem o trabalho rotineiro. Como você corrige um bug quando o agente pode inspecionar o sistema em execução.

Cometemos erros. Vamos continuar cometendo-os. Mas, ao permanecermos abertos à forma como desenhamos e operamos o negócio, continuamos descobrindo ideias que influenciam o produto. A forma como operamos não é separada do que construímos. São a mesma coisa.

[McKinsey recentemente descreveu](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) o que eles chamam de \\"a organização agêntica\\", um novo modelo operacional onde agentes de IA se tornam participantes de primeira classe na forma como uma empresa funciona. Não o consideramos como um modelo. É apenas como trabalhamos.

## A aposta

Apostamos que uma pequena equipe com as ferramentas certas, a mentalidade certa e sem bagagem organizacional pode superar empresas com centenas de funcionários e milhões em financiamento. Não em todas as frentes, mas na que importa: entregar uma experiência de localização fundamentalmente melhor.

A indústria não consegue se reinventar. Podemos.