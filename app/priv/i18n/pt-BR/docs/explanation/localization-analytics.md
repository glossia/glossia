%{
  title: "Por que a análise de localização",
  summary:
    "Como os sinais coletados se traduzem em decisões de localização e por que a métrica de lacuna importa.",
  category: "explicação",
  section: "analytics",
  order: 2
}
---

Escolher para qual idioma traduzir a seguir é uma aposta: custa tempo e dinheiro, e o retorno depende da demanda que você geralmente não consegue ver. A análise de localização torna essa demanda visível.

## A decisão, não o painel

O propósito de coletar análises aqui é estreito e deliberado: responder "devemos localizar para o idioma X?" Os sinais são escolhidos para alimentar essa pergunta, não para serem um conjunto de análises de uso geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes querem este idioma? As línguas do navegador e o país telling onde está o interesse.
2. **A brecha.** Essa demanda já foi atendida? Ao comparar as preferências de idioma com as línguas-alvo do seu projeto, o idioma da página e suas traduções anunciadas, revela-se a parcela de tráfego que encontra uma parede.
3. **Valor.** A localização valerá a pena? O engajamento por lacuna de localização, as páginas nas quais o tráfego não atendido aterrissa e a origem desse tráfego indicam se uma nova localização converte.

## Por que a brecha é calculada no momento da ingestão

`served_locale` registra o idioma real da página declarado em `<html lang>`, não o idioma que assumimos que o visitante recebeu. `has_locale_gap` compara as preferências do navegador contra os objetivos do seu projeto, o idioma da página e as traduções anunciadas através dos links `hreflang`. Ambos são armazenados por evento conforme eram no momento da visita. Isso significa que os dados históricos refletem a oportunidade que você enfrentava naquela época, não um recálculo contra os objetivos de hoje. Se você adicionar português no próximo mês, a brecha do mês passado não diminui retroativamente; você mantém um registro honesto de quanto da demanda estava sem ser atendida.

## Por que sem cookies, especificamente

O instinto quando você quer "visitantes únicos" é definir um cookie ou obter a impressão digital do navegador. Ambos criam identificadores de longa duração, e a obtenção de impressão digital, sob a maioria dos regimes de privacidade, é mais difícil de limpar do que um cookie. Nenhum dos dois é necessário aqui.

Visitantes únicos para um dia exigem apenas um identificador que seja estável *dentro do mesmo dia*. Um hash do IP e do User-Agent, rotacionado diariamente e com escopo por projeto, suporta contagens diárias de visitantes enquanto torna impossível vincular um visitante entre dias ou entre sites. Isso não fornece rastreamento de longo prazo de visitantes que retornam.

Este design limita os identificadores retidos pela análise. Não estabelece se um site específico requer consentimento; isso depende de como o site usa as análises e das regras que se aplicam a ele.
