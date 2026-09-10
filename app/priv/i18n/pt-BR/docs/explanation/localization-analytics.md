%{
  title: "Por que a análise de localização",
  summary:
    "Como os sinais coletados se traduzem em decisões de localização e por que a métrica de lacuna importa.",
  category: "explicação",
  order: 2
}
---
Escolher em qual idioma traduzir a seguir é uma aposta: custa tempo e dinheiro, e o retorno depende da demanda que geralmente não consegue ver. A análise de localização torna essa demanda visível.

## A decisão, não o painel

O propósito de coletar análises aqui é estreito e deliberado: para responder "devemos localizar para o idioma X?" Os sinais são escolhidos para atender a essa pergunta, não para ser uma suíte de análises geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes desejam este idioma? Idiomas do navegador e país indicam onde está o interesse.
2. **A brecha.** Essa demanda já está atendida? Comparando idiomas preferidos com os idiomas-alvo do seu projeto revela a parcela de tráfego que esbarra em uma parede.
3. **Valor.** A localização vale a pena? A lacuna de engajamento por localidade, as páginas onde cai o tráfego não atendido e a origem desse tráfego indicam se uma nova localidade converte.

## Por que a lacuna é calculada no momento da ingestão

`served_locale` e `has_locale_gap` são armazenadas por evento, calculadas em relação aos idiomas-alvo conforme eram na época da visita. Isso significa que os dados históricos refletem a oportunidade que você enfrentou naquela época, e não uma recomputação em relação aos idiomas-alvo de hoje. Se você adicionar o Português no próximo mês, a lacuna do mês passado não diminui retroativamente; você mantém um registro honesto de quanto da demanda estava não atendida.

## Por que sem cookies, especificamente

O instinto quando deseja "visitantes únicos" é definir um cookie ou obter a impressão digital do navegador. Ambos criam identificadores de longa duração, e a impressão digital é, na maioria dos regimes de privacidade, mais difícil de excluir do que um cookie. Nenhum dos dois é necessário aqui.

Visitantes únicos para um dia exigem apenas um identificador estável *dentro do dia*. Um hash do IP e do User-Agent, rotacionado diariamente e delimitado por projeto, fornece contagens de visitantes únicos diárias e semanais precisas, tornando impossível vincular um visitante entre dias ou entre sites. Você abre mão do rastreamento de longe prazo de visitantes retornantes, que é exatamente a capacidade que gera a exposição de privacidade, que você precisaria de um banner de consentimento para operar legalmente.

A contrapartida é intencional: a analítica de localização deve ser algo que você possa enviar em qualquer lugar, para cada visitante, sem atrito legal.