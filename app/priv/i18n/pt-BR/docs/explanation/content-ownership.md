%{
  title: "Propriedade e portabilidade de conteúdo",
  summary:
    "Por que o conteúdo de repositório próprio importa, e quais dependências o código fonte público remove e não remove.",
  category: "explicação",
  section: "translation",
  order: 3
}
---

Uma empresa deve ser capaz de alterar suas ferramentas de idioma sem perder o conteúdo que já produziu ou a capacidade de distribuir esse conteúdo.

## Propriedade é mais do que um botão de exportação

A exportação de arquivos traduzidos é útil, mas a portabilidade também inclui o histórico de revisões, diretrizes de idioma, terminologia e configurações necessárias para continuar o trabalho. Se esses estiverem apenas dentro de um workspace proprietário, a empresa poderá reter sua produção enquanto perde o processo que a gerou.

O fluxo de repositório do Glossia mantém o código fonte publicado e arquivos traduzidos no Git. O histórico de pull request permanece no repositório, e a configuração baseada em arquivos descreve a transformação independentemente de uma sessão de edição no navegador.

## As decisões de idioma devem ser reutilizáveis

Voice e diretrizes de glossário capturam a intenção organizacional. O Glossia torna esse contexto disponível para humanos e integrações, incluindo agentes por meio do MCP. Este é um tipo diferente de reutilização de consultar um segmento já traduzido anteriormente: pode orientar o novo conteúdo mesmo que não exista uma frase correspondente em uma memória.

Isso não torna as memórias de tradução baseadas em segmentos obsoletas. As equipes podem ter traduções revisadas valiosas e fluxos de trabalho especializados que desejam reter. A posição do Glossia é que tais recursos devem complementar o processo de entrega de uma empresa em vez de se tornar uma autoridade proprietária obrigatória sobre ela.

## O código-fonte público ajuda, mas não é um plano de saída mágico

Ser capaz de inspecionar e modificar a implementação ajuda as equipes a entenderem como seu conteúdo é processado. Não significa que toda dependência operacional desapareça. Uma instância do Glossia implantada ainda precisa de bancos de dados, acesso a provedores de modelo para fluxos de trabalho relevantes, credenciais e infraestrutura. O contexto de idioma gerenciado no dashboard também precisa de um plano de migração explícito se uma equipe mudar de sistemas.

A licença atual O'Saasy restringe serviços hospedados concorrentes. A disponibilidade de código-fonte público não é o mesmo que uma licença de código aberto sem restrições ou uma garantia de que um serviço substituto pode ser operado sob qualquer modelo de negócios. Consulte a [licença](https://github.com/glossia/glossia/blob/main/LICENSE.md) do repositório.

## Um teste de portabilidade útil

Pergunte se a equipe ainda pode inspecionar, revisar e publicar o conteúdo traduzido existente se o serviço de idioma estiver indisponível. Com saídas de propriedade do repositório, a publicação não exige reabrir um editor proprietário apenas para recuperar o arquivo mais recente.

Em seguida, pergunte como as diretrizes de idioma, credenciais e automação se moviriam para outro sistema. São perguntas separadas, e mantê-las explícitas é mais útil do que prometer "sem lock-in" sem qualificação.
