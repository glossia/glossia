%{
  title: "Glossia vs Weblate",
  summary:
    "Escolha Glossia para trabalho linguístico orientado a modelos que segue a entrega de repositório e reutiliza sua validação existente.",
  category: "Explicação",
  markdown_only: true,
  section: "translation",
  order: 23
}
---

**Escolha Glossia quando quiser que a automação linguística funcione como o restante da entrega de software:** instruções controladas pelo repositório, seus próprios tokens de modelo, validações nativas do repositório e requests de pull para revisão.

O [Weblate](https://weblate.org/) é um sistema de localização de código aberto com interface de tradução web, integração com controle de versão e opções de auto-hospedagem. Código público e integração Git não são exclusivos do Glossia. O motivo para escolher o Glossia é a combinação de entrega centrada no repositório, transformações orientadas por modelo e contexto de idioma reutilizável tanto para humanos quanto para agentes.

## Por que escolher o Glossia

| Sua prioridade | A vantagem do Glossia |
|---|---|
| Mantenha a revisão no fluxo de trabalho do produto | Revise a saída real controlada por versão através das alterações no repositório e pull requests. |
| Acompanhe um repositório fonte em rápida mudança | A detecção de alterações e a publicação em lotes suportam um ciclo de localização contínuo sem traduzir repetidamente entradas não alteradas. |
| Traga seus próprios tokens de modelo | Configure modelos suportados com credenciais de provedor escopadas à conta e selecione-os com identificadores pertencentes ao repositório. |
| Reutilize a validação nativa | Execute o comando de validação próprio do repositório contra um candidato em seu caminho de destino real. |
| Reutilize o contexto além da tradução | Voz compartilhada e terminologia podem guiar novos conteúdos e integrações de agentes através das interfaces MCP e REST. |

## Mantenha o repositório como a superfície de revisão

O Glossia é projetado para uma equipe que já usa Git para decidir o que está pronto para envio. Sua configuração de localização vive ao lado do conteúdo, e suas saídas propostas podem ser revisadas através do mesmo processo da mudança do produto.

O Weblate também integra com o controle de versão. Sua interface de tradução baseada em navegador pode ser exatamente o que uma comunidade de colaboradores precisa. O foco do Glossia é diferente: preserve o limite de revisão do repositório e traga automação de idioma para ele, em vez de fazer outra interface de edição o centro do trabalho da equipe.

## Traga seus próprios tokens e torne as escolhas de modelo explícitas

O Glossia usa modelos suportados configurados com seus tokens de API do provedor. A configuração do repositório se refere a identificadores de modelo estáveis; segredos permanecem nas configurações da conta. Você pode selecionar diferentes modelos configurados pelo escopo de conteúdo ou idioma-alvo e rodar credenciais sem alterar cada repositório.

Isso dá à sua equipe um lugar explícito para escolher os modelos que escrevem seu conteúdo. Ela não promete que qualquer token ou modelo é suportado, ou que a geração remove a necessidade de revisão humana. Consulte [Configurar um provedor de modelo](/docs/how-to/configure-a-model-provider).

## Reutilize as verificações que definem uma mudança de entrega

As verificações estruturais integradas do Glossia são apenas parte do limite de qualidade. Através `L10N.md`, pode executar um script de validação nativo do repositório, parser, compilador ou verificação de documentação no candidato em seu caminho de destino real.

Isso é útil quando o conteúdo traduzido inclui mais do que strings simples: formatos específicos da aplicação, componentes Markdown, metadados estruturados e restrições que o projeto já sabe como verificar. Validação e recuperação permanecem conectados aos arquivos reais que seu pipeline irá publicar.

O ambiente de execução ainda precisa das dependências do validador, e a validação estrutural não estabelece precisão linguística. Veja [L10N.md](/docs/reference/l10n-md) e [Recuperação de tradução](./translation-recovery).

## Código-fonte público é um ponto de partida, não toda a comparação

O núcleo do Glossia utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite uso comercial, modificação, distribuição, auto-hospedagem e serviços hospedados concorrentes conforme seus termos. O código em `ee/` possui uma [licença Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada e seu uso em produção exige um acordo comercial por escrito. Esse modelo open core difere das licenças baseadas em GPL do Weblate.

Se licenciamento open-source sem restrições e uma interface de tradução web estabelecida forem seus critérios primários, o Weblate merece consideração. Se o objetivo é **suas próprias credenciais de modelo, verificações de repositório existentes e trabalho de idioma que segue a entrega de software**, o Glossia reúne essas escolhas em um sistema operacional de idioma.

Esta comparação não afirma que o Weblate falta automação, recursos de validade ou integrações de provedor, e não promete migração automática ou paridade de recursos. Veja [a documentação do Weblate](https://docs.weblate.org/) para as capacidades atuais.
