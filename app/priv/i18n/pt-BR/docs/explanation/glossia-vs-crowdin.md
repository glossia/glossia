%{
  title: "Glossia vs Crowdin",
  summary:
    "Escolha Glossia para manter a localização no Git, trazer seus próprios tokens de modelo e validar com as verificações do seu repositório.",
  category: "explicação",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Escolha o Glossia quando a localização precisar seguir o ritmo da entrega do seu software.** Seu repositório já define como as alterações são revisadas, validadas e publicadas. O Glossia integra o trabalho de localização nesse ciclo, em vez de tornar um workspace de tradução separado o centro do seu processo.

[Crowdin](https://crowdin.com/) fornece gerenciamento colaborativo de tradução, fluxos de trabalho de revisão, memórias de tradução e integrações de repositório. A vantagem do Glossia para uma equipe de software é a combinação de conteúdo de propriedade do repositório, fonte inspecionável, suas próprias credenciais de modelo e validação que compreende o projeto real.

## Por que escolher o Glossia

| Sua prioridade | A vantagem do Glossia |
|---|---|
| Entregue continuamente | As execuções de tradução seguem as alterações da fonte e retornam atualizações do repositório revisáveis. O conteúdo não precisa de seu próprio processo de lançamento não relacionado. |
| Mantenha o controle da implementação | Aplicação pública, CLI e código de implantação podem ser inspecionados, modificados e hospedados localmente sob os termos da licença. |
| Traga seus próprios tokens | Configure modelos suportados com seus próprios tokens de API de provedor. Arquivos do repositório referenciam identificadores de modelo estáveis, não segredos. |
| Reutilize as verificações das quais você confia | Execute um comando de validação do repositório contra o candidato em seu caminho de destino real antes de aceitá-lo. |
| Mantenha o conteúdo seu | Arquivos de origem, saídas traduzidas, configuração e histórico de pull requests permanecem em seu repositório. |

## Localização que acompanha os commits

O Glossia funciona a partir de instruções versionadas `L10N.md` e detecta qual conteúdo precisa de atualização. Entradas não alteradas não precisam ser traduzidas novamente. Um projeto mantém um único pull request de tradução aberto e publica o progresso em lotes, reduzindo pull requests desnecessários e execuções repetidas de CI conforme a fonte evolui.

O resultado é um fluxo de trabalho de idioma projetado em torno das mesmas pequenas alterações revisáveis que sua equipe já entrega. Contínuo não significa não revisado: revisores ainda decidem o que é seguro mesclar.

O Crowdin também suporta integrações do Git e automação. O motivo para escolher o Glossia não é que o Crowdin não possa se conectar a um repositório; é que a entrega do repositório é a base do fluxo de trabalho do Glossia, não apenas uma fronteira de integração.

## Seus tokens, suas escolhas de modelo

Você não deve ter que recriar a configuração do repositório para rotacionar um token de provedor ou alterar o modelo por trás de um fluxo de trabalho de tradução. O Glossia armazena credenciais nas definições de conta e expõe identificadores estáveis para o repositório. Diferentes áreas de conteúdo ou localizações de destino podem selecionar modelos configurados diferentes.

Isso dá à sua equipe controle sobre as relações de provedor suportadas e as escolhas de modelo que usa. Veja [Configure um provedor de modelo](/docs/how-to/configure-a-model-provider).

## Valide a saída como parte do seu produto

Uma tradução pode ler bem e ainda quebrar a compilação de documentação, um componente, placeholder ou parser de aplicativo. O Glossia permite que você reutilize uma verificação do repositório em vez de parar na avaliação do editor sobre o texto.

Se seu repositório já fornece um script de validação de documentação, referencie-o diretamente:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

O validador recebe o candidato em seu caminho de destino real, retorna um status não zero em caso de falha e executa dentro do orçamento de retry configurado. Suas dependências devem estar disponíveis no ambiente de validação. Veja [L10N.md](/docs/reference/l10n-md) para o contrato.

## Código-fonte público, sem ceder o repositório

Você pode inspecionar como os planos do Glossia funcionam, gerencia credenciais, preserva Markdown e valida um resultado. Arquivos traduzidos existentes permanecem publicáveis através da pipeline do seu repositório mesmo se o serviço de idioma estiver indisponível.

O Glossia é open core: [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE) cobre o núcleo e permite auto-hospedagem e serviços concorrentes hospedados. Código empresarial disponível em fonte sob `ee/` possui uma [licença](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada exigindo um acordo comercial escrito para uso em produção.

O Crowdin ainda pode ser apropriado para um programa centrado na colaboração de contribuidores e um editor de tradução dedicado. Para uma equipe de software cuja prioridade é **conteúdo de propriedade do Git, validação existente e localização que segue a entrega**, o Glossia é projetado para esse trabalho.

Esta comparação não afirma que o Crowdin carece de automação ou de qualquer forma de integração de provedor, nem que o Glossia automaticamente migre suas memórias e histórico. Consulte [documentação do Crowdin](https://support.crowdin.com/) para as capacidades atuais.
