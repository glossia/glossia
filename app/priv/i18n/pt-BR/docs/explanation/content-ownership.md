%{
  title: "Propriedade do conteúdo e portabilidade",
  summary:
    "Por que o conteúdo de propriedade do repositório importa, e quais dependências a fonte pública remove e não remove.",
  category: "explicação",
  section: "translation",
  order: 3
}
---

Uma empresa deve ser capaz de alterar suas ferramentas de idiomas sem perder o conteúdo que já produziu ou a capacidade de distribuir esse conteúdo.

## Propriedade é mais do que um botão de exportação

Exportar arquivos traduzidos é útil, mas a portabilidade também inclui o histórico de revisão, as diretrizes de idioma, os termos terminológicos e a configuração necessários para continuar o trabalho. Se esses itens residirem apenas dentro de um único ambiente de trabalho proprietário, a empresa pode reter sua produção enquanto perde o processo que a gerou.

O fluxo de trabalho de repositório do Glossia mantém os arquivos de origem publicados e os arquivos traduzidos no Git. O histórico de pull request permanece com o repositório, e a configuração baseada em arquivos descreve a transformação independentemente de uma sessão de edição no navegador.

## Decisões de idioma devem ser reutilizáveis

As orientações de voz e glossário capturam a intenção organizacional. O Glossia torna esse contexto disponível para humanos e integrações, incluindo agentes via MCP. Trata-se de um tipo diferente de reutilização da consulta a um segmento traduzido anteriormente: pode orientar novo conteúdo mesmo quando não há uma frase correspondente em uma memória.

Isso não torna as memórias de tradução baseadas em segmentos obsoletas. As equipes podem ter revisões de tradução valiosas e fluxos de trabalho especializados que desejam reter. A posição do Glossia é que tais recursos devem complementar o processo de entrega da empresa, em vez de se tornarem uma autoridade proprietária obrigatória sobre ele.

## A fonte pública ajuda, mas não é um plano de saída mágico

A capacidade de inspecionar e modificar a implementação ajuda as equipes a entender como seu conteúdo é processado. Isso não significa que todas as dependências operacionais desaparecem. Uma instância do Glossia implantada ainda precisa de bancos de dados, acesso ao provedor de modelos para fluxos de trabalho relevantes, credenciais e infraestrutura. O contexto de idioma gerenciado pelo painel também precisa de um plano de migração explícito se uma equipe mudar os sistemas.

O Glossia segue um modelo open core. O núcleo utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite uso comercial, modificação, distribuição, auto-hospedagem e serviços hospedados concorrentes conforme seus termos. O código em `ee/` é visível, mas não é código aberto. Ele possui uma [licença Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada e seu uso em produção exige um acordo comercial por escrito.

## Um teste útil de portabilidade

Pergunte se a equipe ainda pode inspecionar, revisar e publicar o conteúdo traduzido existente se o serviço de idioma estiver indisponível. Com saídas de propriedade de repositório, a publicação não Requer reabrir um editor proprietário apenas para recuperar o arquivo mais recente.

Então pergunte como as diretrizes de idioma, as credenciais e a automação se moveriam para outro sistema. São perguntas separadas, e mantê-las explícitas é mais útil que prometer "sem bloqueio" sem qualificações.
