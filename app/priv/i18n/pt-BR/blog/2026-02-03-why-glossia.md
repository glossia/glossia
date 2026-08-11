%{
  title: "A localização ficou presa ao passado. Criamos a Glossia para levá-la adiante.",
  summary: "As ferramentas tradicionais de localização aumentam a sobrecarga, interrompem a CI e prendem você a ecossistemas de fornecedores. Estamos explorando como pode ser um fluxo de trabalho de localização baseado em agentes.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Se você já lançou um software em mais de um idioma, conhece bem o processo. Você escolhe uma plataforma de localização, conecta-a ao seu repositório e passa o restante do tempo gerenciando a sincronização. O conteúdo é enviado, as traduções retornam e, em algum ponto desse caminho, algo quebra.

Esse custo adicional, causado pelo trânsito constante de conteúdo entre seu repositório e a plataforma, é o preço que todas as equipes pagam para usar as ferramentas de localização atuais. Parece algo pequeno até você precisar descobrir por que um pull request de tradução interrompeu a compilação do site às 18h de uma sexta-feira.

## Um modelo herdado de antes da internet

A maioria das plataformas de localização foi projetada com base em conceitos anteriores ao fluxo de desenvolvimento moderno. Memórias de tradução. Correspondência aproximada. Tradutores humanos trabalhando em editores proprietários, com ferramentas que sugerem textos semelhantes armazenados em um banco de dados.

Essas ideias faziam sentido quando a tradução era um processo manual e realizado sem conexão com a internet. No entanto, as empresas transformaram as memórias de tradução em um mecanismo de dependência. Suas traduções anteriores, o conhecimento institucional pelo qual você pagou, ficam retidos na plataforma. Migrar para outro fornecedor significa começar do zero ou pagar por uma exportação que nunca funciona como deveria.

O resultado é um setor construído sobre barreiras artificiais. Seu conteúdo sai do repositório, entra em uma caixa-preta e retorna conforme o cronograma de outra empresa.

## O ciclo de feedback interrompido

O problema é estrutural: ferramentas externas de localização não conseguem executar seu pipeline de integração contínua. Elas não conhecem seus analisadores de código, sua etapa de compilação, seu verificador de links nem o esquema do front matter. Elas enviam o conteúdo traduzido de volta ao repositório e esperam que tudo funcione. Quando algo quebra, o que de fato acontece, alguém da equipe precisa interromper o próprio trabalho para corrigir problemas de formatação, erros de sintaxe ou marcação inválida introduzidos pela ferramenta de tradução.

Modelos de linguagem de grande escala e experiências baseadas em agentes estão criando novas oportunidades para repensarmos completamente esses fluxos de trabalho. Um agente pode gerar uma tradução, executar suas verificações, identificar um erro e tentar novamente até produzir uma saída válida. Esse tipo de ciclo de feedback imediato muda tudo.

Mas isso só funciona se o conteúdo permanecer onde está: em seu repositório. No momento em que você o envia para uma plataforma externa, as traduções passam a retornar conforme o cronograma de outra empresa e a integração é interrompida. O feedback que poderia ser imediato passa a levar horas ou dias. O contexto que o tornava útil já se perdeu. Você perde o ciclo e, com ele, toda a vantagem que os fluxos de trabalho baseados em agentes deveriam proporcionar.

## Observações que deram forma à Glossia

Essas frustrações não se transformaram em Glossia por conta própria. O projeto surgiu de uma experiência profunda tanto em desenvolvimento quanto em localização, o que trouxe clareza a problemas difíceis de perceber observando apenas um dos lados. Foi essencial compreender os fluxos de trabalho linguísticos, as dinâmicas humanas das equipes de tradução e os motivos que levaram as ferramentas existentes ao modelo atual.

Em conjunto, chegávamos sempre às mesmas observações: as ferramentas de localização foram projetadas para um mundo sem modelos de linguagem de grande escala, sem agentes de programação e sem pipelines de integração contínua. Todo o modelo partia do pressuposto de que a tradução acontecia fora do fluxo de desenvolvimento e depois era enviada de volta. Isso fazia sentido há dez anos. Hoje, não faz mais.

Começamos a perguntar: **e se os agentes de localização pudessem trabalhar da mesma forma que os agentes de programação?**

Temos acompanhado atentamente como a [Anthropic](https://anthropic.com) aborda fluxos de trabalho baseados em agentes com o Claude. O padrão de fornecer ferramentas a um agente, permitir que ele analise uma tarefa, valide a própria saída e faça novas tentativas quando algo estiver incorreto se aplica de forma particularmente adequada à localização. Um agente de tradução capaz de ler seus arquivos-fonte, compreender o contexto do projeto, gerar traduções, executar seu analisador de código e corrigir problemas antes de abrir um pull request. Isso não é uma fantasia. Esse é o fluxo de trabalho que estamos construindo.

## Glossia é a nossa contribuição para o setor de software

Criamos o Glossia porque queremos que mais softwares sejam localizados, não menos.

Processos complexos e plataformas caras tornam a localização inacessível para equipes pequenas, desenvolvedores independentes e projetos paralelos. Se o seu fluxo de trabalho de tradução exige um processo de compras, uma negociação de preço por palavra e um gerente de projeto para coordenar as transferências, a maioria das equipes simplesmente lançará o produto em inglês e dará o trabalho por concluído.

O Glossia utiliza modelos aos quais você já tem acesso. E valida o resultado com as suas próprias ferramentas, não com as nossas.

Acreditamos que a localização deve ser tão natural quanto executar a sua suíte de testes.

## Primeiro o agente, depois as interfaces

Em sua essência, o Glossia é um agente. Estamos começando com o terminal como sua interface principal porque é nele que os problemas mais difíceis são resolvidos primeiro: ler os seus arquivos de origem, gerar traduções, executar as suas verificações e iterar até que o resultado seja válido. Esse é o mesmo padrão adotado pela [OpenAI](https://openai.com) com o [Codex](https://openai.com/index/openai-codex/) e pela [Anthropic](https://anthropic.com) com o [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Você cria o agente, fornece um terminal e permite que ele trabalhe.

Mas o terminal é apenas a primeira interface, não a única. Sabemos que nem todas as pessoas que contribuem para a qualidade da localização são desenvolvedoras. Falamos sobre isso com frequência internamente. As pessoas que mais se importam com a precisão da tradução, o tom e as nuances culturais geralmente são linguistas e especialistas em conteúdo que não trabalham em termos de branches, compilação ou JSON.

Por isso, queremos criar novas interfaces sobre o mesmo agente. Algo em que um linguista veja o conteúdo, o contexto e a tradução lado a lado. Essas pessoas contribuem com o julgamento humano que nenhum modelo pode substituir. Elas refinam o que precisa ser refinado. E o agente cuida de todo o restante: criar commits, validar e abrir o pull request.

Ainda não temos todas as respostas, e isso é intencional. Preferimos construir isso de forma criteriosa em vez de nos apressarmos para criar uma interface de usuário que não atenda ao objetivo. Mas a direção está clara: o Glossia deve acolher todas as pessoas que se importam em fazer o software falar todos os idiomas.

## Acompanhe as novidades

O Glossia ainda está em uma fase inicial, e estamos desenvolvendo o projeto de forma aberta. Se algo disso estiver alinhado à sua visão sobre localização, acompanhe o projeto. Compartilharemos mais novidades à medida que avançarmos.