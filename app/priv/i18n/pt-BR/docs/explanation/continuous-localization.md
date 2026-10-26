%{
  title: "Localização contínua",
  summary:
    "Faça as alterações de idioma parte do ciclo de entrega versionado do produto, em vez de um ciclo separado de exportação e importação.",
  category: "explicação",
  section: "translation",
  order: 2
}
---

A entrega contínua funciona porque pequenas alterações transitam por um pipeline repetível: controle de versão, revisão, validação e implantação. A localização deve se encaixar nesse pipeline em vez de introduzir um sistema de registro não relacionado.

## O loop desconexo

Em um fluxo de trabalho desconexo, uma alteração no produto gatilha uma exportação, o trabalho ocorre em outra ferramenta e o conteúdo traduzido eventualmente retorna. Entre essas etapas, a fonte pode mudar novamente. As equipes precisam harmonizar as versões, decidir se as traduções estão desatualizadas e coordenar outro lançamento.

O problema não é que um editor de web seja inerentemente errado. É que um sistema de edição autoritário de forma independente pode separar decisões de idioma do código e da revisão de conteúdo que descreve.

## O loop do repositório

O fluxo de trabalho de repositório do Glossia mantém arquivos de origem e configuração de localização no Git. Um repositório conectado fornece o conteúdo e os idiomas alvo. As alterações de tradução retornam como alterações de repositório revisíveis, para que as equipes possam aplicar suas convenções existentes de pull request e publicação.

Um loop típico é:

1. Uma equipe altera o conteúdo de origem junto com o produto.
2. O Glossia identifica o conteúdo que precisa de tradução ou refinamento.
3. Orientações de idioma e terminologia fornecem contexto para a transformação.
4. A validação verifica o resultado e as falhas permanecem acionáveis.
5. Os revisores inspecionam as alterações antes que o pipeline de publicação as entregue.

[Refinamento progressivo](./progressive-refinement) explica como o hash e a validação se encaixam neste loop. [Recuperação de tradução](./translation-recovery) explica o que acontece quando a geração ou a validação falha.

## Contínuo não significa sem revisão

Uma alteração continuamente entregável não é necessariamente uma alteração automaticamente aprovada. Linguagem jurídica, promessas do produto e material culturalmente sensível podem necessitar de revisão especializada. Manter essa revisão no loop de entrega permite que a equipe escolha o ponto de controle apropriado sem manter uma autoridade de publicação separada.

Também a localização contínua não significa traduzir todo o repositório a cada commit. O conteúdo não alterado não deve consumir os mesmos recursos repetidamente.

## O limite prático

O Glossia fornece contexto de idioma e mecânicas de localização. As verificações e o processo de implantação do seu repositório ainda definem quando uma alteração é segura para publicação. O Glossia não é um substituto para testes de aplicação nem a responsabilidade de um editor pela precisão.

Outras plataformas também oferecem integrações Git e automação de CI. A distinção é o centro de gravidade pretendido: o Glossia foi construído em torno da propriedade e revisão do conteúdo no repositório, e não existe uma exigência de transferir a autoridade editorial contínua para um workspace de tradução hospedado.
