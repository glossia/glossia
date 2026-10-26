%{
  title: "Por que as análises de localização",
  summary:
    "Como os sinais coletados se traduzem em decisões de localização e por que a métrica de lacuna importa.",
  category: "explicação",
  section: "analytics",
  order: 2
}
---

Escolher em que língua traduzir a seguir é uma aposta: custa tempo e dinheiro, e o retorno depende da demanda que você geralmente não consegue ver. A análise de localização torna essa demanda visível.

## ## A decisão, não o painel

O objetivo de coletar análises aqui é estreito e deliberado: responder "devemos traduzir para o idioma X?". Os sinais são escolhidos para alimentar essa pergunta, não para funcionarem como um conjunto de análises de uso geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes desejam este idioma? Os idiomas do navegador e o país indicam onde está o interesse.
2. **A lacuna.** Essa demanda já está sendo atendida? Comparar os idiomas preferidos contra os idiomas alvo do seu projeto, o idioma da página e suas traduções anunciadas revela a parcela do tráfego que encontra uma barreira.
3. **Valor.** A localização compensa? O engajamento pela lacuna de localização, as páginas onde o tráfego não atendido pousa, e a origem desse tráfego indicam se uma nova localização converte.

## Por que a lacuna é computada no momento da ingestão

O `served_locale` registra o idioma real da página declarado em `<html lang>`, não o idioma que presumimos que o visitante recebeu. `has_locale_gap` compara as preferências do navegador contra os alvos do seu projeto, o idioma da página e as traduções anunciadas através de links `hreflang`. Ambos são armazenados por evento conforme existiam no momento da visita. Isso significa que os dados históricos refletem a oportunidade que você enfrentou naquela época, não uma recomputação contra os alvos de hoje. Se você adicionar o português no próximo mês, a lacuna do mês passado não encolhe retroativamente; você mantém um registro honesto de quanto da demanda estava sem atendimento.

## Por que cookieless, especificamente

O instinto quando se quer "visitantes únicos" é definir um cookie ou fingerprintar o navegador. Ambos criam identificadores de longa duração, e o fingerprinting é, sob a maioria dos regimes de privacidade, mais difícil de limpar que um cookie. Nenhum é necessário aqui.

Visitantes únicos para um dia exigem apenas um identificador que seja estável *dentro do dia*. Uma hash do IP e User-Agent, rotacionada diariamente e scoped por projeto, suporta contagens diárias de visitantes enquanto torna impossível vincular um visitante ao longo de dias ou entre sites. Isso não oferece rastreamento de retorno de longo prazo.

Este design limita os identificadores retidos pela análise. Não estabelece se um site específico requer consentimento; isso depende de como o site usa a análise e das regras que se aplicam a ele.
