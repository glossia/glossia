%{
  title: "Glossia vs Phrase",
  summary:
    "Escolha um fluxo de trabalho linguístico nativo do repositório com fonte pública, seus próprios tokens de modelo e verificações de entrega reutilizáveis.",
  category: "Explicação",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Escolha o Glossia se quiser que o trabalho de idiomas siga o sistema de entrega do seu produto, em vez de construir um processo paralelo de gerenciamento de tradução ao redor dele.** Mantenha o conteúdo no Git, escolha os modelos suportados usando suas próprias credenciais e valide os resultados com as verificações que seu repositório já confia.

[Phrase](https://phrase.com/) oferece um conjunto de localização, incluindo Phrase Strings e Phrase TMS para diferentes necessidades de localização de software e tradução gerenciada. A Glossia adota uma abordagem focada: dê às equipes de software um OS de idioma que se encaixe no seu ciclo existente de revisão e entrega.

## Por que escolher o Glossia

| Sua prioridade | A vantagem do Glossia |
|---|---|
| Entregue mudanças linguísticas junto com o software | Mudanças no repositório acionam a localização, e as saídas retornam como alterações revisáveis. |
| Inspecione e possua o processamento | Fonte pública expõe a aplicação e a implementação de implantação, com modificação e auto-hospedagem permitidas sob os termos da licença. |
| Use seus próprios tokens | Configure suas próprias credenciais de provedor de modelos suportados; selecione modelos através de identificadores de conta na configuração do repositório. |
| Reutilize pipelines de validação | Execute verificações nativas do repositório em candidatos de tradução em vez de tratar a aprovação linguística como prova de que um arquivo será compilado. |
| Mantenha a propriedade duradoura | Arquivos publicados, configuração e histórico de solicitações pull permanecem com o repositório. |

## Integre a localização à entrega contínua

A detecção de mudanças do Glossia evita repetir o trabalho de tradução para entradas não alteradas. Seu fluxo de trabalho no repositório mantém uma única solicitação pull de tradução aberta por projeto e publica o progresso em lotes, então um repositório de fonte que muda rapidamente não precisa de um novo processo de tradução para cada pequena mudança.

O objetivo não é uma corrida para produção sem revisão. É tornar o trabalho de idioma continuamente revisível e entregável através do pipeline que sua equipe já usa.

A Phrase oferece APIs, integrações e automações também. A vantagem que o Glossia enfatiza é o alinhamento arquitetural: o repositório permanece a autoridade do conteúdo e a fronteira de entrega, em vez de ser apenas um local para sincronizar os resultados de outro espaço de trabalho.

## Mantenha a escolha do modelo e as credenciais sob controle seu

O Glossia aceita seus próprios tokens de API de provedor para modelos suportados. As credenciais ficam nas configurações de conta; os repositórios selecionam identificadores estáveis. Uma equipe pode rotacionar um token ou alterar o modelo atrás de um identificador sem reescrever suas instruções do repositório.

Escopos de conteúdo diferentes e idiomas-alvo distintos podem usar diferentes modelos configurados. Modelos de decisão opcionais podem avaliar traduções completas e solicitar correção, enquanto humanos permanecem responsáveis pelo julgamento linguístico. Veja [Modelos de conta](./account-models) para o comportamento e limites atuais.

## Seu repositório já sabe o que significa conteúdo válido

A visão de um sistema de gerenciamento de tradução sobre uma string não é necessariamente a visão do aplicativo sobre um arquivo. Um repositório pode ter seu próprio parser, compilador, regras de componente, construção de documentação e verificações de placeholders.

O Glossia pode reutilizar essas verificações através `L10N.md` comandos de validação. Escreve o candidato temporariamente para seu caminho de destino real para validação e o aceita apenas depois que as verificações necessárias forem atendidas. O comando e suas dependências devem estar disponíveis no ambiente de execução.

Isso permite ao time extender sua fronteira de qualidade existente em vez de manter uma definição separada de "válido" apenas dentro de um espaço de trabalho de tradução. Veja [L10N.md](/docs/reference/l10n-md).

## Implementação pública, não uma caixa preta

Os fontes da aplicação, CLI, SDK e infraestrutura do Glossia são públicos. O núcleo utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite uso comercial, modificação, distribuição, auto-hospedagem e serviços hospedados concorrentes conforme seus termos. O código em `ee/` possui uma [licença Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada e seu uso em produção exige um acordo comercial por escrito.

Um conjunto de tradução mais amplo pode fazer sentido para operações de tradução especializadas e coordenação complexa. Se sua prioridade é **correspondência de velocidade de entrega de software com seus próprios tokens e verificações do repositório**, o Glossia é projetado para manter aquele fluxo de trabalho direto.

Mover um programa de tradução estabelecido ainda requer um plano para suas memórias, terminologia e histórico. Esta página não promete um importador automático de Phrase ou equivalência completa de suite, ou afirma que o Phrase falta todas as integrações equivalentes. Consulte [Documentação da Phrase](https://support.phrase.com/) para as capacidades atuais do produto específico.
