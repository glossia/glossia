%{
  title:
    "Construindo uma empresa centrada em IA para desafiar uma indústria que não consegue se reinventar",
  summary:
    "Empresas de localização consolidadas têm o capital, mas não a liberdade para inovar. Estamos criando o Glossia do zero em torno de IA e agentes, não apenas no produto, mas na forma como operamos todo o nosso negócio.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs e agentes estão transformando tudo. Não apenas o que o software consegue fazer, mas como as empresas são construídas para criar esse software. Na [Glossia](https://glossia.ai), vemos isso como uma oportunidade de uma geração para repensar como o conteúdo chega a todos os idiomas. Mas também sabemos que ter uma boa ideia de produto não basta. Você precisa de uma organização que possa avançar rápido o suficiente para fazer a diferença.

Essa segunda parte é o que este post é sobre.

## O dilema do inovador, se desenrolando em tempo real

A indústria da localização é grande e bem financiada. Empresas como Smartling, Phrase, Crowdin e Lokalise vêm construindo ferramentas e serviços há anos. Elas têm clientes, receita, fluxos de trabalho estabelecidos e equipes que sabem como vender e apoiar seus produtos.

Então por que uma equipe apenas de duas pessoas tentaria mesmo?

Por algo que Clayton Christensen descreveu na [O Dilema do Inovador](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): empresas estabelecidas lutam para adotar inovação disruptiva, não porque não têm recursos, mas porque seus modelos de negócios existentes, expectativas dos clientes e estruturas organizacionais impedem que o façam.

Essas empresas construíram seus produtos em torno de memórias de tradução, preços por palavra e fluxos de trabalho de tradutores humanos. Seus clientes construíram modelos mentais e processos em torno desses blocos de construção. Mudar a fundação significa quebrar promessas a clientes existentes, readequar equipes e repensar modelos de receita. Mesmo com as melhores intenções e o capital para investir, a inércia organizacional é enorme.

Elas precisam de capacidade de inovação e comprometimento de sua força de trabalho para abraçar novas ideias. Mas ainda mais difícil do que isso, elas precisam que seus clientes existentes as acompanhem nessa jornada. E esses clientes estão investidos no modelo antigo.

Essa é a abertura que vemos. Não apesar de ter menos recursos, mas por causa disso. Não temos legado para proteger, nenhum fluxo de trabalho para preservar, nem clientes para migrar. Podemos projetar tudo do zero.

> \[\!NOTE\]
> O dilema do inovador não é sobre tecnologia. Trata-se de incentivos. Empresas estabelecidas otimizam para o que seus clientes atuais querem, o que torna quase impossível buscar algo fundamentalmente diferente.

## A IA no centro, não nas bordas

A maioria das empresas adota a IA acoplando-a aos processos existentes. Um chatbot aqui, um motor de sugestão ali. Vamos na direção oposta: projetamos toda a empresa para ser centrada em IA desde o primeiro dia.

Isso significa que a IA não é um recurso do produto. Ela molda como construímos, vendemos, apoiamos e operamos. Cada decisão que tomamos começa com uma pergunta: um agente pode fazer isso?

O próprio produto é um agente que vive em seu terminal, lê seus arquivos fonte, gera traduções, executa suas verificações de CI e itera até que a saída seja aprovada. Essa é a parte que as pessoas veem. Mas por trás, a mesma filosofia gerencia o negócio.

## Duas pessoas, zero sobrecarga organizacional

Estamos intencionalmente mantendo a equipe o mais pequena possível. Atualmente, somos apenas duas pessoas. Nosso objetivo é manter-nos com duas ou três pessoas por tanto tempo quanto pudermos.

Isso não é sobre economizar dinheiro (embora ajude). É sobre eliminar uma categoria inteira de trabalho que não produz valor para os usuários.

Quanto mais humanos você adiciona, mais coordenação você precisa. Você cria sistemas de confiança, modelos de permissão, cadeias de aprovação. Você gerencia conflitos, alinha prioridades, agenda reuniões. Tudo isso é energia criativa que vai para manter uma organização humana em vez de construir um produto.

Com duas pessoas, pulamos tudo isso. Confiamos plenamente um no outro. Temos acesso a tudo. Não há sobrecarga, não há política, não há processo por causa do processo.

A forma como tornamos isso funcionante em escala é delegando tudo o resto a agentes.

## Discord, um agente de IA e uma única linha de comando

Aqui está algo que pode soar incomum: nossa principal interface de negócios é um servidor [Discord](https://discord.com).

Temos um agente de IA conectado a ele, alimentado pela [OpenAI](https://openai.com), com acesso a todas as ferramentas necessárias para operar o negócio. Em vez de alternar entre painéis de controle web, plataformas de analytics e painéis administrativos, falamos com o agente. Texto e voz são a unidade de interação.

Através do agente, qualquer um de nós pode:

- Consultar analytics de marketing e de produto
- Inspecionar servidores de produção
- Realizar pesquisas de mercado
- Coletar feedback de clientes
- Realizar análise competitiva através da navegação na web
- Rascunhar conteúdo, revisar cópias e publicar

Nenhum de nós depende do outro para fazer qualquer uma dessas coisas. O agente tem acesso às nossas APIs, bancos de dados e ferramentas de monitoramento. Ele pode navegar na web, ler documentação e sintetizar informações. É um servidor Discord, uma instância do OpenAI e uma chave LLM. Esse é o sistema operacional da empresa.

> \[\!TIP\]
> Se você está montando uma pequena equipe e quer reduzir a sobrecarga de coordenação, considere fazer do texto e da voz sua interface primária para as operações do negócio. Um agente compartilhado em um canal de chat pode substituir dezenas de painéis e eliminar a necessidade da maioria das ferramentas internas.

## Escolhas tecnológicas intencionais

Somos muito intencionais sobre nosso stack porque isso afeta diretamente a velocidade com que podemos nos mover e a barateza com que podemos operar.

**Para o agente (CLI):** Escolhemos Go. Ele compila em binários únicos e portáteis entre plataformas, sem dependências de tempo de execução para o usuário.

**Para o servidor:** Escolhemos [Elixir](https://elixir-lang.org) e o runtime [Erlang](https://www.erlang.org). A natureza funcional do Elixir o torna excelente para cargas de trabalho agentic. O VM Erlang é testado e provado para concorrência e tolerância a falhas. E aqui está um bônus: um agente de IA pode introspecionar o sistema Erlang em execução para entender o que está acontecendo, coletar insights e até mesmo corrigir problemas em produção.

**Para a infraestrutura:** Tudo roda em um único VPS. Não apenas o servidor de produção do Glossia, mas todos os serviços periféricos também: [PostgreSQL](https://www.postgresql.org/) para o banco de dados, [Plausible](https://plausible.io) para analytics amigável à privacidade, [Grafana](https://grafana.com) para telemetria e observabilidade. Tudo é implantado a partir de definições de infraestrutura versionadas que descrevem onde e o que vai.

Isso mantém os custos extremamente baixos. Nós não dependemos de serviços de nuvem de terceiros, bancos de dados gerenciados ou provedores de platform-as-a-service. Temos algumas dependências externas, mas apenas para coisas que demorariam um longo tempo para replicar e onde o custo faz sentido.

Quando o tempo vier para escalar através de servidores, evoluiremos o modelo. Mas acreditamos que podemos ir muito longe com este setup. E ir rápido importa mais do que ir grande agora.

> \[\!IMPORTANT\]
> Somos muito deliberados ao pulsar complexidade técnica que engenheiros tendem a buscar cedo. Kubernetes, microserviços, implantações multi-região. Nenhuma dessas é necessária nesta fase, e todas elas nos dariam mais pesado.

## O que isso desbloqueia

Rodar a empresa desse jeito não é apenas uma jogada de eficiência. Muda o que podemos oferecer e a velocidade com que podemos aprender.

**Mais barato para os usuários.** A indústria de localização tornou suas ferramentas inacessíveis através de preços complexos, taxas por palavra e ciclos de vendas enterprise. Se seu fluxo de trabalho de tradução requer procurement, negociações de preço e um gerente de projetos, a maioria das pequenas equipes simplesmente lançará em inglês. Ao manter nossos custos operacionais perto de zero, podemos oferecer algo que é realmente acessível.

**Inovação mais rápida.** Queremos explorar muitas ideias. Novas interfaces para o agente, melhores loops de feedback, novas maneiras de trazer linguistas para o fluxo de trabalho. Uma empresa tradicional precisaria de pessoal, alinhar equipes e agendar revisões de roadmap. Nós apenas tentamos as coisas. A distância entre uma ideia e um experimento implantado é medida em horas, não trimestres.

## Desafiando como trabalhamos, não apenas o que construímos

Não estamos emocionalmente apegados às formas antigas de fazer as coisas. Estamos ativamente questionando o que significa a revisão de código quando um agente escreve a maior parte do código. Como a colaboração funciona quando existem apenas dois humanos. Como você corrige um bug quando o agente pode inspecionar o sistema em execução.

Cometemos erros. Continuaremos cometendo-os. Mas, mantendo-nos abertos a como projetamos e executamos o negócio, continuamos descobrindo ideias que influenciam o produto. A forma como operamos não é separada do que construímos. São a mesma coisa.

[McKinsey recentemente descreveu](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) o que eles chamam de "organização agêntica", um novo modelo operacional onde agentes de IA se tornam participantes de primeira classe na forma como uma empresa funciona. Não o vemos como um modelo. É apenas como trabalhamos.

## A aposta

Estamos apostando que uma equipe de duas pessoas com as ferramentas certas, a mentalidade correta e sem bagagem organizacional pode ultrapassar empresas com centenas de funcionários e milhões em financiamento. Não em todas as frentes, mas naquele que importa: entregar uma experiência de localização fundamentalmente superior.

A indústria não pode se reinventar. Nós podemos.