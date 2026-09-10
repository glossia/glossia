%{
  title:
    "Construindo uma empresa centrada em IA para desafiar um setor que não consegue se reinventar",
  summary:
    "As empresas consolidadas de localização têm capital, mas não a liberdade para inovar. Estamos projetando a Glossia do zero em torno de IA e agentes, não apenas no produto, mas em como operamos todo o negócio.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs e agentes estão transformando tudo. Não apenas o que o software pode fazer, mas como as empresas são construídas para criar esse software. Em[Glossia](https://glossia.ai), vemos isso como uma oportunidade de uma década de pensar como o conteúdo chega a cada idioma. Mas também sabemos que ter uma boa ideia de produto não é suficiente. Você precisa de uma organização que possa se mover rápido o suficiente para importar.

Essa segunda parte é sobre o que este post trata.

## O dilema do inovador, se desenrolando em tempo real

A indústria de localização é grande e bem financiada. Empresas como Smartling, Phrase, Crowdin e Lokalise vêm construindo ferramentas e serviços há anos. Elas têm clientes, receita, fluxos de trabalho estabelecidos e equipes que sabem como vender e suporte seus produtos.

Então por que uma pequena e focada equipe até tentaria?

Porém[O Dilema do Inovador](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): empresas estabelecidas lutam para adotar inovação disruptiva, não por falta de recursos, mas porque seus modelos de negócios existentes, expectativas dos clientes e estruturas organizacionais impedem que isso aconteça.

Essas empresas construíram seus produtos em torno de memórias de tradução, preços por palavra e fluxos de trabalho de tradutores humanos. Seus clientes construíram modelos mentais e processos em torno desses blocos fundamentais. Alterar a base significa quebrar promessas aos clientes existentes, recapacitar equipes e repensar modelos de rendas. Mesmo com as melhores intenções e o capital para investir, a inércia organizacional é enorme.

Eles precisam de capacidade de inovação e compromisso de sua força de trabalho para abraçar novas ideias. Mas ainda mais difícil que isso, precisam que seus clientes existentes venham junto. E esses clientes estão investidos no modelo antigo.

Esta é a oportunidade que vemos. Não apesar de ter menos recursos, mas por causa disso. Não temos legado para proteger, nenhum fluxo de trabalho para preservar, nenhum cliente para migrar. Podemos projetar tudo do zero.

> \[\!NOTE\]
> O dilema do inovador não é sobre tecnologia. É sobre incentivos. Empresas estabelecidas otimizam para o que seus clientes atuais querem, o que torna quase impossível perseguir algo fundamentalmente diferente.

## A IA no centro, não nas bordas

A maioria das empresas adota IA acoplando-a a processos existentes. Um chatbot aqui, um mecanismo de sugestão ali. Estamos indo na direção oposta: projetando toda a empresa para ser centrada em IA desde o primeiro dia.

Isso significa que a IA não é um recurso do produto. Ela molda como construímos, vendemos, damos suporte e operamos. Toda decisão que tomamos começa com uma pergunta: um agente pode fazer isso?

O próprio produto é um agente que vive no seu terminal, lê seus arquivos de origem, gera traduções, executa seus checks de CI e itera até que a saída passe. Essa é a parte que as pessoas vêem. Mas por trás disso, a mesma filosofia dirige o negócio.

## Uma pequena equipe, delegando tudo o mais a agentes

Estamos deliberadamente mantendo a equipe pequena e permanecendo assim por enquanto faz sentido.

Isso não é sobre economizar dinheiro. É sobre eliminar toda uma categoria de trabalho que não gera valor para os usuários.

Quanto mais humanos você adiciona, mais coordenação você precisa. Você cria sistemas de confiança, modelos de permissão, cadeias de aprovação. Você gerencia conflitos, alinha prioridades, agenda reuniões. Tudo isso é energia criativa que vai para manter uma organização humana em vez de construir um produto.

A forma como fazemos isso funcionar é delegando tudo o mais a agentes. Análise de marketing, síntese de feedback de clientes, pesquisa competitiva, redação de conteúdo, monitoramento operacional: o trabalho de rotina de gerenciar o negócio é cada vez mais feito por agentes que nós moldamos, revisamos e melhoramos.

## Escolhas tecnológicas deliberadas

Somos muito intencionais com nosso stack porque isso afeta diretamente o quão rápido podemos nos mover e como o software se comporta para as equipes que o hospedam.

**Para o agente (CLI):** Escolhemos Rust. Ela compila em binários únicos e portáveis entre plataformas, sem dependências de tempo de execução para o usuário.

**Para o servidor:** Escolhemos [Elixir](https://elixir-lang.org) e o [Erlang](https://www.erlang.org) tempo de execução. A natureza funcional do Elixir o torna uma excelente escolha para cargas de trabalho de agentes. A Máquina Virtual Erlang é bastante testada para concorrência e tolerância a falhas. E aqui está um bônus: um agente de IA pode introspecionar o sistema Erlang em execução para entender o que está acontecendo, coletar insights e até mesmo resolver problemas em produção.

**Para distribuição:** O Glossia é de código aberto sob a [Licença O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Equipes que desejam executá-lo por conta própria podem instalar o diagrama Helm no repositório em qualquer cluster Kubernetes. O mesmo código alimenta o serviço hospedado no glossia.ai e qualquer implantação autohospedada.

> \[\!IMPORTANTE\]
> Somos deliberados ao pular a complexidade técnica que os engenheiros tendem a buscar precocemente quando não é justificada. Cada dependência e cada camada de infraestrutura deve justificar seu peso.

## O que isso desbloqueia

Operar a empresa dessa forma não é apenas uma questão de eficiência. Altera o que podemos oferecer e a velocidade com que aprendemos.

**Acessível a mais equipes.** O setor de localização tornou suas ferramentas inacessíveis por meio de precificação complexa, tarifas por palavra e ciclos de vendas corporativas. Se seu fluxo de trabalho de tradução exigir processos de aquisição, negociação de preços e um gerente de projeto, a maioria das pequenas equipes lançará apenas em inglês. Ao construir uma organização eficiente e publicar o software como código aberto para que as equipes possam auto-alojá-lo, podemos tornar o Glossia genuinamente acessível.

**Inovação mais rápida.** Desafiando como trabalhamos, não apenas o que construímos

## Queremos explorar muitas ideias. Novas interfaces para o agente, melhores ciclos de feedback, novas formas de integrar linguistas ao fluxo de trabalho. Uma empresa tradicional precisaria expandir a equipe, alinhar as equipes e agendar revisões de roadmap. Nós apenas testamos coisas. A distância entre uma ideia e um experimento implantado é medida em horas, não em trimestres.

Não estamos emocionalmente apegados às formas antigas de fazer as coisas. Estamos questionando ativamente o que revisão de código significa quando um agente escreve a maior parte do código. Como funciona a colaboração quando a equipe humana é pequena e os agentes fazem o trabalho rotineiro. Como você corrige um bug quando o agente pode inspecionar o sistema em execução.

Cometemos erros. Vamos continuar cometendo-os. Mas ao permanecermos abertos ao design e gestão do negócio, continuamos descobrindo ideias que influenciam o produto. A forma como operamos não é separada do que construímos. São a mesma coisa.

[McKinsey recently described](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) o que eles chamam de "a organização agêntica", um novo modelo operacional onde os agentes de IA se tornam participantes de primeira classe em como uma empresa opera. Não pensamos nisso como um modelo. É simplesmente como trabalhamos.

## A aposta

Apostamos que uma pequena equipe com as ferramentas certas, a mentalidade certa e sem bagagem organizacional pode ultrapassar empresas com centenas de funcionários e milhões em financiamento. Nem em todas as frentes, mas na que importa: entregar uma experiência de localização fundamentalmente melhor.

A indústria não consegue se reinventar. Podemos.