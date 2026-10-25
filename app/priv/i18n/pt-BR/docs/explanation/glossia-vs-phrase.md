%{
  title: "Glossia vs Phrase",
  summary:
    "Escolha um fluxo de trabalho de idioma nativo do repositório com fonte pública, seus próprios tokens de modelo e verificações de entrega reutilizáveis.",
  category: "Explicação",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Escolha o Glossia quando quiser que o trabalho de idiomas siga o sistema de entrega do seu produto, em vez de criar um processo paralelo de gerenciamento de tradução em torno dele.** Mantenha o conteúdo no Git, escolha modelos suportados usando suas próprias credenciais e valide os resultados com as verificações que seu repositório já confia.

[Phrase](https://phrase.com/) oferece uma suíte de localização, incluindo Phrase Strings e Phrase TMS para diferentes necessidades de localização de software e tradução gerenciada. O Glossia adota uma abordagem focada: dê às equipes de software um OS de idiomas que se adapte ao ritmo de revisão e entrega que elas já têm.

## Por que escolher o Glossia

| Sua prioridade | A vantagem do Glossia |
|---|---|
| Entregue mudanças de idioma junto com o software | Alterações no repositório impulsionam a localização, e as saídas retornam como alterações revisáveis. |
| Inspeção e controle do processamento | A fonte pública expõe a aplicação e a implementação de implantação, com modificações e hospedagem própria permitidas por meio dos termos da licença. |
| Traga seus próprios tokens | Configure suas próprias credenciais de provedor de modelos suportados; selecione modelos por meio de nomes de conta na configuração do repositório. |
| Reutilize pipelines de validação | Execute verificações nativas do repositório nos candidatos de tradução em vez de tratar a aprovação linguística como prova de que um arquivo será compilado. |
| Garanta propriedade duradoura | Arquivos publicados, configuração e histórico de pull request permanecem com o repositório. |

## Faça da localização parte da entrega contínua

A detecção de alterações do Glossia evita repetir o trabalho de tradução para entradas não alteradas. Seu fluxo de repositório mantém uma solicitação de pull de tradução aberta por projeto e publica o progresso em lotes, de modo que um repositório de origem em rápida mudança não precisa de um novo processo de tradução para cada pequena alteração.

O objetivo não é uma corrida irrevisada para produção. É tornar o trabalho com idiomas continuamente revisável e entregável pelo pipeline que sua equipe já usa.

A Phrase oferece APIs, integrações e automação também. A vantagem que o Glossia enfatiza é o alinhamento arquitetônico: o repositório permanece como a autoridade de conteúdo e o limite de entrega, em vez de ser apenas um local para sincronizar os resultados de outro ambiente de trabalho.

## Mantenha a escolha do modelo e as credenciais sob seu controle

O Glossia aceita seus próprios tokens API do provedor para modelos suportados. As credenciais permanecem nas configurações da conta; os repositórios selecionam nomes de conta estáveis. Uma equipe pode rotacionar um token ou mudar o modelo por trás de um nome de conta sem reescrever suas instruções de repositório.

Escopos de conteúdo e idiomas-alvo diferentes podem usar modelos configurados diferentes. Modelos de decisão opcionais podem avaliar traduções completas e solicitar correção, enquanto humanos permanecem responsáveis pelo julgamento linguístico. Veja [Modelos de conta](./account-models) para o comportamento e limites atuais.

## Seu repositório já sabe o que significa conteúdo válido

A visão de um sistema de gerenciamento de tradução de uma string não é necessariamente a visão da aplicação de um arquivo. Um repositório pode ter seu próprio analisador, compilador, regras de componente, compilação de documentação e verificações de placeholders.

O Glossia pode reutilizar essas verificações por meio de `L10N.md` comandos de validação. Ele escreve o candidato temporariamente para seu caminho real de destino para validação e o aceita apenas após as verificações necessárias serem concluídas. O comando e suas dependências devem estar disponíveis no ambiente de execução.

Isso permite que a equipe estenda seu limite de qualidade existente em vez de manter uma definição separada de "válido" apenas dentro de um ambiente de tradução. Veja [L10N.md](/docs/reference/l10n-md).

## Implementação pública, não uma caixa preta

A aplicação do Glossia, CLI, SDK e fontes de implantação são públicas. Você pode inspecionar como o conteúdo é tratado e modificar ou fazer hospedagem própria da implementação sob a [O'Saasy license](https://github.com/glossia/glossia/blob/main/LICENSE.md). A licença limita serviços hospedados concorrentes e não é uma licença open-source sem restrições.

Uma suite de tradução mais ampla faz sentido para operações de tradução especializadas e coordenação complexa. Se sua prioridade é **alinhando a velocidade de entrega de software com seus próprios tokens e verificações de repositório**, o Glossia é projetado para manter esse fluxo direto.

Mover um programa de tradução estabelecido ainda exige um plano para suas memórias, terminologia e histórico. Esta página não promete um importador automático de Phrase ou paridade completa de suite, nem afirma que o Phrase falta todas as integrações equivalentes. Consulte [Documentação do Phrase](https://support.phrase.com/) para as capacidades atuais do produto específico.
