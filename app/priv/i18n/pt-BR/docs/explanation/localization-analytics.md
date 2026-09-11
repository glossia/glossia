%{
  title: "Por que a análise de localização",
  summary:
    "Como os sinais coletados se traduzem em decisões de localização e por que a métrica de lacuna importa.",
  category: "Explicação",
  order: 2
}
---
Escolher para qual idioma traduzir a seguir é uma aposta: custa tempo e dinheiro, e o retorno depende de uma demanda que você geralmente não consegue ver. A análise de localização torna essa demanda visível.

## A decisão, não o painel

O objetivo de coletar análises aqui é específico e deliberado: responder à pergunta "devemos localizar para o idioma X?" Os sinais são escolhidos para alimentar essa dúvida, não para ser uma suite de análises de propósito geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes desejam esse idioma? Os idiomas do navegador e o país indicam onde está o interesse.
2. **A lacuna.** Essa demanda já está sendo atendida? Comparar os idiomas preferidos com os idiomas-alvo do seu projeto revela a parcela do tráfego que encontra barreira.
3. **Valor.** A localização vale a pena? A lacuna de engajamento por localização, as páginas onde o tráfego subatendido aterrissa e a origem desse tráfego indicam se uma nova localização converte.

## Por que o gap é computado no tempo de ingestão

`served_locale` e `has_locale_gap` são armazenados por evento, computados contra os idiomas alvo conforme eram no momento da visita. Isso significa que dados históricos refletem a oportunidade que você enfrentou então, não uma recomputação contra os alvos atuais. Se você adicionar o português no próximo mês, o gap do mês passado não diminui retroativamente; você mantém um registro honesto de quanto da demanda estava subatendida.

## Por que sem cookies, especificamente

O instinto quando você quer "visitantes únicos" é definir um cookie ou fingerprintar o navegador. Ambos criam identificadores de longa duração, e o fingerprint é, sob a maioria dos regimes de privacidade, mais difícil de limpar do que um cookie. Nenhum é necessário aqui.

Visitantes únicos por dia exigem apenas um identificador estável. *dentro do dia*. Um hash do IP e User-Agent, renovado diariamente e limitado por projeto, fornece visitantes únicos precisos diariamente e semanalmente, tornando impossível vincular um visitante entre dias ou entre sites. Você abre mão do rastreamento de retorno de longo prazo, que é exatamente a capacidade que cria a exposição de privacidade pela qual você precisaria de um banner de consentimento para operar legalmente.

A compensação é intencional: as análises de localização devem ser algo que você possa lançar em qualquer lugar, para cada visitante, sem atrito legal.