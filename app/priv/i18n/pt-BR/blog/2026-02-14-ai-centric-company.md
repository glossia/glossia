%{
  title:
    "Construindo uma empresa centrada em IA para desafiar um setor que não consegue se reinventar",
  summary:
    "Empresas de localização consolidadas têm o capital, mas não a liberdade de inovar. Projetamos o Glossia do zero em torno da IA e de agentes, não apenas no produto, mas também em como operamos todo o negócio.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs e agentes estão transformando tudo. Não apenas o que o software pode fazer, mas como as empresas são construídas para criar esse software. Na [Glossia](https://glossia.ai), vemos isso como uma oportunidade de uma geração para repensar como o conteúdo chega a cada idioma. Mas também sabemos que ter uma boa ideia de produto não é suficiente. Você precisa de uma organização que possa se mover rápido o suficiente para fazer a diferença.

É da segunda parte que este post trata.

## O dilema do inovador, se desenrolando em tempo real

A indústria de localização é grande e bem financiada. Empresas como Smartling, Phrase, Crowdin e Lokalise têm construído ferramentas e serviços há anos. Elas têm clientes, receita, fluxos de trabalho estabelecidos e equipes que sabem vender e suportar seus produtos.

Então, por que uma equipe pequena e focada até tentaria?

Por causa de algo que Clayton Christensen descreveu em [O Dilema do Inovador](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): empresas consolidadas têm dificuldade em adotar inovações disruptivas, não por falta de recursos, mas porque seus modelos de negócios existentes, expectativas dos clientes e estruturas organizacionais impedem isso.

Essas empresas construíram seus produtos em torno de memórias de tradução, preços por palavra e fluxos de trabalho com tradutores humanos. Seus clientes construiraram modelos mentais e processos em torno desses blocos fundamentais. Mudar a fundação significa quebrar promessas a clientes existentes, retreinar equipes e repensar modelos de receita. Mesmo com as melhores intenções e o capital para investir, a inércia organizacional é enorme.

Eles precisam de capacidade de inovação e compromisso da força de trabalho para abraçar novas ideias. Mas ainda mais difícil que isso, precisam que seus clientes existentes se juntem à jornada. E esses clientes estão investidos no modelo antigo.

Esta é a oportunidade que vemos. Não apesar de ter menos recursos, mas por causa disso. Não temos legado para proteger, nem fluxos de trabalho para preservar, nem clientes para migrar. Podemos projetar tudo do zero.

> \[\!NOTE\]
> O dilema do inovador não é sobre tecnologia. Trata-se de incentivos. Empresas consolidadas otimizam para o que seus clientes atuais querem, o que torna quase impossível buscar algo fundamentalmente diferente.

## IA no centro, não nas bordas

A maioria das empresas adota a IA adicionando-a aos processos existentes. Um bot de chat aqui, um motor de sugestões ali. Nós vamos na direção oposta: projetamos toda a empresa para ser centrada em IA desde o primeiro dia.

Isso significa que a IA não é um recurso do produto. Ela molda como construímos, vendemos, suportamos e operamos. Toda decisão que tomamos começa com uma pergunta: um agente pode fazer isso?

O próprio produto é um agente que vive em seu terminal, lê seus arquivos de origem, gera traduções, executa seus testes de CI e itera até que a saída seja aprovada. Essa é a parte que as pessoas veem. Mas por trás disso, a mesma filosofia rege o negócio.

## Uma pequena equipe, delegando tudo o resto a agentes

Estamos deliberadamente mantendo a equipe pequena e permanecendo assim por tanto tempo quanto faça sentido.

Isso não se trata de economizar dinheiro. Trata-se de eliminar uma categoria inteira de trabalho que não gera valor para os usuários.

Quanto mais humanos você adiciona, mais coordenação você precisa. Você constrói sistemas de confiança, modelos de permissão, cadeias de aprovação. Você gerencia conflitos, alinha prioridades, agenda reuniões. Tudo isso é energia criativa que se gasta mantendo uma organização humana em vez de construir um produto.

A maneira como fazemos isso funcionar é delegando tudo o resto a agentes. Análise de marketing, síntese de feedback do cliente, pesquisa competitiva, redação de conteúdo, monitoramento operacional: o trabalho rotineiro de gerenciar o negócio é cada vez mais realizado por agentes que moldamos, revisamos e melhoramos.

## Escolhas tecnológicas deliberadas

Somos muito intencionais quanto ao nosso stack, pois isso afeta diretamente a rapidez com que avançamos e o comportamento do software para as equipes que o auto-hospedam.

**Para o agente (CLI):** Escolhemos Rust. Ele compila em binários únicos e portáveis entre plataformas, sem dependências de tempo de execução para o usuário.

**Para o servidor:** Escolhemos [Elixir](https://elixir-lang.org) e o [Erlang](https://www.erlang.org) tempo de execução. A natureza funcional do Elixir o torna uma excelente escolha para cargas de trabalho agênticas. A VM da Erlang é comprovada para concorrência e tolerância a falhas. E aqui está um bônus: um agente de IA pode introspecionar o sistema Erlang em execução para entender o que está ocorrendo, coletar insights e até mesmo corrigir problemas em produção.

**Para distribuição:** A Glossia é de código aberto sob a [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Equipes que desejam executá-la por conta própria podem instalar o Helm chart no repositório em qualquer cluster Kubernetes. O mesmo código impulsiona o serviço hospedado no glossia.ai e qualquer implantação auto-hospedada.

> \[\!IMPORTANTE\]
> Somos deliberados ao omitir a complexidade técnica que os engenheiros tendem a buscar precocemente, quando ela não se justifica. Cada dependência e cada camada de infraestrutura precisam justificar o seu peso.

## O que isso desbloqueia

Administrar a empresa dessa maneira não é apenas uma questão de eficiência. Isso muda o que podemos oferecer e a velocidade com que aprendemos.

**Acessível a mais equipes.** A indústria de localização tornou suas ferramentas inacessíveis através de precificação complexa, taxas por palavra e ciclos de vendas corporativas. Se seu fluxo de tradução exigir processos de compras, negociações de preço e um gerente de projetos, a maioria das equipes pequenas acabará lançando tudo em inglês. Ao construir uma organização eficiente e disponibilizar o software em código aberto para que as equipes possam auto-hospedar, podemos tornar o Glossia genuinamente acessível.

**Inovação mais rápida.** Queremos explorar muitas ideias. Novas interfaces para o agente, melhores loops de feedback, novas formas de integrar tradutores ao fluxo de trabalho. Uma empresa tradicional precisaria contratar pessoal, alinhar times e agendar revisões de roadmap. Nós apenas testamos ideias. A distância entre uma ideia e um experimento implantado é medida em horas, não trimestres.

## Desafiando como trabalhamos, não apenas o que construímos

Não estamos emocionalmente apegados às velhas formas de fazer as coisas. Estamos ativamente questionando o que revisão de código significa quando um agente escreve a maior parte do código. Como a colaboração funciona quando a equipe humana é pequena e os agentes realizam o trabalho rotineiro. Como você corrige um bug quando o agente pode inspecionar o sistema em execução.

Cometemos erros. Vamos continuar cometendo-os. Mas, mantendo uma mente aberta sobre como desenhamos e operamos o negócio, continuamos descobrindo ideias que influenciam o produto. A maneira como operamos não é separada do que construímos. São a mesma coisa.

[McKinsey descreveu recentemente](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) o que eles chamam de "a organização agêntica", um novo modelo operacional onde agentes de IA se tornam participantes de primeira classe na forma como uma empresa opera. Não o vemos como um modelo. É apenas como trabalhamos.

## A aposta

Apostamos que uma pequena equipe com as ferramentas certas, a mentalidade certa e sem bagagem organizacional pode superar empresas com centenas de colaboradores e milhões em financiamento. Não em todas as frentes, mas na que importa: entregar uma experiência de localização fundamentalmente melhor.

A indústria não pode se reinventar. Podemos.