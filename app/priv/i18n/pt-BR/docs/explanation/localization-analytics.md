%{
  title: "Por que as análises de localização",
  summary:
    "Como os sinais coletados se traduzem em decisões de localização e por que a métrica de lacuna importa.",
  category: "explicação",
  order: 2
}
---
Escolher para qual idioma traduzir a seguir é uma aposta: custa tempo e dinheiro, e o retorno depende da demanda que geralmente não é visível. As análises de localização tornam essa demanda visível.

## A decisão, não o painel

O propósito de coletar análises aqui é estreito e deliberado: para responder "deveríamos adaptar para o idioma X?" Os sinais são escolhidos para alimentar essa pergunta, não para ser uma suíte de análises de propósito geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes desejam este idioma? Os idiomas do navegador e o país indicam onde está o interesse.
2. **A lacuna.** Essa demanda já está atendida? Comparar os idiomas preferidos contra os idiomas de destino do seu projeto revela a proporção de tráfego que esbarra em uma parede.
3. **Valor.** Vale a pena localizar? A lacuna de engajamento por local, as páginas onde o tráfego com demanda insatisfeita aterrissa e a origem desse tráfego indicam se uma nova local converte.

## Por que a lacuna é computada no momento da ingestão

`served_locale` e `has_locale_gap` são armazenadas por evento, computadas contra seus idiomas de destino conforme eram no momento da visita. Isso significa que os dados históricos refletem a oportunidade que você enfrentou naquela época, não uma recomputação contra os objetivos de hoje. Se você adicionar o português mês que vem, a lacuna do mês passado não encolhe retroativamente; você mantém um registro honesto de quanto demanda estava sem atendimento.

## Por que sem cookie, especificamente

O instinto ao querer "visitantes únicos" é definir um cookie ou identificar a impressão digital do navegador. Ambos criam identificadores de longa duração, e a identificação por impressão digital é, sob a maioria dos regimes de privacidade, mais difícil de limpar do que um cookie. Nenhum deles é necessário aqui.

Visitantes únicos por dia exigem apenas um identificador que seja estável. *dentro do dia*. Um hash do IP e do User-Agent, atualizado diariamente e limitado por projeto, fornece contagens precisas de visitantes únicos diários e semanais, tornando impossível vincular um visitante entre dias ou entre sites. Você abre mão do rastreamento de longo prazo de visitantes recorrentes, que é exatamente a capacidade que cria a exposição de privacidade para a qual você precisaria de um banner de consentimento para operar legalmente.

A contrapartida é intencional: as análises de localização devem ser algo que você possa implementar em todos os lugares, para cada visitante, sem entraves legais.