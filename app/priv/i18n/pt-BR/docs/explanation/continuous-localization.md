%{
  title: "Localização contínua",
  summary:
    "Faça alterações de idioma parte do ciclo de entrega versionado do produto, não de um ciclo separado de exportação e importação.",
  category: "explicação",
  section: "translation",
  order: 2
}
---

A entrega contínua funciona porque pequenas mudanças transitam por um pipeline repetível: controle de versão, revisão, validação e implantação. A localização deve se adaptar a esse pipeline, em vez de introduzir um sistema de registro não relacionado.

## O ciclo desconectado

Em um fluxo de trabalho desconectado, uma alteração no produto dispara uma exportação, o trabalho ocorre em outra ferramenta e o conteúdo traduzido eventualmente retorna. Entre esses passos, a fonte pode mudar novamente. As equipes precisam conciliar versões, decidir se as traduções estão desatualizadas e coordenar outra release.

O problema não é que um editor web seja inerentemente incorreto. É que um sistema editorial com autoridade independente pode separar decisões de linguagem da revisão de código e conteúdo que descreve.

## O ciclo do repositório

O fluxo de trabalho do repositório da Glossia mantém arquivos de fonte e configuração de localização no Git. Um repositório conectado fornece o conteúdo e os idiomas-alvo. Alterações de tradução retornam como alterações de repositório revisíveis, permitindo que as equipes apliquem suas convenções existentes de pull-request e publicação.

Um loop típico é:

1. Uma equipe altera o conteúdo de fonte com o produto.
2. A Glossia identifica o conteúdo que precisa de tradução ou refinamento.
3. Orientação de linguagem e terminologia fornecem contexto para a transformação.
4. A validação verifica o resultado e as falhas permanecem acionáveis.
5. Os revisores inspecionam as alterações antes que o pipeline de publicação as entregue.

[Refinamento progressivo](./progressive-refinement) explica como o hash e a validação se encaixam neste loop. [Recuperação de tradução](./translation-recovery) explica o que acontece quando a geração ou validação falha.

## Contínuo não significa sem revisão

Uma mudança continuamente entregável não é necessariamente uma mudança automaticamente aprovada. A linguagem jurídica, promessas do produto e material culturalmente sensível podem precisar de revisão especializada. Manter essa revisão no ciclo de entrega permite que uma equipe escolha o controle de segurança adequado sem manter uma autoridade de publicação separada.

A localização contínua também não significa traduzir todo o repositório em cada commit. O conteúdo inalterado não deve consumir os mesmos recursos repetidamente.

## O limite prático

A Glossia fornece contexto de idioma e mecânicas de localização. As verificações e o processo de implantação do seu repositório ainda definem quando uma mudança é segura para publicação. A Glossia não é um substituto para testes de aplicação ou a responsabilidade de um editor quanto à precisão.

Outras plataformas também oferecem integrações Git e automação CI. A distinção é o centro de gravidade pretendido: a Glossia é construída em torno da propriedade do conteúdo e revisão no repositório, não uma exigência de mover a autoridade editorial contínua para um workspace de tradução hospedado.
