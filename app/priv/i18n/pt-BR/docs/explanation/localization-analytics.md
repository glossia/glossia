%{
  title: "Por que a análise de localização",
  summary:
    "Como os sinais coletados se transformam em decisões de localização e por que a métrica de lacuna importa.",
  category: "explicação",
  section: "analytics",
  order: 2
}
---

Escolher para que idioma traduzir no próximo é uma aposta: custa tempo e dinheiro, e o retorno depende de uma demanda que geralmente você não consegue ver. A análise de localização torna essa demanda visível.

## A decisão, não o painel

O objetivo de coletar análises aqui é estreito e deliberado: responder "devemos localizar no idioma X?" Os sinais são escolhidos para alimentar essa pergunta, não para serem um conjunto de análises de uso geral.

Três entradas algamparam a decisão:

1. **Demanda.** Quantos visitantes querem este idioma? Os idiomas do navegador e o país indicam onde está o interesse.
2. **A lacuna.** Essa demanda já está sendo atendida? Comparando idiomas preferidos com os idiomas-alvo do projeto, o idioma da página e suas traduções anunciadas revela a parte do tráfego que bate em um muro.
3. **Valor.** A localização valerá a pena? O engajamento por lacuna de idioma, as páginas onde o tráfego inservido aterrissa e de onde esse tráfego vem indicam se um novo idioma converte.

## Por que a lacuna é calculada no momento de ingestão

`served_locale` registra a linguagem real da página declarada em `<html lang>`, não a linguagem que supomos que o visitante recebeu. `has_locale_gap` compara preferências do navegador com os idiomas-alvo do seu projeto, o idioma da página e traduções anunciadas através de `hreflang` links. Ambos são armazenados por evento conforme eram no momento da visita. Isso significa que os dados históricos refletem a oportunidade que você enfrentou então, não uma recomputação contra os alvos de hoje. Se você adicionar o português no próximo mês, a lacuna do mês passado não diminui retroativamente; você mantém um registro honesto de quanto demanda estava sem atendimento.

## Por que sem cookies, especificamente

O instinto quando você quer "visitantes únicos" é definir um cookie ou fingerprintar o navegador. Ambos criam identificadores de vida longa, e fingerprinting é, sob a maioria dos regimes de privacidade, mais difícil de limpar do que um cookie. Nenhum é necessário aqui.

Visitantes únicos para um dia exigem apenas um identificador estável *dentro do mesmo dia*. Um hash do IP e User-Agent, rotacionado diariamente e limitado ao projeto, suporta contagens diárias de visitantes enquanto torna impossível vincular um visitante entre dias ou entre sites. Isso não fornece rastreamento de longo prazo de visitantes recorrentes.

Este design limita os identificadores retidos por análises. Não estabelece se um site em questão exige consentimento; isso depende de como o site usa análises e das regras que se aplicam a ele.
