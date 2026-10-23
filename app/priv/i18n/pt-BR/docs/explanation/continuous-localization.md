%{
  title: "Localização contínua",
  summary:
    "Faça as alterações de idioma parte do ciclo de entrega versionado do produto, e não um ciclo separado de exportação e importação.",
  category: "explicação",
  section: "translation",
  order: 2
}
---

A entrega contínua funciona porque pequenas mudanças passam por um pipeline repetível: controle de versão, revisão, validação e implantação. A localização deve se encaixar nesse pipeline em vez de introduzir um sistema de registro não relacionado.

## O loop desconectado

Em um fluxo de trabalho desconectado, uma alteração do produto dispara uma exportação, o trabalho ocorre em outra ferramenta e o conteúdo traduzido eventualmente retorna. Entre esses passos, a fonte pode mudar novamente. As equipes têm que harmonizar versões, decidir se as traduções estão desatualizadas e coordenar outro lançamento.

O problema não é que um editor web seja inerentemente incorreto. É que um sistema de edição com autoridade própria pode separar decisões de linguagem do código e da revisão de conteúdo que descrevem.

## O loop do repositório

O fluxo de trabalho do repositório do Glossia mantém arquivos de origem e configuração de localização no Git. Um repositório conectado fornece o conteúdo e as linguagens de destino. As alterações de tradução retornam como alterações de repositório revisáveis, para que as equipes possam aplicar suas convenções existentes de pull request e publicação.

Um loop típico é:

1. Uma equipe altera o conteúdo de origem com o produto.
2. O Glossia identifica conteúdo que precisa de tradução ou refinamento.
3. Orientação de linguagem e terminologia fornecem contexto para a transformação.
4. A validação verifica o resultado e as falhas permanecem acionáveis.
5. Os revisores inspecionam as alterações antes que o pipeline de publicação as entregue.

[Refinamento progressivo](./progressive-refinement) explica como hachagem e validação se encaixam neste loop. [Recuperação de tradução](./translation-recovery) explica o que acontece quando a geração ou a validação falha.

## Contínuo não significa sem revisão

Uma mudança continuamente entregável não é necessariamente uma mudança automaticamente aprovada. Linguagem legal, promessas de produto e materiais culturalmente sensíveis podem exigir revisão especializada. Manter essa revisão no loop de entrega permite que uma equipe escolha o ponto de parada apropriado sem manter uma autoridade de publicação separada.

A localização contínua também não significa traduzir todo o repositório em cada commit. Conteúdo não alterado não deve consumir os mesmos recursos repetidamente.

## O limite prático

O Glossia fornece contexto de linguagem e mecânicas de localização. As verificações e o processo de implantação do seu repositório ainda definem quando uma alteração é segura para publicação. O Glossia não é um substituto para testes de aplicação ou a responsabilidade de um editor pela precisão.

Outras plataformas também oferecem integrações Git e automação de CI. A distinção está no centro de gravidade pretendido: O Glossia é construído em torno da propriedade e revisão do conteúdo no repositório, não em um requisito para transferir a autoridade editorial contínua para um espaço de tradução hospedado.
