%{
  title: "Por que as análises de localização",
  summary:
    "Como os sinais coletados se transformam em decisões de localização, e por que a métrica de lacuna importa.",
  category: "explicação",
  order: 2
}
---
Escolher para qual idioma traduzir a seguir é uma apostas: custa tempo e dinheiro, e o retorno depende da demanda que geralmente você não pode ver. As análises de localização tornam essa demanda visível.

## A decisão, não o painel

O objetivo de coletar análises aqui é estreito e deliberado: responder a "devemos traduzir para o idioma X?". Os sinais são escolhidos para alimentar essa pergunta, não para funcionarem como uma suíte analítica de propósito geral.

Três entradas impulsionam a decisão:

1. **Demanda.** Quantos visitantes querem esse idioma? Os idiomas do navegador e o país indicam onde está o interesse.
2. **A lacuna.** Essa demanda já é atendida? Comparar idiomas preferidos contra os idiomas-alvo do seu projeto revela a parcela do tráfego que bate na parede.
3. **Valor.** A tradução valerá a pena? O engajamento pela lacuna de localização, as páginas onde o tráfego subatendido cai, e de onde esse tráfego vem indicam se uma nova localização converte.

## Por que a lacuna é computada no momento da ingestão

`served_locale` e `has_locale_gap` são armazenados por evento, computados contra seus idiomas-alvo conforme eram no momento da visita. Isso significa que os dados históricos refletem a oportunidade que você teve naquela época, não uma recomputação contra os alvos de hoje. Se você adicionar o português mês que vem, a lacuna do mês passado não diminui retroativamente; você mantém um registro honesto de quanto demanda estava indo sem atendimento.

## Por que sem cookies, especificamente

O instinto quando você quer "visitantes únicos" é definir um cookie ou tirar uma impressão digital do navegador. Ambos criam identificadores de longa duração, e o fingerprinting é, sob a maioria dos regimes de privacidade, mais difícil de remover do que um cookie. Nenhum é necessário aqui.

Visitantes únicos para um dia exigem apenas um identificador que seja estável *dentro do dia*. Um hash do IP e User-Agent, rotacionado diariamente e delimitado por projeto, fornece únicas precisas diárias e semanais, enquanto torna impossível vincular um visitante entre dias ou entre sites. Você renuncia ao rastreamento de retorno a longo prazo, que é exatamente a capacidade que cria a exposição de privacidade para a qual você precisaria de um banner de consentimento para operar legalmente.

A troca é intencional: as análises de localização devem ser algo que você pode lançar em qualquer lugar, para todos os visitantes, sem atrito legal.