%{
  title: "Por que análise de localização",
  summary:
    "Como os sinais coletados se traduzem em decisões de localização e por que a métrica de lacuna importa.",
  category: "explicação",
  order: 2
}
---
Escolher para qual idioma traduzir a seguir é uma aposta: custa tempo e dinheiro, e o retorno depende de uma demanda que você geralmente não consegue ver. A análise de localização torna essa demanda visível.

## A decisão, não o painel

O propósito de coletar análises aqui é estreito e deliberado: para responder "devemos localizar para o idioma X?" Os sinais são escolhidos para atender a essa pergunta, não para funcionar como uma suíte analítica de propósito geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes desejam esse idioma? Os idiomas do navegador e o país indicam onde está o interesse.
2. **A lacuna.** Essa demanda já está atendida? Ao comparar idiomas preferidos com os idiomas de destino do seu projeto, revela-se a parcela do tráfego que esbarra em uma barreira.
3. **Valor.** Faria a localização valer a pena? A lacuna de engajamento por localização, as páginas onde aterrissa o tráfego subatendido e a origem desse tráfego indicam se uma nova localização converte.

## Por que a lacuna é computada no momento da ingestão

`served_locale` e `has_locale_gap` são armazenados por evento, calculados em relação aos idiomas alvo conforme eram no momento da visita. Isso significa que os dados históricos refletem a oportunidade que você enfrentou naquela época, não uma recomputação em relação às metas de hoje. Se você adicionar Português no próximo mês, a lacuna do mês passado não diminui retroativamente; você mantém um registro honesto de quanto da demanda estava sendo subatendida.

## Por que sem cookie, especificamente

O instinto quando você deseja "visitantes únicos" é definir um cookie ou fingerprintar o navegador. Ambos criam identificadores de longa duração, e o fingerprinting é, na maioria dos regimes de privacidade, mais difícil de remover do que um cookie. Nenhum é necessário aqui.

Visitantes únicos por dia exigem apenas um identificador que seja estável *dentro do dia*. Uma hash do IP e User-Agent, rotacionada diariamente e delimitada por projeto, fornece contagens precisas de visitantes únicos diárias e semanais, tornando impossível vincular um visitante entre dias ou sites. Você abre mão do rastreamento a longo prazo de visitantes recorrentes, que é exatamente a capacidade que cria a exposição de privacidade que, de outra forma, exigiria um banner de consentimento para operar legalmente.

A compensação é intencional: as análises de localização devem ser algo que você possa lançar em qualquer lugar, para cada visitante, sem atrito legal.