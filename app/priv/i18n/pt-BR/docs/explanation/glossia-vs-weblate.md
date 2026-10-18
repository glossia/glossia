%{
  title: "Glossia contra Weblate",
  summary:
    "Escolha a Glossia para trabalho de linguagem orientado a modelos que segue a entrega de repositório e reutiliza sua validação existente.",
  category: "explicação",
  section: "translation",
  order: 23
}
---

**Escolha Glossia quando quer que a automação de idiomas funcione como o resto da sua entrega de software:** instruções controladas por código, tokens de seu próprio modelo, verificações nativas do repositório, e pull requests para revisão.

[Weblate](https://weblate.org/) é um sistema de localização de código aberto com uma interface web de tradução, integração com controle de versão, e opções de auto-hospedagem. Código e Git público não são exclusivos do Glossia. A razão para escolher o Glossia é sua combinação de entrega centrada no repositório, transformações baseadas em modelo, e contexto linguístico reutilizável tanto para humanos quanto para agentes.

## ## Por que escolher o Glossia

| \| Sua prioridade \| | A vantagem do Glossia \| |
|---|---|
| | Mantenha a revisão no fluxo de trabalho do produto | | | Revisar a saída real controlada por código através das alterações do repositório e pull requests. | |
| | Adaptar a um repositório fonte em rápida evolução | | | A detecção de mudanças e publicação em lotes apoiam um ciclo de localização contínuo sem traduzir repetidamente entradas não alteradas. | |
| | Traga seus próprios tokens de modelo | | | Configure modelos suportados com credenciais do provedor com escopo de conta e selecione-os com handles de propriedade do repositório. | |
| | Reutilize validação nativa | | | Execute o comando próprio de validação do repositório contra um candidato em seu caminho real de destino. | |
| | Reutilize contexto além da tradução | | | Voz compartilhada e terminologia podem guiar novo conteúdo e integrações de agentes através de interfaces MCP e REST. |

## ## Mantenha o repositório como a superfície de revisão

O Glossia foi desenhado para uma equipe que já usa Git para decidir o que está pronto para lançamento. Sua configuração de localização mora ao lado do conteúdo, e suas saídas propostas podem ser revisadas através do mesmo processo da mudança do produto.

O Weblate também integra-se com controle de versão. Sua interface web de tradução baseada em navegador pode ser exatamente o que uma comunidade de contribuidores precisa. O foco do Glossia é diferente: preserve a fronteira de revisão do repositório e traga automação de idioma a ela, e não torne outra interface de edição o centro do trabalho da equipe.

## ## Traga seus próprios tokens e torne as escolhas de modelo explícitas

O Glossia usa modelos suportados configurados com seus tokens de API do provedor. Configuração do repositório refere-se a handles de modelo estáveis; segredos permanecem nas configurações de conta. Você pode selecionar modelos configurados diferentes por escopo de conteúdo ou locale-alvo e rotacionar credenciais sem alterar cada repositório.

Isso dá à sua equipe um lugar explícito para escolher os modelos que constroem seu conteúdo. Ele não promete que algum token ou modelo é suportado, ou que a geração remove a necessidade de revisão humana. Veja [Configurar um provedor de modelo](/docs/how-to/configure-a-model-provider).

## Reutilize as verificações que definem uma mudança entregável

As verificações estruturais embutidas do Glossia são apenas parte da fronteira de qualidade. Melalui `L10N.md` >, ele pode executar um script de validação nativo do repositório, parser, compilador, ou verificação de documentação sobre o candidato em seu caminho real de destino.

Isso é útil quando o conteúdo traduzido inclui mais do que strings soltas: formatos específicos de aplicação, componentes Markdown, metadados estruturados, e restrições que o projeto já sabe como verificar. Validação e recuperação permanecem conectadas aos arquivos reais que seu pipeline publicará.

O ambiente de execução ainda precisa das dependências do validador, e validação estrutural não estabelece precisão linguística. Veja [L10N.md](/docs/reference/l10n-md) e [Recuperação de tradução](./translation-recovery).

## Código fonte público é uma linha de base, não toda a comparação

A implementação do Glossia é pública e pode ser inspecionada, modificada e auto-hospedada sob [O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). A licença restringe serviços hospedados concorrentes; não é a mesma que a licença GPL de código aberto do Weblate.

Se licenciamento de código aberto irrestrito e uma interface web de tradução estabelecida forem seus critérios primários, o Weblate merece consideração. Se o objetivo é **suas próprias credenciais de modelo, verificações existentes do repositório, e trabalho de idioma que segue a entrega de software**, o Glossia traz essas escolhas juntas num sistema operacional de idioma.

Esta comparação não afirma que o Weblate falta automação, recursos de validação, ou integrações de provedor, e não promete migração automática ou paridade de funcionalidades. Veja [Documentação do Weblate](https://docs.weblate.org/) para capacidades atuais.
