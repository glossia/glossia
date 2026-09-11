%{
  title: "Por que as análises de localização",
  summary:
    "Como os sinais coletados se traduzem em decisões de localização e por que a métrica de lacuna importa.",
  category: "explicação",
  order: 2
}
---
Escolher qual idioma traduzir a seguir é uma aposta: custa tempo e dinheiro, e o retorno depende da demanda que geralmente você não vê. Análise de localização torna essa demanda visível.

## A decisão, não o painel

O objetivo de coletar análises aqui é estreito e deliberado: para responder "devemos localizar para o idioma X?" Os sinais são escolhidos para alimentar essa pergunta, não para ser uma suite de análises de uso geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes desejam este idioma? Os idiomas do navegador e o país indicam onde o interesse está.
2. **A lacuna.** Essa demanda já está atendida? Comparar idiomas preferidos contra os idiomas de destino do seu projeto revela a parte do tráfego que esbarra em um muro.
3. **Valor.** Vale a pena traduzir? O gap de engajamento por local, as páginas onde o tráfego não atendido aterrissa e a origem desse tráfego indicam se um novo local converte.

## Por que o gap é calculado no momento da ingestão

`served_locale` e `has_locale_gap` são armazenados por evento, calculados em relação aos seus idiomas-alvo conforme eles eram no momento da visita. Isso significa que os dados históricos refletem a oportunidade que você enfrentou na época, não uma recomputação contra os alvos de hoje. Se você adicionar o Português no próximo mês, o gap do mês passado não diminui retroativamente; você mantém um registro honesto de quanto da demanda estava sem atendimento.

## Por que sem cookie, especificamente

O instinto quando você quer "visitantes únicos" é definir um cookie ou criar uma impressão digital do navegador. Ambos criam identificadores de longa duração, e criar uma impressão digital é, sob a maioria dos regimes de privacidade, mais difícil de limpar do que um cookie. Nenhum é necessário aqui.

Visitantes únicos por dia exigem apenas um identificador estável. *dentro do dia*. Um hash do IP e User-Agent, rotacionado diariamente e limitado por projeto, fornece visitantes únicos precisos diários e semanais, tornando impossível vincular um visitante entre dias ou entre sites. Você abre mão do rastreamento de longo prazo de visitantes recorrentes, que é exatamente a capacidade que cria a exposição de privacidade para a qual você normalmente precisaria de um banner de consentimento para operar legalmente.

A compensação é intencional: as análises de localização devem ser algo que você possa distribuir em todos os lugares, para cada visitante, sem atrito legal.