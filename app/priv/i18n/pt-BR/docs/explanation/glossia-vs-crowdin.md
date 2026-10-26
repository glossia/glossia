%{
  title: "Glossia contra Crowdin",
  summary:
    "Escolha o Glossia para manter a localização no Git, trazer seus próprios tokens de modelo e validar com as verificações do seu repositório.",
  category: "explicação",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Escolha o Glossia quando a localização precisa avançar com a mesma velocidade da entrega do seu software.** Seu repositório já define como as mudanças são revistas, validadas e enviadas. O Glossia traz o trabalho de linguagem para dentro desse loop em vez de tornar uma área de trabalho de tradução separada o centro do seu processo.

[Crowdin](https://crowdin.com/) oferece gestão colaborativa de tradução, fluxos de revisão, memórias de tradução e integrações de repositório. A vantagem do Glossia para uma equipe de software é a combinação de conteúdo de propriedade do repositório, código-fonte inspecionável, suas próprias credenciais de modelo e validação que compreende o projeto real.

## Por que escolher o Glossia

| Sua prioridade | Vantagem do Glossia |
|---|---|
| Entregue continuamente | As execuções de tradução seguem as alterações do recurso e retornam atualizações de repositório revisáveis. O conteúdo não precisa de seu próprio processo de lançamento não relacionado. |
| Mantenha o controle da implementação | Aplicativo público, CLI e código de implantação podem ser inspecionados, modificados e auto-hospedados de acordo com os termos da licença. |
| Traga seus próprios tokens | Configure modelos suportados com seus próprios tokens de API de provedor. Arquivos de repositório referenciam handles de modelo estáveis, não segredos. |
| Reutilize as verificações que você confia | Execute um comando de validação de repositório contra o candidato em seu caminho de destino real antes de aceitá-lo. |
| Mantenha o conteúdo seu | Arquivos de origem, saídas traduzidas, configuração e histórico de solicitações pull permanecem no seu repositório. |

## Localização que acompanha os commits

O Glossia funciona a partir de instruções `L10N.md` versionadas e detecta qual conteúdo precisa de atualização. Entradas não alteradas não precisam ser traduzidas novamente. Um projeto mantém uma única solicitação pull de tradução aberta e publica o progresso em lotes, reduzindo solicitações pull desnecessárias e execuções repetidas de CI à medida que o código evolui.

O resultado é um fluxo de linguagem desenhado em torno das mesmas pequenas alterações revisáveis que sua equipe já entrega. Contínuo não significa sem revisão: revisores ainda decidem o que é seguro de mesclar.

O Crowdin também suporta integrações de Git e automação. A razão para escolher o Glossia não é que o Crowdin não possa se conectar a um repositório; é que a entrega de repositório é a base do fluxo de trabalho do Glossia, não apenas uma fronteira de integração.

## Seus tokens, suas escolhas de modelo

Você não deve ter que reconstruir a configuração do repositório para rotacionar um token de provedor ou alterar o modelo por trás de um fluxo de trabalho de tradução. O Glossia armazena credenciais em configurações de conta e expõe handles estáveis para o repositório. Diferentes áreas de conteúdo ou locais-alvo podem selecionar diferentes modelos configurados.

Isso dá controle à sua equipe sobre as relações de provedor suportadas e as escolhas de modelo que ela usa. Veja [Configure um provedor de modelo](/docs/how-to/configure-a-model-provider).

## Valide a saída como parte do seu produto

Uma tradução pode ler bem e ainda quebrar uma compilação de documentação, um componente, um substituto ou um analisador de aplicativo. O Glossia permite reutilizar uma verificação do repositório em vez de parar na avaliação do editor do texto.

Se seu repositório já fornece um script de validação de documentação, referencie-o diretamente:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

O validador recebe o candidato em seu caminho de destino real, retorna um status diferente de zero em caso de falha e executa dentro do limite de tentativas configurado. Suas dependências devem estar disponíveis no ambiente de validação. Consulte [L10N.md](/docs/reference/l10n-md) para o contrato.

## Código-fonte público, sem entregar o repositório

Você pode inspecionar como os planos do Glossia funcionam, lidam com credenciais, preservam Markdown e validam um resultado. Arquivos traduzidos existentes permanecem publicáveis através da pipeline do seu repositório mesmo que o serviço de linguagem não esteja disponível.

O Glossia está disponível como código-fonte sob a [licença O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md), que permite auto-hospedamento, mas restringe serviços hospedados concorrentes. Não é uma licença de código-fonte sem restrições.

O Crowdin ainda pode ser adequado para um programa centrado em coordenação de contribuidores e um editor de tradução dedicado. Para uma equipe de software cuja prioridade é **conteúdo de propriedade Git, validação existente e localização que segue a entrega**, o Glossia é feito para esse trabalho.

Esta comparação não afirma que o Crowdin falta automação ou todos os tipos de integração de provedor, nem que o Glossia migra automaticamente suas memórias e histórico. Consulte [documentação do Crowdin](https://support.crowdin.com/) para capacidades atuais.
