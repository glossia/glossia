%{
  title: "Por que usar análises de localização",
  summary: "Como os sinais coletados se transformam em decisões de localização e por que a métrica de lacuna é importante.",
  category: "explanation",
  order: 2
}
---
Escolher o próximo idioma para o qual traduzir é uma aposta: exige tempo e dinheiro, e o retorno depende de uma demanda que normalmente não é possível observar. A análise de localização torna essa demanda visível.

## A decisão, não o painel

O objetivo da coleta de dados analíticos aqui é específico e deliberado: responder à pergunta "devemos localizar para o idioma X?". Os indicadores foram escolhidos para fundamentar essa decisão, não para compor uma solução de análise de propósito geral.

Três fatores orientam a decisão:

1. **Demanda.** Quantos visitantes querem esse idioma? Os idiomas do navegador e o país indicam onde está o interesse.
2. **A lacuna.** Essa demanda já é atendida? Comparar os idiomas preferidos com os idiomas de destino do projeto revela a parcela do tráfego que encontra uma barreira.
3. **Valor.** A localização traria retorno? O engajamento por lacuna de localidade, as páginas acessadas pelo tráfego não atendido e a origem desse tráfego indicam se uma nova localidade gera conversões.

## Por que a lacuna é calculada no momento da ingestão

`served_locale` e `has_locale_gap` são armazenados por evento e calculados com base nos idiomas de destino definidos no momento da visita. Isso significa que os dados históricos refletem a oportunidade existente naquela ocasião, não um novo cálculo baseado nos idiomas de destino atuais. Se você adicionar português no próximo mês, a lacuna do mês passado não diminuirá retroativamente. Assim, você mantém um registro fiel da demanda que não estava sendo atendida.

## Por que, especificamente, não usar cookies

Ao buscar identificar "visitantes únicos", a reação inicial costuma ser definir um cookie ou criar uma impressão digital do navegador. Ambas as abordagens criam identificadores de longa duração e, na maioria dos regimes de privacidade, a impressão digital é mais difícil de remover do que um cookie. Nenhuma delas é necessária aqui.

A contagem de visitantes únicos em um dia exige apenas um identificador estável *durante esse dia*. Um hash do endereço de Protocolo de Internet (IP) e do User-Agent, alternado diariamente e restrito a cada projeto, fornece contagens precisas de visitantes únicos diários e semanais, além de impedir a associação de um visitante entre dias ou sites diferentes. Abre-se mão do acompanhamento de visitantes recorrentes no longo prazo, justamente a capacidade que gera a exposição de privacidade que, de outra forma, exigiria um banner de consentimento para operar legalmente.

Essa escolha é intencional: a análise de localização deve poder ser disponibilizada em qualquer lugar, para todos os visitantes, sem entraves jurídicos.