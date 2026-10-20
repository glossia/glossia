%{
  title: "Propriedade e portabilidade de conteúdo",
  summary:
    "Por que o conteúdo de propriedade do repositório importa, e quais dependências a fonte pública remove e não remove.",
  category: "explicação",
  section: "translation",
  order: 3
}
---

Uma empresa deve ser capaz de alterar suas ferramentas de idioma sem perder o conteúdo que já produziu ou a capacidade de lançar esse conteúdo.

## Propriedade é mais do que um botão de exportação

Exportar arquivos traduzidos é útil, mas a portabilidade também inclui o histórico de revisões, orientações de idioma, terminologia e configuração necessárias para continuar o trabalho. Se essas residirem apenas dentro de um único ambiente de trabalho proprietário, a empresa pode reter seu resultado enquanto perde o processo que o produziu.

O fluxo de repositório do Glossia mantém o código fonte publicado e os arquivos traduzidos no Git. O histórico de Pull-request permanece no repositório, e a configuração baseada em arquivos descreve a transformação independentemente de uma sessão de edição no navegador.

## Decisões de idioma devem ser reutilizáveis

Voz e orientação de glossário capturam a intenção organizacional. O Glossia torna esse contexto disponível para humanos e integrações, incluindo agentes via MCP. Isso é um tipo diferente de reutilização em comparação com a consulta a um segmento traduzido anteriormente: pode orientar novos conteúdos mesmo quando não há uma frase correspondente em uma memória.

Isso não torna as memórias de tradução baseadas em segmentos obsoletas. As equipes podem ter traduções revisadas valiosas e fluxos de trabalho especializados que desejam manter. A posição do Glossia é que esses recursos devem complementar o processo de entrega da empresa, em vez de se tornarem uma autoridade proprietária obrigatória sobre ele.

## Fonte pública ajuda, mas não é um plano de saída mágico

Ser capaz de inspecionar e modificar a implementação ajuda as equipes a entenderem como o conteúdo é processado. Isso não significa que todas as dependências operacionais desaparecem. Uma instância do Glossia implantada ainda precisa de bancos de dados, acesso ao provedor de modelos para fluxos de trabalho relevantes, credenciais e infraestrutura. O contexto de idioma gerenciado pelo Painel também precisa de um plano de migração explícito se uma equipe mudar de sistemas.

A licença atual O'Saasy restringe serviços hospedados concorrentes. A disponibilidade de fonte pública não é o mesmo que uma licença de código aberto sem restrições ou uma garantia de que um serviço substituto pode ser operado sob qualquer modelo de negócios. Veja a [licença](https://github.com/glossia/glossia/blob/main/LICENSE.md) do repositório.

## Um teste útil de portabilidade

Pergunte se a equipe ainda pode inspecionar, revisar e publicar seu conteúdo traduzido existente caso o serviço de idioma esteja indisponível. Com saídas de propriedade do repositório, a publicação não requer reabrir um editor proprietário apenas para recuperar o arquivo mais recente.

Então pergunte como a orientação de idioma, credenciais e automação migrariam para outro sistema. São perguntas separadas, e mantê-las explícitas é mais útil do que prometer "sem bloqueio" sem qualificação.
