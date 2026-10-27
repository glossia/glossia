%{
  title: "Por que a análise de localização",
  summary:
    "Como os sinais coletados se traduzem em decisões de localização e por que a métrica de lacuna importa.",
  category: "explicação",
  section: "analytics",
  order: 2
}
---

Escolher qual idioma traduzir a seguir é uma aposta: custa tempo e dinheiro, e o retorno depende de uma demanda que você normalmente não consegue ver. A análise de localização torna essa demanda visível.

## ## A decisão, não o painel

O propósito de coletar análises aqui é estreito e intencional: para responder "deveríamos localizar para o idioma X?" Os sinais são escolhidos para alimentar essa pergunta, não para ser um conjunto de análises de uso geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes querem esse idioma? Idiomas do navegador e país indicam onde está o interesse.
2. **O hiato.** Essa demanda já está sendo atendida? Comparando idiomas preferidos contra as línguas-alvo do projeto, o idioma da página e suas traduções anunciadas revela a proporção de tráfego que tropeça em um obstáculo.
3. **Valor.** A localização compensaria? O engajamento por lacuna de localidade, as páginas onde o tráfego subatendido aterrissa e a origem desse tráfego indicam se uma nova localidade converte.

## Por que o hiato é computado no momento da ingestão

`served_locale` registra o idioma real da página declarado em `<html lang>`, não o idioma que presumimos que o visitante recebeu. `has_locale_gap` compara uma escolha explícita e válida de idioma, ou preferências do navegador quando nenhuma escolha é conhecida, contra os alvos do seu projeto, o idioma da página e traduções anunciadas através de links `hreflang`. Uma escolha indica demanda, não disponibilidade: escolher um idioma não suportado ainda deixa um hiato. Preferência do navegador, escolha e idioma da página permanecem sinais separados.

A decisão do hiato é armazenada por evento conforme era no momento da visita. Bandeiras históricas, incluindo aquelas coletadas antes das escolhas explícitas afetarem o cálculo do hiato, não são recomputadas com base nos alvos de hoje ou em escolhas futuras. A lista completa de preferências de navegador e traduções anunciadas não são retidas, portanto não podem ser reconstituídas de forma confiável. Se você adicionar português no próximo mês, o hiato do mês passado não é retroativamente reduzido; você mantém o registro original da demanda.

## Por que sem cookies, especificamente

O instinto, ao desejar "visitantes únicos", é definir um cookie ou gerar uma impressão digital do navegador. Ambos criam identificadores de longa duração, e o fingerprinting é, sob a maioria dos regimes de privacidade, mais difícil de remover do que um cookie. Nenhum dos dois é necessário aqui.

Visitantes únicos para um dia exigem apenas um identificador que seja estável *no decorrer do dia*. Um hash do IP e User-Agent, rotacionado diariamente e escopo por projeto, suporta contagens diárias de visitantes enquanto torna impossível vincular um visitante entre dias ou entre sites. Isso não fornece rastreamento de visitantes retornantes de longo prazo.

Este design limita os identificadores retidos pela análise. Não determina se um site em particular requer consentimento; isso depende de como o site usa análise e das regras que se aplicam a ele.
