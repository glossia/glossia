%{
  title: "Glossia versus Phrase",
  summary:
    "Escolha um fluxo de trabalho de linguagem nativo do repositório com código fonte público, seus próprios tokens de modelo e verificações de entrega reutilizáveis.",
  category: "explicação",
  section: "translation",
  order: 22
}
---

**Escolha Glossia quando você quiser que o trabalho com idiomas siga o sistema de entrega do seu produto, em vez de construir um processo paralelo de gerenciamento de tradução ao redor dele.** Mantenha o conteúdo no Git, escolha modelos suportados usando suas próprias credenciais e valide os resultados com as verificações que seu repositório já confia.

[Phrase](https://phrase.com/) fornece uma suíte de internacionalização, incluindo Phrase Strings e Phrase TMS para diferentes necessidades de software-localization e tradução gerenciada. Glossia adota uma abordagem focada: dê às equipes de software um sistema operacional para idiomas que se encaixe em seu loop atual de revisão e entrega.

## Por que escolher a Glossia

| Sua prioridade | A vantagem da Glossia |
|---|---|
| Entregue mudanças de idioma com o software | Mudanças no repositório impulsionam a localização, e os resultados retornam como mudanças revisáveis. |
| Inspeione e assuma o controle do processamento | O código-fonte público expõe a implementação do aplicativo e de deploy, com modificações e hospedagem própria permitidas sob os termos da licença. |
| Leve seus próprios tokens | Configure suas próprias credenciais de provedor de modelo suportado; selecione modelos através de handles de conta na configuração do repositório. |
| Reutilize pipelines de validação | Execute verificações nativas do repositório em candidatos a tradução, em vez de tratar a aprovação linguística como prova de que um arquivo pode ser compilado. |
| Mantenha uma propriedade duradoura | Arquivos publicados, configuração e histórico de pull requests permanecem com o repositório. |

## Integre a localização na entrega contínua

A detecção de mudanças da Glossia evita repetir trabalho de tradução para entradas inalteradas. Seu fluxo de trabalho do repositório mantém um único pull request de tradução aberto por projeto e publica o progresso em lotes, de modo que um repositório fonte em rápida mudança não precisa de um novo processo de tradução para cada pequena alteração.

O objetivo não é uma corrida para a produção não revisada. É tornar o trabalho de idioma continuamente revisável e entregável através do pipeline que sua equipe já usa.

A Phrase também oferece APIs, integrações e automação. A vantagem que a Glossia ressalta é o alinhamento arquitetônico: o repositório permanece a autoridade do conteúdo e o limite da entrega, em vez de apenas ser um local para sincronizar os resultados de outro ambiente de trabalho.

## Mantenha a escolha do modelo e as credenciais sob seu controle

A Glossia aceita seus próprios tokens de API de provedor para modelos suportados. As credenciais permanecem nas configurações da conta; os repositórios selecionam handles estáveis. Uma equipe pode girar um token ou mudar o modelo atrás de um handle sem reescrever suas instruções de repositório.

Escopos de conteúdo diferentes e idiomas-alvo podem usar modelos configurados diferentes. Modelos de decisão opcionais podem avaliar traduções completas e solicitar correção, enquanto humanos permanecem responsáveis pelo julgamento linguístico. Veja [Modelos de conta](./account-models) para o comportamento atual e limitações.

## Seu repositório já sabe o que conteúdo válido significa

A visão de uma string de um sistema de gerenciamento de tradução não é necessariamente a visão do aplicativo de um arquivo. Um repositório pode ter seu próprio parser, compilador, regras de componente, build de documentação e verificações de placeholders.

A Glossia pode reutilizar essas verificações através `L10N.md` de comandos de validação. Ele escreve o candidato temporariamente em seu caminho de destino real para validação e o aceita apenas após as verificações necessárias serem completadas. O comando e suas dependências devem estar disponíveis no ambiente de execução.

Isso permite que a equipe estenda seu limite de qualidade existente, em vez de manter uma definição separada de "válido" exclusivamente dentro de um ambiente de tradução. Veja [L10N.md](/docs/reference/l10n-md).

## Implementação pública, não uma caixa preta

O aplicativo, CLI, SDK e fontes de deploy da Glossia são públicos. Você pode inspecionar como o conteúdo é tratado e modificar ou hospedar a implementação sob a [licença O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). A licença restringe serviços hospedados concorrentes e não é uma licença de código aberto restrita.

Uma suíte de tradução mais ampla pode fazer sentido para operações de tradução especializadas e coordenação complexa. Se sua prioridade é **alinhando a velocidade da entrega de software com seus próprios tokens e verificações de repositório**, a Glossia é projetada para manter esse fluxo direto.

Mover um programa de tradução estabelecido ainda requer um plano para suas memórias, terminologia e histórico. Esta página não promete um importador automático da Phrase ou paridade completa da suíte, ou afirmar que a Phrase carece de todas as integrações equivalentes. Consulte [documentação da Phrase](https://support.phrase.com/) para as capacidades atuais do produto específico.
