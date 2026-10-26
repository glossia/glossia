%{
  title: "Glossia vs Weblate",
  summary:
    "Escolha o Glossia para trabalho de linguagem orientado por modelo que segue a entrega do repositório e reutiliza sua validação existente.",
  category: "explicação",
  markdown_only: true,
  section: "translation",
  order: 23
}
---

**Escolha o Glossia quando quiser que a automação de idiomas funcione como o resto da sua entrega de software:** instruções controladas no repositório, seus próprios tokens de modelo, verificações nativas do repositório e pull requests para revisão.

[Weblate](https://weblate.org/) é um sistema de localização de código aberto com interface web de tradução, integração com controle de versão e opções de hospedagem própria. Código público e integração com Git não são exclusivos do Glossia. O motivo para escolher o Glossia é a combinação de entrega centrada no repositório, transformações impulsionadas pelo modelo e contexto de idioma reutilizável tanto para humanos quanto para agentes.

## Por que escolher o Glossia

| Sua prioridade | Vantagem do Glossia |
|---|---|
| Manter a revisão no fluxo de trabalho do produto | Revise o resultado controlado pelo repositório por meio de alterações do repositório e pull requests. |
| Inspecionar um repositório de fonte em rápida evolução | A detecção de alterações e publicação em lotes sustentam um ciclo de localização contínuo sem traduzir repetidamente entradas inalteradas. |
| Leve seus próprios tokens de modelo | Configure modelos suportados com credenciais de provedor escopadas por conta e selecione-os com handles pertencentes ao repositório. |
| Reutilize a validação nativa | Execute o comando de validação próprio do repositório contra um candidato em seu caminho de destino real. |
| Reutilize o contexto além da tradução | Voz compartilhada e terminologia podem guiar novos conteúdos e integrações de agentes por meio de interfaces MCP e REST. |

## Manter o repositório como superfície de revisão

O Glossia é projetado para uma equipe que já usa Git para decidir o que está pronto para publicação. Sua configuração de localização vive ao lado do conteúdo, e suas saídas propostas podem ser revisadas pelo mesmo processo das alterações do produto.

O Weblate também integra-se ao controle de versão. Sua interface de tradução baseada em navegador pode ser exatamente o que uma comunidade de contribuidores precisa. O foco do Glossia é diferente: preserve a fronteira de revisão do repositório e levar a automação de idioma até ela, em vez de fazer outra interface de edição o centro do trabalho da equipe.

## Leve seus próprios tokens e torne as escolhas de modelos explícitas

O Glossia usa modelos suportados configurados com seus tokens de API do provedor. A configuração do repositório refere-se a handles de modelo estáveis; os segredos permanecem nas configurações da conta. Você pode selecionar diferentes modelos configurados por escopo de conteúdo ou local de destino e rotacionar credenciais sem alterar todo o repositório.

Isso dá à sua equipe um local explícito para escolher os modelos que escrevem seu conteúdo. Não promete que qualquer token ou modelo seja suportado, nem que a geração remova a necessidade de revisão humana. Veja [Configure um provedor de modelo](/docs/how-to/configure-a-model-provider).

## Reutilize as verificações que definem uma mudança de entrega

As verificações estruturais embutidas do Glossia são apenas parte da fronteira de qualidade. Através `L10N.md` , ele pode executar o script de validação nativo do repositório, o parser, o compilador ou a verificação de documentação do candidato em seu caminho de destino real.

Isso é útil quando o conteúdo traduzido inclui mais do que strings simples: formatos específicos da aplicação, componentes Markdown, metadados estruturados e restrições que o projeto já sabe como verificar. A validação e recuperação permanecem conectadas aos arquivos reais que seu pipeline publicará.

O ambiente de execução ainda precisa das dependências do validador, e a validação estrutural não estabelece precisão linguística. Veja [L10N.md](/docs/reference/l10n-md) e [Recuperação de tradução](./translation-recovery).

## O código-fonte público é uma base, não toda a comparação

O núcleo do Glossia utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite uso comercial, modificação, distribuição, auto-hospedagem e serviços hospedados concorrentes conforme seus termos. O código em `ee/` possui uma [licença Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada e seu uso em produção exige um acordo comercial por escrito. Esse modelo open core difere das licenças baseadas em GPL do Weblate.

Se uma licença de código aberto sem restrições e uma interface web de tradução estabelecida forem seus critérios principais, o Weblate merece consideração. Se o objetivo é **seus próprios credenciais de modelo, verificações de repositório existentes e trabalho de idioma que segue a entrega de software**, o Glossia reúne essas escolhas em um SO de idioma.

Esta comparação não afirma que o Weblate carece de automação, recursos de validação ou integrações de provedor, e não promete migração automática ou paridade de recursos. Veja [documentação do Weblate](https://docs.weblate.org/) para as capacidades atuais.
