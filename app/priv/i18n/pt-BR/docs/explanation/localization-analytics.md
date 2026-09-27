%{
  title: "Por que análises de localização",
  summary:
    "Como os sinais coletados se traduzem em decisões de localização e por que a métrica da lacuna importa.",
  category: "Explicação",
  section: "Análises",
  order: 2
}
---
Escolher para qual idioma traduzir a seguir é uma aposta: custa tempo e dinheiro, e o retorno depende da demanda que você geralmente não consegue ver. As análises de localização tornam essa demanda visível.

## A decisão, não o painel

O objetivo de coletar análises aqui é específico e deliberado: para responder "deveríamos localizar para o idioma X?" Os sinais são escolhidos para alimentar essa pergunta, não para ser uma suíte de análises de propósito geral.

Três fatores impulsionam a decisão:

1. **Demanda.** Quantos visitantes desejam este idioma? Os idiomas do navegador e o país indicam onde está o interesse.
2. **A lacuna.** Essa demanda já está atendida? Comparar os idiomas preferidos com os idiomas-alvo do projeto revela a proporção de tráfego que encontra uma barreira.
3. **Valor.** Vale a pena localizar? O gap de engajamento por localização, as páginas onde o tráfego não atendido termina e a origem deste tráfego indicam se um novo locale converte.

## Por que o gap é computado no momento da ingestão

`served_locale` e `has_locale_gap` são armazenados por evento, computados contra seus idiomas alvo conforme eram no momento da visita. Isso significa que os dados históricos refletem a oportunidade que você enfrentou naquela época, e não uma recomputação contra os alvos de hoje. Se você adicionar o Português no próximo mês, o gap do mês passado não diminui retroativamente; você mantém um registro honesto de quanto da demanda estava sem atendimento.

## Por que sem cookies, especificamente

O instinto quando você quer "visitantes únicos" é definir um cookie ou fingerprintar o navegador. Ambos criam identificadores de longa duração, e o fingerprinting é, sob a maioria dos regimes de privacidade, mais difícil de limpar que um cookie. Nenhum é necessário aqui.

Visitantes únicos para um dia exigem apenas um identificador estável *dentro do dia*. Um hash do IP e do User-Agent, rotacionado diariamente e limitado ao projeto, fornece contagens de visitantes únicos diárias e semanais precisas, tornando impossível vincular um visitante entre dias ou entre sites. Você abre mão do rastreamento de longo prazo de visitantes recorrentes, que é exatamente a capacidade que cria a exposição de privacidade pela qual, de outra forma, você precisaria de um banner de consentimento para operar legalmente.

A troca é intencional: as análises de localização devem ser algo que você possa distribuir em todos os lugares, para cada visitante, sem atrito legal.