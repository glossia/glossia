%{
  title: "Por que análise de localização",
  summary: "Como os sinais coletados resultam em decisões de localização e por que a métrica de lacuna importa.",
  category: "explanation",
  order: 2
}
---
Escolher para qual idioma traduzir a seguir é uma aposta: custa tempo e dinheiro, e o retorno depende da demanda que você geralmente não consegue ver. A análise de localização torna essa demanda visível.

## A decisão, não o painel

O objetivo de coletar análise de localização aqui é restrito e deliberado: responder "devemos localizar para o idioma X?" Os sinais são escolhidos para alimentar essa pergunta, não para servir como uma suíte de análise geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes desejam esse idioma? Os idiomas do navegador e o país indicam onde o interesse está.
2. **A lacuna.** Essa demanda já está sendo atendida? Comparando idiomas preferidos contra os idiomas alvo do seu projeto revela a parcela do tráfego que esbarra em um muro.
3. **Valor.** A localização compensaria? O engajamento pela lacuna de localização, as páginas para as quais o tráfego subatendido é direcionado e de onde esse tráfego provém indicam se uma nova localização converte.

## Por que a lacuna é computada no momento da ingestão

`served_locale` e `has_locale_gap` são armazenados por evento, computados contra os seus idiomas alvo conforme eram no momento da visita. Isso significa que os dados históricos refletem a oportunidade que você enfrentava então, não uma recomputação contra os alvos de hoje. Se você adicionar Português no próximo mês, a lacuna do mês passado não diminui retroativamente; você mantém um registro honesto de quanto da demanda estava indo sem ser atendida.

## Por que sem cookies, especificamente

O instinto quando você quer "visitantes únicos" é definir um cookie ou realizar uma impressão digital do navegador. Ambos criam identificadores de longa duração, e a impressão digital é, sob a maioria dos regimes de privacidade, mais difícil de limpar que um cookie. Nenhum é necessário aqui.

Visitantes únicos para um dia só requerem um identificador que seja estável *dentro do dia*. Um hash do IP e User-Agent, rotacionado diariamente e escopado por projeto, fornece contagens diárias e semanais precisas enquanto torna impossível vincular um visitante através de dias ou através de sites. Você abre mão do rastreamento de retorno de visitantes de longo prazo, que é exatamente a capacidade que cria a exposição de privacidade que você normalmente precisaria de um banner de consentimento para operar legalmente.

A compensação é intencional: a análise de localização deve ser algo que você possa implantar em qualquer lugar, para cada visitante, sem atrito legal.