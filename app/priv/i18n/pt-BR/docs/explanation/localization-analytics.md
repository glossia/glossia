%{
  title: "Por que a análise de localização",
  summary:
    "Como os sinais coletados se transformam em decisões de localização e por que a métrica de lacuna importa.",
  category: "explicação",
  order: 2
}
---
Escolher para qual idioma traduzir a seguir é uma aposta: consome tempo e dinheiro, e o retorno depende da demanda que você geralmente não consegue ver. A análise de localização torna essa demanda visível.

## A decisão, não o painel

O propósito de coletar análises aqui é restrito e deliberado: para responder "devemos localizar para o idioma X?" Os indicadores são escolhidos para responder a essa pergunta, não para ser uma suíte de análises de uso geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes buscam este idioma? Os idiomas de navegador e o país indicam onde está o interesse.
2. **A lacuna.** Essa demanda já é atendida? Comparando os idiomas preferidos com os idiomas-alvo do seu projeto revela a parcela de tráfego que esbarra em um obstáculo.
3. **Valor.** A localização vale a pena? O gap de engajamento por locale, as páginas para as quais o tráfego não atendido chega e a origem desse tráfego indicam se um novo locale converte.

## Por que o gap é computado no momento da ingestão

`served_locale` e `has_locale_gap` são armazenados por evento, computados contra seus idiomas alvo conforme eram no momento da visita. Isso significa que os dados históricos refletem a oportunidade que você enfrentava na época, não uma recomputação contra os objetivos de hoje. Se você adicionar o português no mês que vem, o gap do mês passado não diminui retroativamente; você mantém um registro honesto de quanto demanda estava não atendida.

## Por que sem cookie, especificamente

O instinto quando você quer "visitantes únicos" é definir um cookie ou fazer fingerprint no navegador. Ambos criam identificadores de longa duração, e o fingerprinting, sob a maioria dos regimes de privacidade, é mais difícil de limpar que um cookie. Nenhum é necessário aqui.

Visitantes únicos para um dia exigem apenas um identificador que seja estável *dentro do dia*. Um hash do IP e User-Agent, rotacionado diariamente e com escopo por projeto, fornece contagens precisas de visitantes únicos diários e semanais, tornando impossível vincular um visitante entre dias ou entre sites. Você abre mão do rastreamento de visitantes recorrentes de longo prazo, o que é exatamente a capacidade que gera a exposição de privacidade que você de outra forma precisaria de um banner de consentimento para operar legalmente.

A compensação é intencional: as análises de localização devem ser algo que você possa distribuir em toda parte, para todos os visitantes, sem atrito legal.