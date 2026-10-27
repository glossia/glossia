%{
  title: "Glossia x Weblate",
  summary:
    "Escolha o Glossia para trabalho com linguagens orientado a modelos que segue a entrega do repositório e reutiliza sua validação existente.",
  category: "Explicação",
  markdown_only: true,
  section: "translation",
  order: 23
}
---

**Escolha o Glossia quando quiser que a automação de idiomas funcione como o restante da sua entrega de software:** instruções controladas por repositório, seus próprios tokens de modelo, verificações nativas do repositório e pull requests para revisão.

[Weblate](https://weblate.org/) é um sistema de localização open-source com interface web de tradução, integração com controle de versão e opções de auto-hospedagem. Código fonte aberto e integração Git não são exclusivos do Glossia. O motivo para escolher o Glossia é a combinação de entrega centrada no repositório, transformações orientadas por modelo e contexto de idioma reutilizável tanto para humanos quanto para agentes.

## Por que escolher o Glossia

| Sua prioridade | Vantagem do Glossia |
|---|---|
| Mantenha a revisão no fluxo de trabalho do produto | Revise a saída real controlada por versão por meio de alterações no repositório e pull requests. |
| Ajuste-se a um repositório de origem em rápida evolução | Detecção de alterações e publicação em lote suportam um ciclo de localização contínuo sem traduzir repetidamente entradas inalteradas. |
| Leve seus próprios tokens de modelo | Configure modelos suportados com credenciais do provedor em escopo de conta e selecione-os com manipuladores de propriedade do repositório. |
| Reutilize a validação nativa | Execute o comando de validação próprio do repositório contra um candidato em seu caminho de destino real. |
| Reutilize o contexto além da tradução | Voz e terminologia compartilhadas podem orientar novos conteúdos e integrações de agentes por meio das interfaces MCP e REST. |

## Mantenha o repositório como a superfície de revisão

O Glossia é projetado para uma equipe que já usa o Git para decidir o que está pronto para lançamento. Sua configuração de localização vive ao lado do conteúdo, e suas saídas propostas podem ser revisadas pelo mesmo processo da alteração do produto.

O Weblate também se integra com controle de versão. Sua interface de tradução baseada em navegador pode ser exatamente o que a comunidade de contribuidores precisa. O foco do Glossia é diferente: preserve o limite de revisão do repositório e traga a automação de idioma até ele, em vez de tornar outra interface de edição o centro do trabalho da equipe.

## Leve seus próprios tokens e torne as escolhas de modelo explícitas

O Glossia usa modelos suportados configurados com tokens de API de provedor. A configuração do repositório se refere a manipuladores de modelo estáveis; segredos permanecem nas configurações de conta. Você pode selecionar diferentes modelos configurados por escopo de conteúdo ou destino e girar credenciais sem alterar todos os repositórios.

Isso dá à sua equipe um lugar explícito para escolher os modelos que escrevem seu conteúdo. Não garante que nenhum token ou modelo é suportado, ou que a geração remove a necessidade de revisão humana. Veja [Configurar um provedor de modelo](/docs/how-to/configure-a-model-provider).

## Reutilize as verificações que definem uma alteração de entrega

As verificações estruturais embutidas no Glossia são apenas parte do limite de qualidade. Através `L10N.md`, é possível executar um script de validação nativo do repositório, um parser, um compilador ou uma verificação de documentação sobre o candidato em seu caminho de destino real.

Isso é útil quando o conteúdo traduzido inclui mais do que strings simples: formatos específicos da aplicação, componentes Markdown, metadados estruturados e restrições que o projeto já sabe como verificar. A validação e a recuperação permanecem conectadas aos arquivos reais que seu pipeline publicará.

O ambiente de execução ainda precisa das dependências do validador, e a validação estrutural não estabelece precisão linguística. Veja [L10N.md](/docs/reference/l10n-md) e [Recuperação de tradução](./translation-recovery).

## Fonte pública é uma base, não a comparação inteira

O núcleo do Glossia é público e pode ser inspecionado, modificado, distribuído e auto-hospedado sob [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), o que permite serviços hospedados concorrentes. Código empresarial sob `ee/` tem uma [licença](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada exigindo um acordo comercial escrito para uso em produção. Este modelo open-core difere da licenciamento baseada em GPL do Weblate.

Se a licenciamento baseada em GPL e uma interface web de tradução estabelecida são seus critérios principais, o Weblate merece consideração. Se o objetivo for **suas próprias credenciais de modelo, verificações de repositório existentes e trabalho em idioma que segue a entrega de software**, o Glossia reúne essas escolhas em um Sistema Operacional de Idioma.

Esta comparação não afirma que o Weblate carece de automação, recursos de validação ou integrações de provedor, e não promete migração automática ou paridade de recursos. Veja [Documentação do Weblate](https://docs.weblate.org/) para capacidades atuais.
