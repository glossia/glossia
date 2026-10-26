%{
  title: "Propriedade e portabilidade de conteúdo",
  summary:
    "Por que o conteúdo de repositório próprio importa e quais dependências a fonte pública remove e não remove.",
  category: "explanation",
  section: "translation",
  order: 3
}
---

Uma empresa deve poder alterar suas ferramentas de idioma sem perder o conteúdo que já produziu ou a capacidade de lançar esse conteúdo.

## A propriedade é mais do que um botão de exportação

Exportar arquivos traduzidos é útil, mas a portabilidade também inclui o histórico de revisão, orientações de idioma, terminologia e configuração necessárias para continuar o trabalho. Se esses recursos viverem apenas dentro de um único espaço de trabalho proprietário, a empresa pode manter sua saída enquanto perde o processo que a produziu.

O fluxo de trabalho do repositório do Glossia mantém o código-fonte publicado e arquivos traduzidos no Git. O histórico de solicitações pull permanece no repositório, e a configuração baseada em arquivos descreve a transformação independentemente de uma sessão de edição no navegador.

## Decisões de idioma devem ser reutilizáveis

Orientações de voz e glossário capturam a intenção organizacional. O Glossia torna esse contexto disponível para humanos e integrações, incluindo agentes através do MCP. Isso é um tipo diferente de reutilização em comparação com a consulta de um segmento previamente traduzido: pode orientar novos conteúdos mesmo quando não há uma frase correspondente em uma memória.

Isso não torna as memórias de segmento obsoletas. As equipes podem possuir traduções revisadas valiosas e fluxos de trabalho especializados que desejam reter. A posição do Glossia é que tais recursos devem complementar o processo de entrega de uma empresa e não se tornar uma autoridade proprietária obrigatória sobre ele.

## Código-fonte público ajuda, mas não é um plano de saída mágico

Ser capaz de inspecionar e modificar a implementação ajuda as equipes a entenderem como seu conteúdo é processado. Isso não significa que todas as dependências operacionais desapareçam. Uma instância do Glossia implantada ainda precisa de bancos de dados, acesso ao provedor de modelo para fluxos de trabalho relevantes, credenciais e infraestrutura. O contexto de idioma gerenciado pelo Painel de controle também precisa de um plano de migração explícito se uma equipe mudar os sistemas.

O núcleo do Glossia é código aberto sob Apache-2.0, o que permite auto-hospedagem e serviços hospedados concorrentes sob seus termos. Código empresarial sob `ee/` está disponível com código-fonte sob licença separada e requer um acordo comercial escrito para uso em produção. Consulte o [aviso de licenciamento](https://github.com/glossia/glossia/blob/main/LICENSE.md) do repositório ao planejar uma implantação de substituição.

## Um teste útil de portabilidade

Pergunte se a equipe ainda pode inspecionar, revisar e publicar o conteúdo traduzido existente se o serviço de idioma estiver indisponível. Com saídas de propriedade do repositório, a publicação não exige reabrir um editor proprietário apenas para recuperar o arquivo mais recente.

Então pergunte como as orientações de idioma, credenciais e automação se transfeririam para outro sistema. São perguntas separadas e mantê-las explícitas é mais útil que prometer "sem lock-in" sem qualificação.
