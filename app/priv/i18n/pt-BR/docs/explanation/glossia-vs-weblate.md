%{
  title: "Glossia versus Weblate",
  summary:
    "Escolha Glossia para trabalho com linguagens baseado em modelo que segue a entrega do repositório e reutiliza sua validação existente.",
  category: "explicação",
  markdown_only: true,
  section: "translation",
  order: 23
}
---

**Escolha o Glossia quando quiser que a automação de idioma funcione como o restante de sua entrega de software:** instruções controladas por repositório, seus próprios tokens de modelo, checks nativos do repositório e pull requests para revisão.

[Weblate](https://weblate.org/) é um sistema de código aberto de localização com interface web de tradução, integração com controle de versão e opções de auto-hospedagem. Código público e integração Git não são exclusivos do Glossia. O motivo para escolher o Glossia é a combinação de entrega centrada no repositório, transformações dirigidas por modelo e contexto de idioma reutilizável tanto para humanos quanto para agentes.

## Por que escolher o Glossia

| Sua prioridade | Vantagem do Glossia |
|---|---|
| Mantenha a revisão no fluxo de trabalho do produto | Revise a saída real controlada por repositório por meio de alterações de repositório e pull requests. |
| Combine com um repositório de fonte em rápido movimento | A detecção de alterações e a publicação em lote suportam um loop de localização contínuo sem traduzir repetidamente entradas inalteradas. |
| Traga seus próprios tokens de modelo | Configure modelos suportados com credenciais do provedor com escopo de conta e selecione-os com identificadores de propriedade do repositório. |
| Reutilize a validação nativa | Execute o comando de validação próprio do repositório contra um candidato em seu caminho real de destino. |
| Reutilize o contexto além da tradução | Voz e terminologia compartilhadas podem guiar novo conteúdo e integrações de agentes por meio de interfaces MCP e REST. |

## Mantenha o repositório como a superfície de revisão

O Glossia é projetado para uma equipe que já usa Git para decidir o que está pronto para envio. Sua configuração de localização fica ao lado do conteúdo, e suas saídas propostas podem ser revisadas pelo mesmo processo da mudança do produto.

O Weblate também se integra com controle de versão. Sua interface de tradução baseada em navegador pode ser exatamente o que uma comunidade de contribuidores precisa. O foco do Glossia é diferente: preserve a fronteira de revisão do repositório e leve a automação de idioma para ela, em vez de tornar outra interface de edição o centro do trabalho da equipe.

## Traga seus próprios tokens e torne as escolhas de modelo explícitas

O Glossia usa modelos suportados configurados com seus tokens de API do provedor. A configuração do repositório refere-se a identificadores de modelo estáveis; segredos permanecem nas configurações de conta. Você pode selecionar modelos configurados diferentes por escopo de conteúdo ou idioma alvo e rotacionar credenciais sem alterar todos os repositórios.

Isso dá à sua equipe um lugar explícito para escolher os modelos que produzem seu conteúdo. Não garante que qualquer token ou modelo seja suportado, ou que a geração elimine a necessidade de revisão humana. Veja [Configurar um provedor de modelo](/docs/how-to/configure-a-model-provider).

## Reutilize as verificações que definem uma mudança entregável

As verificações estruturais embutidas do Glossia são apenas parte da fronteira de qualidade. Através `L10N.md`, ele pode executar um script de validação nativo do repositório, um parser, um compilador ou uma verificação de documentação sobre o candidato em seu caminho real de destino.

Isso é útil quando o conteúdo traduzido inclui mais do que strings simples: formatos específicos da aplicação, componentes Markdown, metadados estruturados e restrições que o projeto já sabe como verificar. Validação e recuperação permanecem conectadas aos arquivos reais que seu pipeline publicará.

O ambiente de execução ainda precisa das dependências do validador, e a validação estrutural não estabelece precisão linguística. Veja [L10N.md](/docs/reference/l10n-md) e [Recuperação de tradução](./translation-recovery).

## Código fonte público é uma base, não toda a comparação

A implementação do Glossia é pública e pode ser inspecionada, modificada e auto-hospedada sob [O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). A licença restringe serviços hospedados concorrentes; não é a mesma coisa que a licença de código aberto baseada em GPL do Weblate.

Se licenciamento de código aberto sem restrições e uma interface de tradução web estabelecida forem seus critérios principais, o Weblate merece consideração. Se o objetivo for **seus próprios tokens de modelo, verificações de repositório existentes e trabalho de idioma que segue a entrega de software**, o Glossia reúne essas escolhas em um Sistema Operacional de Idioma.

Esta comparação não afirma que o Weblate falta automação, recursos de validação ou integrações de provedor, e não promete migração automática ou paridade de recursos. Veja [Documentação do Weblate](https://docs.weblate.org/) para capacidades atuais.
