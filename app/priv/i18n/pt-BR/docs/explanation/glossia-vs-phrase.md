%{
  title: "Glossia versus Phrase",
  summary:
    "Escolha um fluxo de trabalho nativo do repositório com fonte pública, seus próprios tokens de modelo e verificações de entrega reutilizáveis.",
  category: "explicação",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Escolha o Glossia quando quiser que o trabalho de linguagem siga o sistema de entrega do seu produto, em vez de construir um processo paralelo de gerenciamento de tradução em torno dele.** Mantenha o conteúdo no Git, escolha modelos suportados usando suas próprias credenciais e valide os resultados com as verificações em que seu repositório já confia.

[Phrase](https://phrase.com/) oferece uma suíte de localização, incluindo Phrase Strings e Phrase TMS para necessidades diferentes de localização de software e tradução gerenciada. O Glossia adota uma abordagem focada: dê às equipes de software um sistema operacional de linguagem que se adapte ao seu ciclo existente de revisão e entrega.

## Por que escolher o Glossia

| Sua prioridade | A vantagem do Glossia |
|---|---|
| Entregue alterações de idioma com o software | Alterações no repositório impulsionam a localização, e os retornos voltam como alterações passíveis de revisão. |
| Inspecione e domine o processamento | Um código-fonte público expõe a implementação da aplicação e do implantação, permitindo modificações e hospedagem própria conforme os termos da licença. |
| Leve seus próprios tokens | Configure suas próprias credenciais de provedor de modelo suportados; selecione modelos através de handles de conta na configuração do repositório. |
| Reutilize fluxos de validação | Execute verificações nativas do repositório em candidatos a tradução, em vez de tratar a aprovação linguística como prova de que um arquivo será compilado. |
| Mantenha a propriedade durável | Arquivos publicados, configuração e histórico de pull requests permanecem com o repositório. |

## Faça da localização parte da entrega contínua

A detecção de alterações do Glossia evita repetir trabalho de tradução para entradas não alteradas. Seu fluxo de trabalho de repositório mantém um único pull request de tradução aberto por projeto e publica o progresso em lotes, de modo que um repositório de origem em movimento rápido não precisa de um novo processo de tradução para cada pequena alteração.

O objetivo não é uma corrida para produção sem revisão. É tornar continuamente o trabalho de linguagem passível de revisão e entregável através do pipeline que sua equipe já utiliza.

O Phrase também oferece APIs, integrações e automação. A vantagem enfatizada pelo Glossia é o alinhamento arquitetônico: o repositório permanece a autoridade de conteúdo e a fronteira de entrega, em vez de apenas ser um local para sincronizar os resultados de outro espaço de trabalho.

## Mantenha a escolha de modelos e credenciais sob seu controle

O Glossia aceita seus próprios tokens de API de provedor para modelos suportados. Credenciais permanecem nas configurações da conta; repositórios selecionam handles estáveis. Uma equipe pode rotacionar um token ou alterar o modelo por trás de um handle sem reescrever suas instruções de repositório.

Diferentes escopos de conteúdo e idiomas-alvo podem usar modelos configurados diferentes. Modelos de decisão opcionais podem avaliar traduções completas e solicitar correção, enquanto humanos permanecem responsáveis pelo julgamento linguístico. Veja [Modelos de conta](./account-models) para o comportamento e limites atuais.

## Seu repositório já sabe o que significa conteúdo válido

A visão de um sistema de gerenciamento de tradução de um atributo não é necessariamente a visão da aplicação de um arquivo. Um repositório pode ter seu próprio parser, compilador, regras de componente, documentação de compilação e verificações de placeholder.

O Glossia pode reutilizar essas verificações através de `L10N.md` comandos de validação. Ele escreve o candidato temporariamente para seu caminho de destino real para validação e aceita-o apenas após as verificações necessárias passarem. O comando e suas dependências devem estar disponíveis no ambiente de execução.

Isso permite que a equipe estenda sua fronteira de qualidade existente em vez de manter uma definição separada de "válido" exclusivamente dentro de um espaço de tradução. Veja [L10N.md](/docs/reference/l10n-md).

## Implementação pública, não uma caixa preta

A aplicação, CLI, SDK e origens de implantação do Glossia são públicas. Você pode inspecionar como o conteúdo é manipulado e modificar ou hospedar a implementação por conta própria sob a [O'Saasy license](https://github.com/glossia/glossia/blob/main/LICENSE.md). A licença limita os serviços hospedados concorrentes e não é uma licença de código aberto irrestrita.

Uma suíte de tradução mais ampla pode fazer sentido para operações de tradução especializadas e coordenação complexa. Se sua prioridade é **matching software-delivery speed with your own tokens and repository checks**, o Glossia é projetado para manter esse fluxo direto.

Mover um programa de tradução estabelecido ainda exige um plano para suas memórias, terminologia e história. Esta página não promete um importador do Phrase automático ou paridade total de suíte, nem afirma que o Phrase carece de todas as integrações equivalentes. Consulte [documentação do Phrase](https://support.phrase.com/) para as capacidades atuais do produto específico.
