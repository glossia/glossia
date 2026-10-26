%{
  title: "Propriedade do conteúdo e portabilidade",
  summary:
    "Por que o conteúdo de propriedade de repositório importa, e quais dependências a fonte pública remove e não remove.",
  category: "explicação",
  section: "translation",
  order: 3
}
---

Uma empresa deve poder alterar suas ferramentas de idioma sem perder o conteúdo já produzido ou a capacidade de publicar esse conteúdo.

## Propriedade é mais que um botão de exportação

Exportar arquivos traduzidos é útil, mas a portabilidade também inclui o histórico de revisão, orientações de linguagem, terminologia e a configuração necessária para continuar o trabalho. Se tudo isso residir apenas dentro de um único ambiente proprietário, a empresa pode reter seu produto final enquanto perde o processo que o gerou.

O fluxo de repositório do Glossia mantém os arquivos fonte publicados e traduzidos no Git. O histórico de pull requests permanece no repositório, e a configuração baseada em arquivos descreve a transformação independentemente de uma sessão de edição no navegador.

## As decisões de idioma devem ser reutilizáveis

A orientação de voz e glosário captam a intenção organizacional. O Glossia torna esse contexto disponível para humanos e integrações, incluindo agentes através do MCP. Este é um tipo diferente de reutilização em relação à consulta de um segmento previamente traduzido: pode guiar novos conteúdos mesmo quando não há uma frase correspondente em uma memória.

Isso não torna as memórias de tradução baseadas em segmentos obsoletas. Equipes podem ter revisões valiosas de traduções e fluxos de trabalho especializados que desejam manter. A posição do Glossia é que tais recursos deveriam complementar o processo de entrega de uma empresa, em vez de se tornarem uma autoridade proprietária obrigatória sobre ele.

## Fonte pública ajuda, mas não é um plano de saída mágico

A capacidade de inspecionar e modificar a implementação ajuda as equipes a entenderem como seu conteúdo é processado. Isso não significa que todas as dependências operacionais desaparecem. Uma instância do Glossia implantada ainda precisa de bancos de dados, acesso a provedores de modelo para fluxos de trabalho relevantes, credenciais e infraestrutura. O contexto de idioma gerenciado pelo painel também precisa de um plano de migração explícito se uma equipe mudar os sistemas.

O Glossia segue um modelo open core. O núcleo utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite uso comercial, modificação, distribuição, auto-hospedagem e serviços hospedados concorrentes conforme seus termos. O código em `ee/` é visível, mas não é código aberto. Ele possui uma [licença Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada e seu uso em produção exige um acordo comercial por escrito.

## Um teste útil de portabilidade

Pergunte se a equipe ainda pode inspecionar, revisar e publicar seu conteúdo traduzido existente se o serviço de idioma estiver indisponível. Com saídas de propriedade do repositório, a publicação não exige reabrir um editor proprietário apenas para recuperar o arquivo mais recente.

Então pergunte como as orientações de idioma, credenciais e automação se moveriam para outro sistema. São questões separadas, e mantê-las explícitas é mais útil do que prometer "sem lock-in" sem qualificação.
