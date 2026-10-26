%{
  title: "Glossia versus Lokalise",
  summary:
    "Mantenha a localização do produto na sua pipeline de entrega, com fonte pública, seus próprios tokens de modelo e validação nativa.",
  category: "Explicação",
  markdown_only: true,
  section: "translation",
  order: 21
}
---

**Escolha o Glossia quando o repositório do produto deve permanecer a autoridade para conteúdo multilíngue.** Strings, documentação, configurações e suas verificações já evoluem junto com sua aplicação. O Glossia mantém as alterações de linguagem conectadas a essa evolução, em vez de pedir à sua equipe que torne um editor hospedado a autoridade de publicação.

[Lokalise](https://lokalise.com/) oferece localização colaborativa, gerenciamento de tradução e integrações de desenvolvedor. A proposta do Glossia é mais específica: mantenha o fluxo de trabalho do repositório, traga suas próprias credenciais de modelo, reutilize as verificações existentes e inspecione o sistema que executa o trabalho.

## Por que escolher Glossia

| Sua prioridade | A vantagem do Glossia |
|---|---|
| Corresponda à velocidade de entrega de software | As alterações na fonte impulsionam o trabalho de tradução; as saídas propostas retornam por meio de um fluxo de trabalho de revisão de repositório. |
| Tenha controle sobre a implementação | Código fonte público torna o processamento inspecionável e suporta modificação e auto-hospedagem nos termos da licença. |
| Use seus próprios tokens de modelo | As credenciais do provedor com escopo na conta permitem escolher modelos suportados sem inserir segredos no Git. |
| Valide o conteúdo real da aplicação | Scripts do repositório podem verificar o candidato no local esperado pela aplicação. |
| Preserve um limite de revisão claro | Pull requests mantêm as alterações de linguagem visíveis nas mesmas ferramentas usadas para revisar o produto. |

## Mantenha as alterações de linguagem vinculadas às alterações do produto

Uma nova mensagem da interface de usuário ou seção de documentação não é uma tarefa de tradução isolada. Ela pertence a uma revisão do produto, usa sua terminologia e deve funcionar com sua estrutura.

O Glossia lê a configuração de propriedade do repositório `L10N.md` , usa alterações de conteúdo e contexto para identificar traduções desatualizadas e propõe atualizações para revisão. Os revisores veem arquivos reais e diffs; a pipeline de publicação continua sendo sua.

O Lokalise também possui automação e integrações Git. A distinção do Glossia é o sistema de registro pretendido: seu repositório possui o conteúdo publicado e suas regras de entrega, enquanto o Glossia fornece o contexto de linguagem e as mecânicas de transformação.

## Leve seus próprios tokens em vez de fixar rigidamente uma escolha de modelo

O Glossia permite configurar modelos suportados usando seus próprios tokens de API do provedor. Um repositório usa um identificador de modelo estável, assim a rotação de credenciais ou a atualização do modelo por trás desse identificador não exige alterar cada projeto.

Configuração aninhada e orientações específicas do locale podem selecionar um modelo configurado diferente para uma área ou linguagem específica. Esta é uma seleção explícita, não uma promessa de failover automático do provedor. Veja [Modelos de conta](./account-models).

## Reutilize a validação que já conhece sua aplicação

Seu repositório pode já saber como detectar strings inválidas, arquivos com formato incorreto, atributos de componentes quebrados ou falha na compilação de documentos. O Glossia pode invocar esse conhecimento por meio de um comando de validação configurado.

O candidato é temporariamente colocado em seu caminho de saída real para a verificação. O alvo anterior é restaurado após cada tentativa de validação, e o candidato aceito é escrito em seguida. A saída rejeitada passa pelo orçamento de recuperação configurado em vez de ser aceita simplesmente porque o texto parece plausível.

Verificações estruturais e de repositório não provam que cada frase está correta. Elas complementam a revisão de linguagem humana e tornam aquela revisão parte de uma mudança entregável. Veja [L10N.md](/docs/reference/l10n-md) e [Recuperação de tradução](./translation-recovery).

## Código fonte público e saídas de propriedade do repositório

O núcleo do Glossia está disponível para inspeção, modificação, distribuição e auto-hospedagem sob [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), o que também permite serviços hospedados concorrentes. Código Enterprise sob `ee/` tem uma [licença](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada exigindo um acordo comercial escrito para uso em produção.

Mais importante para a entrega diária, suas saídas traduzidas permanecem no Git. Você não precisa de uma sessão de edição em outro produto simplesmente para publicar os arquivos existentes que possui.

O Lokalise pode servir a uma equipe que deseja edição centralizada no navegador e coordenação de localização. O Glossia é a escolha quando **propriedade do repositório, seus próprios tokens do modelo e verificações existentes do produto** são o fluxo de trabalho que você deseja manter.

Teste uma alteração representativa antes de mudar os sistemas. Esta página não promete migração automática ou equivalência de recursos, nem afirma que o Lokalise carece de automação ou todas as opções de provedor. Veja [Documentação do Lokalise](https://docs.lokalise.com/) para suas capacidades atuais.
