%{
  title: "Glossia vs Lokalise",
  summary:
    "Mantenha a localização do produto no seu pipeline de entrega, com código-fonte público, seus próprios tokens de modelo e validação nativa.",
  category: "explicação",
  markdown_only: true,
  section: "translation",
  order: 21
}
---

**Escolha o Glossia quando o repositório do produto deve permanecer a autoridade para conteúdo multilíngue.** Strings, documentação, configuração e suas verificações já evoluem com sua aplicação. O Glossia mantém as alterações de idioma vinculadas a essa evolução, em vez de pedir à sua equipe que faça um editor hospedado a autoridade de publicação.

[Lokalise](https://lokalise.com/) oferece localização collaborativa, gerenciamento de tradução e integrações de desenvolvedor. A proposta do Glossia é mais específica: mantenha o fluxo de trabalho do repositório, traga suas próprias credenciais de modelo, reutilize suas verificações existentes e inspecione o sistema que executa o trabalho.

## Por que escolher o Glossia

| Sua prioridade | Vantagem do Glossia |
|---|---|
| Corresponda à velocidade de entrega de software | As alterações no código impulsionam o trabalho de tradução; as saídas propostas retornam através de um fluxo de trabalho de revisão de repositório. |
| Controle a implementação | Código fonte público torna o processamento inspecionável e apoia modificação e auto-hospedagem de acordo com os termos da licença. |
| Use seus próprios tokens de modelo | Credenciais de provedor escopadas por conta permitem que você escolha modelos suportados sem colocar segredos no Git. |
| Valide o conteúdo real da aplicação | Os scripts do repositório podem verificar o candidato onde a aplicação espera encontrá-lo. |
| Preserve um limite de revisão claro | Os Pull Requests mantêm as alterações de idioma visíveis na mesma ferramenta usada para revisar o produto. |

## Mantenha as alterações de idioma vinculadas às alterações do produto

Uma nova mensagem de interface do usuário ou seção de documentação não é uma tarefa de tradução isolada. Ela pertence a uma revisão do produto, utiliza sua terminologia e deve funcionar com sua estrutura.

O Glossia lê a `L10N.md` configuração de propriedade do repositório, usa alterações de conteúdo e contexto para identificar traduções obsoletas e propõe atualizações para revisão. Os revisores veem arquivos reais e diffs; o pipeline de publicação permanece seu.

Lokalise também possui automações e integrações do Git. A distinção do Glossia é o sistema de registro pretendido: seu repositório possui o conteúdo publicado e suas regras de entrega, enquanto o Glossia fornece contexto de idioma e os mecanismos de transformação.

## Traga seus próprios tokens em vez de codificar rigidamente uma escolha de modelo

O Glossia permite que você configure modelos suportados usando seus próprios tokens de API de provedor. Um repositório usa um identificador de modelo estável, então rotacionar credenciais ou atualizar o modelo por trás desse identificador não exige alterar cada projeto.

Configuração aninhada e orientações específicas do locale podem selecionar um modelo configurado diferente para uma área ou idioma específico. Isso é seleção explícita, não uma promessa de recuperação automática de provedor. Veja [Modelos de conta](./account-models).

## Reutilize a validação que já conhece sua aplicação

Seu repositório pode já saber como detectar strings inválidas, arquivos malformados, atributos de componente quebrados ou falha de build de documentação. O Glossia pode invocar esse conhecimento através de um comando de validação configurado.

O candidato é temporariamente colocado em seu caminho de saída real para a verificação. O alvo anterior é restaurado após cada tentativa de validação, e o candidato aceito é escrito posteriormente. A saída rejeitada passa pelo orçamento de recuperação configurado em vez de ser aceita apenas porque o texto parece plausível.

As verificações estruturais e de repositório não provam que cada frase está correta. Elas complementam a revisão linguística humana e fazem dessa revisão parte de uma alteração entregável. Veja [L10N.md](/docs/reference/l10n-md) e [Recuperação de tradução](./translation-recovery).

## Código-fonte público e saídas de propriedade do repositório

A implementação do Glossia está disponível para inspeção, modificação e auto-hospedagem sob [O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Essa licença restringe serviços hospedados concorrentes e não é uma licença open-source sem restrições.

Mais importante para a entrega diária, suas saídas traduzidas permanecem no Git. Você não precisa de uma sessão de edição em outro produto apenas para publicar os arquivos existentes de propriedade sua.

Lokalise pode se adequar a uma equipe que deseja edição centralizada no navegador e coordenação de localização. O Glossia é a escolha quando **propriedade do repositório, seus próprios tokens de modelo e verificações de produto existentes** são o fluxo de trabalho que você deseja manter.

Teste uma alteração representativa antes de alternar os sistemas. Esta página não promete migração automática ou equivalência de recursos, nem afirma que o Lokalise carece de automação ou de todas as opções de provedor. Veja [documentação do Lokalise](https://docs.lokalise.com/) para suas capacidades atuais.
