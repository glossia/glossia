%{
  title: "O sistema operacional que faltava para a linguagem",
  summary: "O software tem frameworks, sistemas de design e Git. A linguagem não tem... nada. Acreditamos que chegou a hora de criar o sistema operacional no qual linguistas assumem a liderança e as organizações finalmente tratam o conteúdo com o mesmo cuidado que dedicam ao código.",
  date: ~D[2026-02-16],
  slug: "2026-02-16-the-missing-os-for-language",
  author: "pedro"
}
---
Pense em quanto o software avançou ao oferecer às equipes ferramentas compartilhadas para trabalhar de forma consistente. [Frameworks](https://en.wikipedia.org/wiki/Software_framework) permitem que os desenvolvedores expressem a lógica por meio de padrões previsíveis. [Sistemas de design](https://en.wikipedia.org/wiki/Design_system) permitem que designers e engenheiros compartilhem uma linguagem visual em todas as telas e superfícies. O [Git](https://en.wikipedia.org/wiki/Git) forneceu uma base para colaboração, versionamento e revisão que o [GitHub](https://github.com) e o [GitLab](https://gitlab.com) transformaram em algo usado diariamente por milhões de pessoas.

> [!NOTE]
> Se você não desenvolve software: o [Git](https://en.wikipedia.org/wiki/Git) é um sistema de [controle de versão](https://en.wikipedia.org/wiki/Version_control), uma ferramenta que registra cada alteração feita em um conjunto de arquivos para que as equipes possam colaborar sem sobrescrever o trabalho umas das outras. Pense nele como o recurso "Controlar Alterações" de um processador de texto, mas aplicado a projetos inteiros. O [GitHub](https://github.com) e o [GitLab](https://gitlab.com) são plataformas desenvolvidas sobre o Git que facilitam a proposta de alterações, a revisão do trabalho entre as pessoas e a discussão de melhorias antes de aceitá-las.

Agora pense na linguagem. Nas palavras que seu produto usa para se comunicar com as pessoas. No tom das suas mensagens de erro. Em como seu texto de marketing soa em japonês e em como soa em alemão. Na terminologia usada pela sua equipe de suporte em comparação com a apresentada na interface do produto.

Não existe um sistema compartilhado para nada disso. Nenhum framework. Nenhum sistema de design. Nenhum Git. Nada.

## Nunca construímos a infraestrutura

Não é que as teorias não existam. A linguística é um campo rico. O conceito de [equivalência dinâmica](https://en.wikipedia.org/wiki/Dynamic_equivalence), de [Eugene Nida](https://en.wikipedia.org/wiki/Eugene_Nida), ensinou-nos que uma boa tradução não consiste em substituir palavras, mas em recriar a mesma relação percebida entre o leitor e a mensagem. Análise do discurso, pragmática, sociolinguística: todas essas disciplinas dedicaram décadas a compreender como a linguagem funciona em seu contexto. A base intelectual existe.

Mas ninguém construiu um sistema em torno dela.

Quando a internet surgiu, as empresas de localização transferiram seus aplicativos proprietários de desktop para o navegador. O modelo subjacente permaneceu o mesmo: [memórias de tradução](https://en.wikipedia.org/wiki/Translation_memory), [correspondência aproximada](https://en.wikipedia.org/wiki/Fuzzy_matching_(computer-assisted_translation)), cobrança por palavra. Elas continuaram construindo sobre a mesma base e, quando a tradução automática melhorou, apenas a adicionaram por cima. Sem repensar, sem reinventar. Apenas o mesmo fluxo de trabalho com um mecanismo mais rápido por baixo.

Então vieram os intermediários.

Entre você, a pessoa ou empresa que possui o conteúdo, e o linguista, a pessoa que realmente entende de linguagem, surgiu todo um setor de intermediários. Plataformas de integração. Sistemas de gestão de tradução. Agências de tradução. Camadas de garantia de qualidade. Painéis de gestão de projetos. Cada um adiciona complexidade e fica com uma parte da receita. A pessoa que agrega mais valor, o linguista que contribui com consciência cultural, precisão terminológica e discernimento criativo, acaba no final da cadeia, recebendo a menor remuneração.

[Relatórios do setor](https://traductoresnativos.com/en/translation-agencies-2025-summary-2026/) mostram que as tarifas de pós-edição de inteligência artificial podem cair para 50% a 70% dos já modestos valores cobrados por palavra, enquanto as agências ainda solicitam descontos adicionais de 30% a 40%. A cadeia de fornecimento pressiona justamente as pessoas das quais mais depende.

## Um sinal de que algo está faltando

Eis um sinal de que as ferramentas atuais não são suficientes: as empresas estão criando uma função chamada ["Gerente de Idioma"](https://slator.com/10-language-jobs-big-tech-is-hiring-for-right-now/). São profissionais cujo trabalho consiste integralmente em manter a terminologia, supervisionar os fluxos de trabalho de tradução, garantir a consistência terminológica e coordenar a colaboração entre linguistas, equipes de produto e departamentos de marketing.

A existência dessa função é um sinal. Ela indica que as organizações precisam de consistência linguística em todos os seus canais, mas as ferramentas disponíveis não oferecem isso. Por esse motivo, contratam uma pessoa para conectar todas as partes.

Esses profissionais acabam presos em uma dicotomia desconfortável. Por um lado, podem solicitar recursos de engenharia para desenvolver um sistema interno, mas isso exige um investimento muito alto em algo que não faz parte da atividade principal da empresa. Por outro, podem procurar uma ferramenta externa, mas ninguém desenvolveu uma solução realmente abrangente para essa necessidade. O que existe são componentes menores e desconectados, que eles mesmos precisam orquestrar e integrar. Nenhuma das opções é satisfatória.

É exatamente essa lacuna que um sistema deve preencher. Não substituindo o Gerente de Idioma, mas oferecendo a ele, e a todos os linguistas com quem trabalha, um sistema operacional adequado para realizar seu trabalho.

## O que estamos desenvolvendo com a Glossia

Acreditamos que a resposta se parece menos com uma ferramenta de tradução e mais com o que o GitHub fez pelo código.

O GitHub transformou o Git, um sistema para rastrear alterações em arquivos, em uma plataforma colaborativa na qual desenvolvedores revisam o trabalho uns dos outros, discutem alterações e aprimoram o resultado em conjunto. Antes do GitHub, contribuir com projetos de software exigia o envio de arquivos por e-mail. Depois do GitHub, qualquer pessoa com uma conta passou a poder participar.

Queremos fazer o mesmo pela linguagem.

A Glossia é o sistema operacional no qual as organizações registram suas preferências linguísticas, sua voz, sua terminologia, seu tom e as expectativas de seu público. É também onde os linguistas ocupam uma posição central no aprimoramento dessas preferências. Não no final de uma cadeia. Não atrás de três camadas de intermediários. No centro.

Abordamos esse tema em nossa publicação sobre [o grafo de contexto](https://glossia.ai/blog/2026-02-15-context-graph): estamos desenvolvendo um mapa estruturado de conhecimentos conectados que registra, ao longo do tempo, tudo o que uma organização sabe sobre sua linguagem. Definições de voz, entradas de terminologia, perfis de público e regras de formalidade. Cada elemento é versionado, permitindo identificar o que mudou e quando, e conectado a tudo que se relaciona a ele. Quando algo muda, o sistema sabe exatamente qual conteúdo foi afetado e o que precisa ser revisado.

Esta é a sua conta na Glossia e os diversos projetos com os quais você pode contribuir. Um linguista pode trabalhar com várias organizações, aplicar sua experiência em diferentes contextos e acompanhar como o impacto de suas decisões se propaga pelo sistema. Assim como um desenvolvedor contribui com vários projetos no GitHub, um linguista na Glossia pode definir como dezenas de produtos se comunicam.

## A inteligência artificial como amplificadora, não como substituta

A narrativa predominante sobre inteligência artificial e linguagem é centrada na substituição. Mais rapidez, menos custos, menos pessoas. Acreditamos que essa visão está profundamente equivocada e, francamente, desrespeita a profundidade da experiência que os linguistas oferecem.

Nossa perspectiva é diferente. A inteligência artificial é uma ferramenta executada em um sistema moldado pela contribuição linguística. Ela não substitui o linguista. Ela amplia o que os linguistas tornam possível.

Quando um linguista aprimora uma definição de voz na Glossia, esse refinamento é aplicado a todo conteúdo processado pelo sistema. Quando um terminólogo atualiza uma entrada de terminologia, essa atualização é refletida na próxima vez que qualquer agente gerar ou transformar conteúdo para essa organização. A decisão humana é multiplicada por centenas ou milhares de resultados. Esse nível de impacto nunca esteve disponível antes.

A tradução é o caso de uso mais evidente e foi por onde começamos. Mas não é o único. Depois que uma organização constrói um grafo de contexto rico, repleto da memória linguística desenvolvida por sua equipe de linguistas ao longo de meses e anos, as possibilidades se ampliam:

- Uma equipe de marketing pode conectar suas ferramentas de escrita a este sistema operacional por meio do [Protocolo de Contexto de Modelo](https://modelcontextprotocol.io/), um padrão que permite que ferramentas de inteligência artificial se comuniquem com sistemas externos, e garantir que todas as campanhas sigam a terminologia e a voz da empresa.
- Uma equipe de produto pode validar se os textos da interface correspondem ao tom definido para seu público.
- Uma equipe de suporte pode gerar respostas que tenham a voz da marca, não a de um chatbot genérico.

O conhecimento linguístico se torna um recurso compartilhado, como um sistema de design, mas voltado à linguagem.

## Linguistas merecem ferramentas melhores

Se você é linguista ou tradutor e está lendo isto, quero que saiba que este projeto existe por sua causa, não apesar de você.

O setor de localização passou anos afastando você cada vez mais das pessoas e organizações que atende. Transformou seu trabalho em commodity, reduziu sua remuneração e tratou sua especialização como algo secundário em um fluxo otimizado para o volume de produção.

Acreditamos que linguistas devem participar diretamente da maneira como as organizações se comunicam. Você compreende registro, pragmática, contexto cultural e as diferenças sutis entre o que uma frase diz e o que ela significa. Nenhum modelo pode substituir isso. Mas um sistema pode fazer com que suas contribuições alcancem mais pessoas, permaneçam relevantes por mais tempo e influenciem muito mais do que qualquer tradução isolada poderia influenciar.

Estamos desenvolvendo o Glossia para que sua especialização seja a base sobre a qual todo o restante funciona. Não uma etapa no fim de uma cadeia. A base.

## O que vem a seguir

Ainda estamos no início. Começamos pelo [agente de linha de comando](https://glossia.ai/docs), uma ferramenta com a qual você interage digitando comandos em um terminal em vez de clicar em botões em uma interface visual, porque é nesse ambiente que estão os problemas de infraestrutura mais difíceis: ler arquivos de origem, gerar resultados, validar com suas próprias ferramentas e fechar o ciclo de feedback. Mas, como descrevemos em nossa [primeira publicação](https://glossia.ai/blog/2026-02-03-why-glossia), o terminal é a primeira interface, não a única.

Estamos projetando experiências nas quais linguistas possam visualizar conteúdo e contexto lado a lado, aprimorar definições de voz em sessões colaborativas e acompanhar suas decisões se propagarem pelo sistema em tempo real. Queremos que a experiência de contribuir com conhecimento linguístico seja tão natural e gratificante quanto contribuir com código no GitHub.

Se alguma parte disso fizer sentido para você, seja você um linguista que se sente colocado em segundo plano pelas ferramentas que precisa usar, um gerente de idiomas em busca do sistema que gostaria que existisse ou apenas alguém que acredita que a maneira como falamos importa tanto quanto a maneira como construímos, gostaríamos muito de ouvir você. Participe do nosso [Discord](https://discord.gg/7FRHkwvs) ou acompanhe o [blog](https://glossia.ai/blog). A conversa está apenas começando.