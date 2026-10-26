%{
  title: "Glossia vs Phrase",
  summary:
    "Escolha um fluxo nativo de linguagem ao repositório com fonte pública, seus próprios tokens de modelo e verificações de entrega reutilizáveis.",
  category: "Explicação",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Escolha o Glossia quando deseja que o trabalho com o idioma siga o sistema de entrega do seu produto, em vez de criar um processo paralelo de gerenciamento de tradução em torno dele.** Mantenha o conteúdo no Git, escolha modelos apoiados usando suas próprias credenciais e valide os resultados com as verificações que seu repositório já confia.

O [Phrase](https://phrase.com/) fornece uma suíte de localização, incluindo Phrase Strings e Phrase TMS para diferentes necessidades de localização de software e tradução gerenciada. O Glossia adota uma abordagem focada: ofereça às equipes de software um sistema operacional de idioma que se adeque ao seu ciclo existente de revisão e entrega.

## Por que escolher o Glossia

| Sua prioridade | Vantagem do Glossia |
|---|---|
| Entregue alterações de idioma com software | Alterações no repositório impulsionam a localização, e os resultados retornam como alterações passíveis de revisão. |
| Inspeccione e assuma o processamento | A fonte pública expõe a aplicação e a implementação de implantação, com modificação e hospedagem próprias permitidas nos termos da licença. |
| Leve seus próprios tokens | Configure suas próprias credenciais de provedor de modelos apoiados; selecione modelos através de alvos de conta na configuração do repositório. |
| Reutilize pipelines de validação | Execute verificações nativas do repositório em candidatos de tradução, em vez de tratar a aprovação linguística como prova de que um arquivo será compilado. |
| Mantenha uma propriedade duradoura | Arquivos publicados, configuração e histórico de solicitações de pull permanecem com o repositório. |

## Inclua a localização na entrega contínua

A detecção de alterações do Glossia evita repetir o trabalho de tradução para entradas inalteradas. Seu fluxo de trabalho do repositório mantém uma única solicitação de pull de tradução aberta por projeto e publica o progresso em lotes, de forma que um repositório de origem em movimento rápido não precise de um novo processo de tradução para cada pequena alteração.

O objetivo não é uma corrida não supervisionada para o ambiente de produção. É tornar o trabalho com o idioma continuamente passível de revisão e entregável através do pipeline que sua equipe já utiliza.

A Phrase também oferece APIs, integrações e automação. A vantagem que o Glossia enfatiza é o alinhamento arquitetural: o repositório permanece como a autoridade do conteúdo e a fronteira de entrega, em vez de apenas ser um local para sincronizar os resultados de outro ambiente de trabalho.

## Mantenha a escolha do modelo e as credenciais sob seu controle

O Glossia aceita seus próprios tokens de API do provedor para modelos apoiados. As credenciais permanecem nas configurações da conta; os repositórios selecionam alvos estáveis. Uma equipe pode rotacionar um token ou alterar o modelo atrás de um alvo sem reescrever suas instruções de repositório.

Escopos de conteúdo diferentes e idiomas-alvo podem usar modelos configurados diferentes. Modelos de decisão opcionais podem avaliar traduções completas e solicitar correções, enquanto os seres humanos permanecem responsáveis pelo juízo linguístico. Veja [Modelos de conta](./account-models) para o comportamento atual e limitações.

## Seu repositório já sabe o que significa conteúdo válido

A visão de um sistema de gerenciamento de tradução de uma string não é necessariamente a visão da aplicação de um arquivo. Um repositório pode ter seu próprio parser, compilador, regras de componente, documentação de build e verificações de placeholders.

O Glossia pode reutilizar essas verificações através de `L10N.md` comandos de validação. Ele escreve o candidato temporariamente em seu caminho real de alvo para validação e o aceita apenas após o sucesso das verificações necessárias. O comando e suas dependências devem estar disponíveis no ambiente de execução.

Isso permite à equipe estender sua fronteira de qualidade existente, em vez de manter uma definição separada de "válido" apenas dentro de um ambiente de trabalho de tradução. Consulte [L10N.md](/docs/reference/l10n-md).

## Implementação pública, não uma caixa preta

A aplicação, a CLI, o SDK e as fontes de implantação do Glossia são públicas. O núcleo é de código aberto sob [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite modificação, distribuição, hospedagem própria e serviços concorrentes. Código empresarial sob `ee/` possui uma [licença](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada que exige um acordo comercial escrito para uso em produção.

Uma suíte de tradução mais ampla pode fazer sentido para operações de tradução especializadas e coordenação complexa. Se sua prioridade é **corresponder à velocidade de entrega de software com seus próprios tokens e verificações de repositório**, o Glossia é projetado para manter esse fluxo direto.

Migrar um programa de tradução estabelecido ainda exige um plano para suas memórias, terminologia e história. Esta página não promete um importador automático do Phrase ou paridade completa de suíte, ou afirmar que o Phrase carece de todas as integrações equivalentes. Consulte [documentação do Phrase](https://support.phrase.com/) para as capacidades atuais do produto específico.
