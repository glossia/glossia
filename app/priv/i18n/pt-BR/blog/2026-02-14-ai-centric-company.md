%{
  title:
    "Construindo uma empresa centrada em IA para desafiar uma indústria que não consegue se reinventar.",
  summary:
    "Empresas de localização estabelecidas têm capital, mas não a liberdade para inovar. Estamos construindo a Glossia do zero em torno da IA e de agentes, não apenas no produto, mas em como operamos todo o negócio.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs e agentes estão transformando tudo. Não apenas o que o software pode fazer, mas como as empresas são estruturadas para criar esse software. Em [Glossia](https://glossia.ai), vemos isso como uma oportunidade de uma geração para repensar como o conteúdo chega a todos os idiomas. Mas também sabemos que ter uma boa ideia de produto não é suficiente. Você precisa de uma organização que possa agir com rapidez suficiente para ter impacto.

Essa segunda parte é sobre o que este post trata.

## O dilema do inovador, se desenrolando em tempo real

O setor de localização é grande e bem capitalizado. Empresas como Smartling, Phrase, Crowdin e Lokalise vêm construindo ferramentas e serviços há anos. Elas contam com clientes, receita, fluxos de trabalho consolidados e equipes que sabem como vender e dar suporte aos seus produtos.

Então por que uma equipe pequena e focada tentaria, mesmo assim?

Por causa de algo que Clayton Christensen descreveu em [O Dilema dos Inovadores](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): empresas estabelecidas lutam para adotar inovação disruptiva, não por falta de recursos, mas porque seus modelos de negócios existentes, expectativas dos clientes e suas estruturas organizacionais impedem-no de fazê-lo.

Essas empresas construíram seus produtos em torno de memórias de tradução, preços por palavra e fluxos de trabalho de tradutores humanos. Seus clientes desenvolveram modelos mentais e processos ao redor desses blocos de construção. Alterar a fundação significa quebrar promessas aos clientes existentes, requalificar equipes e repensar modelos de receita. Mesmo com as melhores intenções e o capital disponível, a inércia organizacional é enorme.

Eles precisam de capacidade de inovação e compromisso da força de trabalho para abraçar novas ideias. Mas é ainda mais difícil: precisam que seus clientes existentes as acompanhem nessa jornada. E esses clientes estão investidos no modelo antigo.

Esta é a oportunidade que vemos. Não apesar de ter menos recursos, mas fruto disso. Não temos legado a proteger, nem fluxos de trabalho a preservar, nem clientes para migrar. Podemos projetar tudo do zero.

> \[\!NOTE\]
> O dilema do inovador não trata de tecnologia. Trata-se de incentivos. Empresas estabelecidas otimizam para o que seus clientes atuais desejam, o que torna quase impossível buscar algo fundamentalmente diferente.

## IA no centro, não nas bordas.

A maioria das empresas adota a IA acoplando-a aos processos existentes. Um chatbot aqui, um motor de sugestões ali. Vamos na direção oposta: projetando toda a empresa para ser centrada em IA desde o primeiro dia.

Isso significa que a IA não é um recurso do produto. Ela molda como construímos, vendemos, prestamos suporte e operamos. Toda decisão que tomamos começa com uma pergunta: um agente pode fazer isso?

O próprio produto é um agente que vive no seu terminal, lê seus arquivos-fonte, gera traduções, executa suas verificações CI e itera até a saída ser aprovada. É o que as pessoas veem. Mas por trás, a mesma filosofia gerencia o negócio.

## Uma pequena equipe, delegando tudo o resto aos agentes

Estamos deliberadamente mantendo a equipe pequena e permanecendo assim tão tempo quanto fizer sentido.

Isso não se trata de economizar dinheiro. Trata-se de eliminar uma categoria inteira de trabalho que não produz valor para os usuários.

Quanto mais humanos você adiciona, mais coordenação você precisa. Você constrói sistemas de confiança, modelos de permissão, cadeias de aprovação. Você gerencia conflitos, alinha prioridades, agenda reuniões. Tudo isso é energia criativa que vai para manter uma organização humana em vez de construir um produto.

A forma como fazemos isso funcionar é delegando tudo o resto aos agentes. Análise de marketing, síntese de feedback do cliente, pesquisa competitiva, elaboração de conteúdo, monitoramento operacional: o trabalho rotineiro de gerenciar o negócio é cada vez mais feito por agentes que moldamos, revisamos e aprimoramos.

## Escolhas tecnológicas deliberadas

Somos muito intencionais em relação ao nosso stack porque afeta diretamente a velocidade com que avançamos e como o software se comporta para as equipes que o auto-hospedam.

**Para o agente (CLI):** Escolhemos Rust. Ele compila em binários únicos e portáveis entre plataformas, sem dependências de tempo de execução para o usuário.

**Para o servidor:** Escolhemos [Elixir](https://elixir-lang.org) e o [Erlang](https://www.erlang.org) tempo de execução. A natureza funcional do Elixir o torna uma excelente escolha para cargas de trabalho agênicas. A VM do Erlang é testada em batalha para concorrência e tolerância a falhas. E aqui está um bônus: um agente de IA pode introspecionar o sistema Erlang em execução para entender o que está acontecendo, reunir insights e até corrigir problemas em produção.

**Para distribuição:** O Glossia opera como um serviço hospedado em [glossia.ai](https://glossia.ai). Um caminho de código, uma implantação, um lugar para raciocinar - sem divisão entre uma build on-prem e uma build hospedada, sem infraestrutura por inquilino para coordenar.

> \[\!IMPORTANTE\]
> Somos deliberados ao evitar a complexidade técnica que os engenheiros tendem a buscar cedo quando ela não é necessária. Cada dependência e cada camada de infraestrutura deve justificar seu peso.

## O que isso desbloqueia

Operar a empresa dessa forma não é apenas uma questão de eficiência. Altera o que podemos oferecer e a rapidez com que podemos aprender.

**Acessível a mais equipes.** A indústria de localização tornou suas ferramentas inacessíveis por meio de preços complexos, taxas por palavra e ciclos de vendas corporativos. Se o seu fluxo de trabalho de tradução exigir processos de compras, negociações de preços e um gerente de projetos, a maioria das pequenas equipes apenas publicará em inglês. Ao construir uma organização eficiente, podemos precificar o Glossia de tal forma que publicar em um segundo idioma seja uma decisão que qualquer pessoa da equipe possa tomar, e não um projeto de compras.

**Inovação mais rápida.** Queremos explorar muitas ideias. Novas interfaces para o agente, melhores ciclos de feedback, novas maneiras de integrar linguistas ao fluxo de trabalho. Uma empresa tradicional precisaria expandir a equipe, alinhar times e agendar revisões de roadmap. Nós apenas tentamos. A distância entre uma ideia e um experimento implantado é medida em horas, não em trimestres.

## Desafiando como trabalhamos, não apenas o que construímos

Não estamos emocionalmente apegados aos velhos modos de fazer as coisas. Estamos questionando ativamente o que significa uma revisão de código quando um agente escreve a maior parte do código. Como funciona a colaboração quando a equipe humana é pequena e os agentes fazem o trabalho rotineiro. Como você corrige um bug quando o agente pode inspecionar o sistema em execução.

Cometemos erros. Continuaremos cometendo-os. Mas, mantendo uma mente aberta sobre como desenhamos e gerenciamos o negócio, continuamos descobrindo ideias que influenciam o produto. A maneira como operamos não é separada do que construímos. São a mesma coisa.

[McKinsey recentemente descreveu](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) o que eles chamam de \\"a organização agêntica\\", um novo modelo de operação em que agentes de IA se tornam participantes de primeira classe na forma como a empresa funciona. Não a consideramos um modelo. Isso é apenas como trabalhamos.

## A aposta

Apostamos que uma pequena equipe com as ferramentas certas, a mentalidade certa e sem bagagem organizacional pode superar empresas com centenas de funcionários e milhões em financiamento. Não em todas as frentes, mas na única que importa: entregar uma experiência de localização fundamentalmente melhor.

A indústria não consegue se reinventar. Nós podemos.