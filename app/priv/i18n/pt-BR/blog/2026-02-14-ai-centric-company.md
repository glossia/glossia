%{
  title:
    "Construindo uma empresa centrada em IA para desafiar uma indústria que não consegue se reinventar.",
  summary:
    "Empresas de localização estabelecidas têm o capital, mas não a liberdade para inovar. Estamos desenvolvendo o Glossia do zero em torno de IA e agentes, não apenas no produto, mas em como operamos todo o negócio.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs e agentes estão transformando tudo. Não apenas o que o software pode fazer, mas como as empresas são construídas para criar esse software. Em [Glossia](https://glossia.ai), vemos isso como uma oportunidade única de uma geração para repensar como o conteúdo chega a cada idioma. Mas também sabemos que ter uma boa ideia de produto não é suficiente. Você precisa de uma organização que possa se mover rápido o suficiente para fazer a diferença.

Essa segunda parte é o que este post trata.

## O dilema do inovador, se desenrolando em tempo real

A indústria de localização é grande e bem financiada. Empresas como Smartling, Phrase, Crowdin e Lokalise vêm construindo ferramentas e serviços há anos. Elas têm clientes, receitas, fluxos de trabalho estabelecidos e equipes que sabem como vender e oferecer suporte aos seus produtos.

Então, por que uma pequena equipe focada ainda tentaria?

Por causa de algo que Clayton Christensen descreveu em [O Dilema do Inovador](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): empresas estabelecidas lutam para adotar inovação disruptiva, não por falta de recursos, mas porque seus modelos de negócios, expectativas dos clientes e estruturas organizacionais impedem que isso ocorra.

Essas empresas construíram seus produtos em torno de memórias de tradução, precificação por palavra e fluxos de trabalho de tradutores humanos. Seus clientes construíram modelos mentais e processos em torno desses blocos de construção. Mudar a base significa quebrar promessas a clientes existentes, requalificar equipes e repensar modelos de receita. Mesmo com as melhores intenções e o capital para investir, a inércia organizacional é enorme.

Eles precisam de capacidade de inovação e compromisso da sua equipe para abraçar novas ideias. Mas ainda mais difícil que isso, precisam que seus clientes existentes acompanhem essa jornada. E esses clientes estão investidos no modelo antigo.

Esta é a oportunidade que vemos. Não apesar de termos menos recursos, mas por causa disso. Não temos legado para proteger, nem fluxos de trabalho para preservar, nem clientes para migrar. Podemos projetar tudo do zero.

> \[\!NOTA\]
> O dilema do inovador não é sobre tecnologia. É sobre incentivos. Empresas estabelecidas otimizam para o que seus clientes atuais querem, o que torna quase impossível perseguir algo fundamentalmente diferente.

## IA no centro, não nas bordas

A maioria das empresas adota a IA apenas anexando-a a processos existentes. Um chatbot aqui, um motor de sugestões ali. Vamos na direção oposta: projetando a empresa inteira para ser centrada em IA desde o primeiro dia.

Isso significa que a IA não é um recurso do produto. Ela define como construímos, vendemos, damos suporte e operamos. Cada decisão que tomamos começa com uma pergunta: um agente pode fazer isso?

O próprio produto é um agente que vive no seu terminal, lê seus arquivos fonte, gera traduções, executa suas verificações de CI e itera até a saída ser aprovada. Essa é a parte que as pessoas veem. Mas por trás, a mesma filosofia orienta o negócio.

## Uma pequena equipe, delegando tudo o resto a agentes

Estamos deliberadamente mantendo a equipe pequena e permanecendo assim tanto tempo quanto fizer sentido.

Não se trata de economizar dinheiro. Trata-se de eliminar uma categoria inteira de trabalho que não produz valor para os usuários.

Quanto mais humanos você adiciona, mais coordenação você precisa. Você constrói sistemas de confiança, modelos de permissão e cadeias de aprovação. Você gerencia conflitos, alinha prioridades e agenda reuniões. Tudo isso é energia criativa que acabas indo para a manutenção de uma organização humana em vez de construir um produto.

A maneira como fazemos isso funcionar é delegando tudo o mais a agentes. Análise de marketing, síntese de feedback dos clientes, pesquisa competitiva, redação de conteúdo e monitoramento operacional: o trabalho de rotina de gerir o negócio é cada vez mais realizado por agentes que moldamos, revisamos e aprimoramos.

## Escolhas tecnológicas intencionais

Somos muito intencionais quanto à nossa pilha de tecnologia, pois isso afeta diretamente a velocidade com que avançamos e como o software se comporta para as equipes que o auto-hospedam.

**Para o agente (CLI):** Escolhemos o Rust. Ele compila em binários únicos e portáteis entre plataformas, sem dependências de tempo de execução para o usuário.

**Para o servidor:** Escolhemos [Elixir](https://elixir-lang.org) e o [Erlang](https://www.erlang.org) tempo de execução. A natureza funcional do Elixir o torna ideal para cargas de trabalho de agentes. A VM do Erlang foi testada rigorosamente para concorrência e tolerância a falhas. E aqui está um bônus: um agente de IA pode introspecionar o sistema Erlang em execução para compreender o que está acontecendo, coletar insights e até corrigir problemas em produção.

**Para distribuição:** O Glossia é de código aberto sob a [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Equipes que desejam executá-la por conta própria podem instalar o chart do Helm no repositório em qualquer cluster Kubernetes. O mesmo código alimenta o serviço hospedado em glossia.ai e qualquer implantação autohospedada.

> \[\!IMPORTANTE\]
> Somos criteriosos ao pular complexidade técnica que engenheiros tendem a buscar cedo demais, quando ela não é justificada. Cada dependência e cada camada de infraestrutura deve justificar seu peso.

## O que isso desbloqueia

Gerir a empresa dessa forma não é apenas uma jogada de eficiência. Muda o que podemos oferecer e o quão rápido podemos aprender.

**Acessível para mais equipes.** A indústria da localização tornou suas ferramentas inacessíveis por meio de preços complexos, taxas por palavra e ciclos de vendas corporativos. Se seu fluxo de trabalho de tradução exigir processos de compras, negociações de preços e um gerente de projetos, a maioria das pequenas equipes simplesmente lançará o produto em inglês. Ao construir uma organização eficiente e disponibilizar o software de código aberto para que as equipes possam auto-hospedar, podemos tornar o Glossia genuinamente acessível.

**Inovação mais rápida.** Queremos explorar muitas ideias. Novas interfaces para o agente, melhores ciclos de feedback, novas formas de integrar linguistas ao fluxo de trabalho. Uma empresa tradicional precisaria contratar equipe, alinhar equipes e agendar revisões de roadmap. Nós só testamos. A distância entre uma ideia e um experimento implantado é medida em horas, não em trimestres.

## Desafiar como trabalhamos, não apenas o que construímos

Não estamos emocionalmente apegados às formas tradicionais de fazer as coisas. Estamos ativamente questionando o que revisão de código significa quando um agente escreve a maior parte do código. Como funciona a colaboração quando a equipe humana é pequena e os agentes fazem o trabalho rotineiro. Como corrigir um bug quando o agente pode inspecionar o sistema em execução.

Cometemos erros. Continuaremos cometendo-os. Mas, mantendo uma mente aberta sobre como projetamos e operamos o negócio, continuamos descobrindo ideias que influenciam o produto. A maneira como operamos não é separada do que construímos. São a mesma coisa.

[McKinsey descreveu recentemente](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) o que eles chamam de "a organização autônoma", um novo modelo operacional em que agentes de IA se tornam participantes de primeira classe na forma como uma empresa funciona. Não a consideramos um modelo. É apenas assim que trabalhamos.

## A aposta

Apostamos que uma pequena equipe com as ferramentas certas, a mentalidade correta e sem bagagem organizacional pode superar empresas com centenas de colaboradores e milhões em financiamento. Não em todas as frentes, mas nessa que importa: entregar uma experiência de localização fundamentalmente melhor.

O setor não pode se reinventar. Podemos.