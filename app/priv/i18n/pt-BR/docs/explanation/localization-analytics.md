%{
  title: "Por que a análise de localização",
  summary:
    "Como os sinais coletados se transformam em decisões de localização e por que a métrica de lacuna importa.",
  category: "explicação",
  order: 2
}
---
Escolher para qual idioma traduzir a seguir é uma aposta: custa tempo e dinheiro, e o retorno depende da demanda que geralmente você não consegue ver. As análises de localização tornam essa demanda visível.

## A decisão, não o painel

O propósito de coletar análises aqui é restrito e deliberado: para responder "devemos localizar para o idioma X?" Os sinais são escolhidos para alimentar essa questão, não para ser uma suíte de análises de propósito geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes desejam este idioma? A língua do navegador e o país indicam onde está o interesse.
2. **A lacuna.** Essa demanda já está atendida? Comparando idiomas preferidos com os idiomas-alvo do seu projeto revela a fração do tráfego que esbarra em um muro.
3. **Valor.** Vale a pena localizar? O gap de engajamento por idioma, as páginas nas quais o tráfego não atendido aterrissa e a origem desse tráfego indicam se um novo idioma converte.

## Por que o gap é computado no momento da ingestão

`served_locale` e `has_locale_gap` e são armazenados por evento, computados contra os idiomas de destino conforme eram no momento da visita. Isso significa que os dados históricos refletem a oportunidade que você enfrentou naquela época, não uma recomputação contra os alvos de hoje. Se você adicionar Português no próximo mês, o gap do mês passado não diminui retroativamente; você mantém um registro honesto de quanto da demanda permanecia não atendida.

## Por que sem cookie, especificamente

O instinto quando você quer "visitantes únicos" é definir um cookie ou fingerprintar o navegador. Ambos criam identificadores de longa duração, e o fingerprinting é, na maioria dos regimes de privacidade, mais difícil de remover do que um cookie. Nenhum é necessário aqui.

Visitantes únicos em um dia exigem apenas um identificador que seja estável *dentro do dia*. Uma hash do IP e User-Agent, rotacionada diariamente e com escopo por projeto, fornece contagens precisas de visitantes únicos diários e semanais, tornando impossível vincular um visitante entre dias ou entre sites. Você abre mão do rastreamento de longo prazo de visitantes que retornam, que é exatamente a capacidade que cria a exposição de privacidade na qual você precisaria de um banner de consentimento para operar legalmente.

A compensação é intencional: as análises de localização devem ser algo que você possa distribuir em qualquer lugar, para cada visitante, sem atrito legal.