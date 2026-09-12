%{
  title: "Por que a análise de localização",
  summary:
    "Como os sinais coletados se traduzem em decisões de localização, e por que a métrica de lacuna importa.",
  category: "explicação",
  order: 2
}
---
Escolher o próximo idioma para traduzir é uma aposta: custa tempo e dinheiro, e o retorno depende de uma demanda que geralmente não é visível. A análise de localização torna essa demanda visível.

## A decisão, não o painel

O propósito de coletar análises aqui é estreito e deliberado: para responder "devemos traduzir para o idioma X?" Os sinais são escolhidos para alimentar essa pergunta, não para ser uma suíte de análise de propósito geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes desejam este idioma? Os idiomas do navegador e o país indicam onde o interesse está.
2. **A lacuna.** Essa demanda já é atendida? Comparar os idiomas preferidos com os idiomas-alvo do seu projeto revela a parcela do tráfego que encontra barreiras.
3. **Valor.** Vale a pena localizar? O gap de engajamento por localidade, as páginas onde o tráfego não atendido chega, e a origem desse tráfego indicam se uma nova localidade converte.

## Por que o gap é calculado no momento da ingestão

`served_locale` e `has_locale_gap` armazenados por evento, calculados em relação aos seus idiomas alvo conforme eles eram no momento da visita. Isso significa que os dados históricos refletem a oportunidade que você enfrentou na época, não uma recomputação contra os alvos de hoje. Se você adicionar Português no próximo mês, o gap do mês passado não encolhe retroativamente; você mantém um registro honesto de quanto demanda estava sem atendimento.

## Por que sem cookies, especificamente

O instinto quando você quer "visitantes únicos" é definir um cookie ou criar uma impressão digital do navegador. Ambos criam identificadores de longa duração, e a impressão digital é, sob a maioria dos regimes de privacidade, mais difícil de limpar do que um cookie. Nenhum dos dois é necessário aqui.

Visitantes únicos para um dia exigem apenas um identificador que seja estável *dentro do dia*. Um hash do IP e User-Agent, rotacionado diariamente e com escopo por projeto, fornece contagens únicas diárias e semanais precisas, tornando impossível vincular um visitante através de dias ou sites. Você abre mão do rastreamento de visitantes retornantes de longo prazo, que é exatamente a capacidade que cria a exposição de privacidade para a qual você normalmente precisaria de um banner de consentimento para operar legalmente.

A compensação é intencional: os analytics de localização devem ser algo que você possa implementar em qualquer lugar, para cada visitante, sem atrito legal.