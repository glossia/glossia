%{
  title: "Glossia x Lokalise",
  summary:
    "Mantenha a localização do produto no seu pipeline de entrega, com fonte pública, seus próprios tokens de modelo e validação nativa.",
  category: "explicação",
  markdown_only: true,
  section: "translation",
  order: 21
}
---

**Escolha Glossia quando o repositório do produto deve permanecer a autoridade para o conteúdo multilíngue.** Strings, documentação, configuração e suas verificações já evoluem com sua aplicação. A Glossia mantém as alterações de idioma associadas a essa evolução, em vez de pedir à sua equipe para fazer de um editor hospedado a autoridade de publicação.

[Lokalise](https://lokalise.com/) oferece localização colaborativa, gerenciamento de traduções e integrações para desenvolvedores. O argumentação da Glossia é mais específico: mantenha o fluxo de trabalho do repositório, traga suas próprias credenciais de modelo, reutilize suas verificações existentes e inspecione o sistema que realiza o trabalho.

## Por que escolher Glossia

| Sua prioridade | A vantagem da Glossia |
|---|---|
| Alinhar velocidade de entrega de software | Alterações na fonte impulsionam o trabalho de tradução; as saídas propostas retornam através de um fluxo de revisão de repositório. |
| Tenha o controle da implementação | Uma fonte pública torna o processamento inspecionável e suporta modificação e hospedagem própria dentro dos termos da licença. |
| Use seus próprios tokens de modelo | Credenciais de provedor com escopo de conta permitem escolher modelos suportados sem colocar segredos no Git. |
| Valide o conteúdo real da aplicação | Scripts do repositório podem verificar o candidato onde a aplicação espera encontrá-lo. |
| Preserve uma clara fronteira de revisão | Pull requests mantêm as alterações de idioma visíveis nas mesmas ferramentas usadas para revisar o produto. |

## Mantenha as alterações de idioma associadas às alterações do produto

Uma nova mensagem de interface ou seção de documentação não é uma tarefa de tradução isolada. Ela pertence a uma revisão de produto, utiliza sua terminologia e deve funcionar com sua estrutura.

A Glossia lê a configuração `L10N.md` de propriedade do repositório, usa alterações de conteúdo e contexto para identificar traduções obsoletas e propõe atualizações para revisão. Os revisores veem arquivos e diffs reais; a cadeia de publicação permanece sob seu controle.

Lokalise também possui automação e integrações com Git. A distinção da Glossia é o sistema de registro pretendido: seu repositório detém o conteúdo publicado e suas regras de entrega, enquanto a Glossia fornece contexto de idioma e mecânicas de transformação.

## Traga seus próprios tokens em vez de gravar uma escolha de modelo

A Glossia permite configurar modelos suportados usando seus próprios tokens de API de provedor. Um repositório usa um identificador de modelo estável, de modo que rotacionar credenciais ou atualizar o modelo por trás desse identificador não requer alterar todos os projetos.

Configuração aninhada e orientações específicas de locale podem selecionar um modelo configurado diferente para uma área ou idioma particular. Esta é uma seleção explícita, não uma promessa de failover automático do provedor. Consulte [Modelos de conta](./account-models).

## Reutilize a validação que já conhece sua aplicação

Seu repositório pode já saber como detectar strings inválidas, arquivos malformados, atributos de componente quebrados ou falha na compilação de documentação. A Glossia pode invocar esse conhecimento por meio de um comando de validação configurado.

O candidato é colocado temporariamente em seu caminho de saída real para a verificação. O alvo anterior é restaurado após cada tentativa de validação, e o candidato aceito é escrito em seguida. Uma saída rejeitada passa pelo orçamento de recuperação configurado, em vez de ser aceita apenas porque o texto parece plausível.

Verificações estruturais e de repositório não comprovam que todas as frases estão corretas. Elas complementam a revisão humana de idioma e tornam essa revisão parte de uma alteração entregável. Consulte [L10N.md](/docs/reference/l10n-md) e [Recuperação de tradução](./translation-recovery).

## Fonte pública e saídas de propriedade do repositório

O Glossia segue um modelo open core. O núcleo utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite uso comercial, modificação, distribuição, auto-hospedagem e serviços hospedados concorrentes conforme seus termos. O código em `ee/` é visível, mas não é código aberto. Ele possui uma [licença Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada e seu uso em produção exige um acordo comercial por escrito.

Mais importante para a entrega diária, suas saídas traduzidas permanecem no Git. Você não precisa de uma sessão de edição em outro produto simplesmente para publicar os arquivos existentes que possui.

Lokalise pode servir a uma equipe que deseja edição centralizada no navegador e coordenação de localização. A Glossia é a escolha quando **propriedade do repositório, seus próprios tokens de modelo e verificações de produto existentes** são o fluxo de trabalho que você deseja manter.

Teste uma alteração representativa antes de alternar os sistemas. Esta página não promete migração automática ou paridade de recursos, nem afirma que o Lokalise falta automação ou todas as opções de provedor. Consulte [Documentação do Lokalise](https://docs.lokalise.com/) para suas capacidades atuais.
