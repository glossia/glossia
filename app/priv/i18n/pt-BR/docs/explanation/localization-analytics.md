%{
  title: "Por que a análise de localização",
  summary:
    "Como os sinais coletados se traduzem em decisões de localização e por que a métrica de lacuna importa.",
  category: "explicação",
  section: "analytics",
  order: 2
}
---
Escolher o idioma para traduzir a seguir é uma aposta: custa tempo e dinheiro, e o retorno depende de uma demanda que você geralmente não consegue ver. A análise de localização torna essa demanda visível.

## A decisão, não o painel.

O propósito de coletar análises aqui é apurado e deliberado: responder à pergunta "devemos traduzir para o idioma X?" Os sinais são escolhidos para responder a essa questão, não para atuar como uma suíte analítica de propósito geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes desejam este idioma? As preferências de idioma do navegador e o país indicam onde está esse interesse.
2. **A lacuna.** Essa demanda já está sendo atendida? Comparando os idiomas preferidos com os idiomas-alvo do seu projeto, o idioma da página e suas traduções anunciadas, revela-se a proporção de tráfego que esbarra em uma barreira.
3. **Valor.** A localização vale a pena? A lacuna de engajamento por localização, as páginas onde o tráfego não atendido aterrissa e de onde esse tráfego vem indicam se uma nova localização converte.

## Por que a lacuna é calculada no tempo de ingestão

`served_locale` registra o idioma real da página declarado em `<html lang>`, não o idioma que assumimos que o visitante recebeu. `has_locale_gap` compara as preferências do navegador com os objetivos do seu projeto, o idioma da página e as traduções anunciadas através `hreflang` links. Ambos são armazenados por evento conforme estavam no momento da visita. Isso significa que os dados históricos refletem a oportunidade que você enfrentou então, não uma recomputação contra os objetivos de hoje. Se você adicionar Português no próximo mês, a lacuna do mês passado não diminui retroativamente; você mantém um registro honesto de quanto da demanda estava não atendida.

## Por que sem cookies, especificamente

O instinto quando você quer "visitantes únicos" é definir um cookie ou obter a impressão digital do navegador. Ambos criam identificadores de longa duração, e a impressão digital é, na maioria dos regimes de privacidade, mais difícil de remover do que um cookie. Nenhum dos dois é necessário aqui.

Visitantes únicos por dia exigem apenas um identificador que seja estável *dentro do dia*. Um hash do IP e do User-Agent, rotacionado diariamente e isolado por projeto, suporta a contagem diária de visitantes enquanto torna impossível vincular um visitante entre dias ou sites.

Essa abordagem limita os identificadores mantidos pela análise. Ela não determina se um site específico requer consentimento; isso depende de como o site usa a análise e das regras aplicáveis a ele.