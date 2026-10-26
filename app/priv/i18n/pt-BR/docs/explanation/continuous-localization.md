%{
  title: "Localização contínua",
  summary:
    "Incorpore as alterações de idioma ao ciclo de entrega versionado do produto, e não em um ciclo separado de exportação e importação.",
  category: "explicação",
  section: "translation",
  order: 2
}
---

A entrega contínua funciona porque pequenas alterações percorrem um pipeline repetível: controle de versão, revisão, validação e implantação. A localização deve se encaixar nesse pipeline em vez de introduzir um sistema de registro não relacionado.

## O ciclo desconectado

Em um fluxo de trabalho desconectado, uma alteração no produto dispara uma exportação, o trabalho ocorre em outra ferramenta e o conteúdo traduzido retorna. Entre esses passos, o conteúdo original pode mudar novamente. As equipes precisam reconciliar versões, decidir se as traduções estão desatualizadas e coordenar outra liberação.

O problema não é que um editor web seja inerentemente incorreto. É que um sistema de edição com autoridade independente pode separar decisões de idioma do código e da revisão de conteúdo que descrevem.

## O ciclo de repositório

O fluxo de trabalho de repositório do Glossia mantém os arquivos de origem e a configuração de localização no Git. Um repositório conectado fornece o conteúdo e os idiomas-alvo. As alterações de tradução retornam como alterações de repositório revisáveis, permitindo que as equipes apliquem suas convenções existentes de pull request e publicação.

Um ciclo típico é:

1. Uma equipe altera o conteúdo de origem com o produto.
2. O Glossia identifica o conteúdo que precisa de tradução ou refinamento.
3. Diretrizes linguísticas e terminologia fornecem contexto para a transformação.
4. A validação verifica o resultado e as falhas permanecem acionáveis.
5. Revisores inspecionam as alterações antes que o pipeline de publicação as entregue.

[Refinamento progressivo](./progressive-refinement) explica como o hash e a validação se encaixam nesse ciclo. [Recuperação de tradução](./translation-recovery) explica o que acontece quando a geração ou a validação falham.

## Contínuo não significa sem revisões

Uma alteração continuamente entregue não é necessariamente uma alteração automaticamente aprovada. Linguagem jurídica, promessas de produto e material culturalmente sensível podem exigir revisão especialista. Manter essa revisão no ciclo de entrega permite que uma equipe escolha o gate adequado sem manter uma autoridade de publicação separada.

A localização contínua também não significa traduzir todo o repositório a cada commit. O conteúdo não alterado não deve consumir os mesmos recursos repetidamente.

## O limite prático

O Glossia fornece contexto linguístico e mecânica de localização. As verificações e o processo de implantação do seu repositório ainda definem quando uma alteração é segura para publicação. O Glossia não substitui testes de aplicativo nem a responsabilidade do editor quanto à precisão.

Outras plataformas também oferecem integrações de Git e automação de CI. A distinção é o centro de gravidade pretendido: o Glossia é construído em torno da propriedade e revisão de conteúdo no repositório, e não um requisito para mover a autoridade editorial contínua para um espaço de tradução hospedado.
