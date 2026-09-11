%{
  title:
    "Construindo uma empresa centrada em IA para desafiar um setor que não consegue se reinventar",
  summary:
    "Empresas de localização tradicionais possuem o capital, mas não a liberdade para inovar. Estamos projetando a Glossia do zero, centrada em IA e agentes, não apenas no produto, mas na forma como operamos todo o negócio.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs e agentes estão transformando tudo. Não apenas o que o software pode fazer, mas como as empresas são construídas para criar esse software. Em [Glossia](https://glossia.ai), vemos isso como uma oportunidade de uma geração para repensar como o conteúdo chega a cada idioma. Mas também sabemos que ter uma boa ideia de produto não é suficiente. Você precisa de uma organização que possa se mover rápido o suficiente para fazer a diferença.

Essa segunda parte é o que este post trata.

## O dilema do inovador, se desdobrando em tempo real

A indústria de localização é grande e bem financiada. Empresas como Smartling, Phrase, Crowdin e Lokalise vêm construindo ferramentas e serviços há anos. Têm clientes, receita, fluxos de trabalho estabelecidos e equipes que sabem vender e oferecer suporte aos seus produtos.

Então, por que uma pequena equipe focada tentaria mesmo assim?

Por causa de algo que Clayton Christensen descreveu em [O Dilema do Inovador](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): empresas estabelecidas lutam para adotar inovação disruptiva, não por falta de recursos, mas porque seus modelos de negócios existentes, expectativas dos clientes e estruturas organizacionais impedem que o façam.

Estas empresas construiram seus produtos em torno de memórias de tradução, tarifa por palavra e fluxos de trabalho de tradutores humanos. Seus clientes construíram modelos mentais e processos em torno dessas peças fundamentais. Mudar a base significa quebrar promessas a clientes existentes, requalificar equipes e repensar modelos de receita. Mesmo com as melhores intenções e o capital para investir, a inércia organizacional é enorme.

Eles precisam de capacidade de inovação e comprometimento de sua força de trabalho para abraçar novas ideias. Mas é ainda mais difícil: precisam que seus clientes existentes acompanhem. E esses clientes estão investidos no modelo antigo.

Esta é a abertura que vemos. Não apesar de ter menos recursos, mas devido a isso. Não temos legado a proteger, nem fluxos de trabalho a preservar, nem clientes a migrar. Podemos projetar tudo do zero.

> \[\!NOTE\]
> O dilema do inovador não é sobre tecnologia. É sobre incentivos. Empresas estabelecidas otimizam para o que seus clientes atuais querem, o que torna quase impossível perseguir algo fundamentalmente diferente.

## IA no centro, não nas bordas

A maioria das empresas adota a IA acoplando-a a processos existentes. Um chatbot aqui, um motor de sugestões ali. Vamos na direção oposta: desenhamos a empresa inteira para ser centrada na IA desde o primeiro dia.

Isso significa que a IA não é um recurso do produto. Ela molda como construímos, vendemos, damos suporte e operamos. Toda decisão que tomamos começa com uma pergunta: um agente consegue fazer isso?

O próprio produto é um agente que vive no seu terminal, lê seus arquivos de fonte, gera traduções, executa suas verificações de CI e itera até que a saída passe. É o que as pessoas veem. Mas por trás, a mesma filosofia rege o negócio.

## Uma equipe pequena, delegando tudo o resto para agentes

Deliberadamente mantemos a equipe pequena e permanecemos assim tanto tempo quanto fizer sentido.

Não se trata de economizar dinheiro. Trata-se de eliminar uma categoria inteira de trabalho que não gera valor para os usuários.

Quanto mais humanos você adicionar, mais coordenação você precisa. Você constrói sistemas de confiança, modelos de permissão, cadeias de aprovação. Você gerencia conflitos, alinha prioridades, agenda reuniões. Tudo isso é energia criativa que vai para manter uma organização humana em vez de construir um produto.

O jeito fazemos isso funcionar é delegando tudo o mais para agentes. Análise de marketing, síntese de feedback de clientes, pesquisa competitiva, redação de conteúdo, monitoramento operacional: o trabalho rotineiro de gerir o negócio é cada vez mais feito por agentes que moldamos, revisamos e aprimoramos.

## Escolhas tecnológicas deliberadas

Estamos muito intencionais em relação à nossa stack porque isso afeta diretamente a rapidez com que avançamos e como o software se comporta para as equipes que o auto-hospedam.

**Para o agente (CLI):** Escolhemos Rust. Ele compila em binários únicos e portáveis em todas as plataformas, sem dependências do runtime para o usuário.

**Para o servidor:** Escolhemos [Elixir](https://elixir-lang.org) e o [Erlang](https://www.erlang.org) runtime. A natureza funcional do Elixir o torna uma excelente escolha para cargas de trabalho de agentes. A Máquina Virtual do Erlang é testada para concorrência e tolerância a falhas. E aqui está um bônus: um agente de IA pode introspecionar o sistema do Erlang em execução para entender o que está acontecendo, coletar insights e até corrigir problemas em produção.

**Para distribuição:** O Glossia é de código aberto sob a [Licença O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md)'. Equipes que desejam rodá-lo por conta própria podem instalar o chart Helm no repositório em qualquer cluster Kubernetes. O mesmo código impulsiona o serviço hospedado na glossia.ai e qualquer implantação auto-hospedada.

> \[\!IMPORTANTE\]
> Somos deliberados ao pular complexidades técnicas que engenheiros tendem a buscar precocemente quando não há justificativa. Cada dependência e cada camada de infraestrutura deve justificar o seu peso.

## O que isso desbloqueia

Gerenciar a empresa dessa forma não é apenas uma jogada de eficiência. Isso muda o que podemos oferecer e a rapidez com que podemos aprender.

**Acessível a mais equipes.** A indústria de localização tornou suas ferramentas inacessíveis por meio de preços complexos, tarifas por palavra e ciclos de vendas empresariais. Se seu fluxo de tradução exigir compras, negociações de preços e um gerente de projetos, a maioria das pequenas equipes lançará apenas em inglês. Ao construir uma organização eficiente e disponibilizar o software de forma open source para que as equipes possam auto-hospedar, podemos tornar o Glossia genuinamente acessível.

**Inovação mais rápida.** Queremos explorar muitas ideias. Novas interfaces para o agente, ciclos de feedback melhores, novas formas de integrar linguistas ao fluxo de trabalho. Uma empresa tradicional precisaria aumentar a equipe, alinhar squads e agendar revisões de roteiro. Nós apenas testamos as coisas. A distância entre uma ideia e um experimento implantado é medida em horas, não trimestres.

## Desafiando como trabalhamos, não apenas o que construímos.

Não estamos emocionalmente apegados às formas antigas de fazer as coisas. Estamos questionando ativamente o que significa revisão de código quando um agente escreve a maior parte do código. Como a colaboração funciona quando a equipe humana é pequena e os agentes fazem o trabalho rotineiro. Como corrigir um bug quando o agente pode inspecionar o sistema em execução.

Cometemos erros. Continuaremos cometendo-os. Mas, mantendo uma abordagem aberta sobre como projetamos e gerenciamos os negócios, continuamos descobrindo ideias que influenciam o produto. A maneira como operamos não está separada do que construímos. Eles são a mesma coisa.

[McKinsey recentemente descreveu](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) o que eles chamam de "organização agêntica", um novo modelo operacional onde os agentes de IA se tornam participantes de primeira classe na forma como uma empresa opera. Não pensamos nisso como um modelo. É apenas como trabalhamos.

## A aposta

Apostamos que uma equipe pequena com as ferramentas certas, a mentalidade certa e sem bagagem organizacional pode ultrapassar empresas com centenas de funcionários e milhões em capital. Não em todas as frentes, mas na única que importa: entregar uma experiência de localização fundamentalmente melhor.

A indústria não consegue se reinventar. Nós podemos.