%{
  title: "Glossia vs Crowdin",
  summary:
    "Escolha o Glossia para manter a localização no Git, trazer seus próprios tokens de modelo e validar com as validações do seu repositório.",
  category: "explicação",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Escolha o Glossia quando a necessidade de localização precise mover-se à velocidade da entrega do seu software.** Seu repositório já define como as alterações são revisadas, validadas e enviadas. O Glossia traz o trabalho de idioma para este loop em vez de tornar um ambiente de tradução separado o centro do seu processo.

[Crowdin](https://crowdin.com/) oferece gerenciamento de tradução colaborativo, fluxos de trabalho de revisão, memórias de tradução e integrações de repositório. A vantagem do Glossia para uma equipe de software é a combinação de conteúdo próprio do repositório, código-fonte inspecionável, suas próprias credenciais de modelo e validação que compreende o projeto real.

## Por que escolher Glossia

| Sua prioridade | A vantagem do Glossia |
|---|---|
| Entrega contínua | As execuções de tradução seguem as alterações de origem e retornam atualizações de repositório revisáveis. O conteúdo não precisa de seu próprio processo de lançamento não relacionado. |
| Mantenha o controle da implementação | Aplicação pública, CLI e código de implantação podem ser inspecionados, modificados e auto-hospedados sob os termos da licença. |
| Leve seus próprios tokens | Configure modelos suportados com seus próprios tokens de API do provedor. Arquivos do repositório referenciam identificadores de modelo estáveis, não segredos. |
| Reutilize as verificações nas quais confia | Execute um comando de validação de repositório contra o candidato em seu caminho de destino real antes de aceitá-lo. |
| Mantenha o conteúdo seu | Arquivos de origem, saídas de tradução, configuração e histórico de pull request permanecem em seu repositório. |

## Localização que acompanha os commits

O Glossia funciona a partir de instruções `L10N.md` versionadas e detecta quais conteúdos precisam ser atualizados. Entradas não alteradas não precisam ser traduzidas novamente. Um projeto mantém um único pull request de tradução aberto e publica o progresso em lotes, reduzindo pull requests desnecessários e execuções de CI repetidas à medida que a fonte evolui.

O resultado é um fluxo de trabalho de idioma projetado em torno das mesmas pequenas alterações revisáveis que sua equipe já envia. Contínuo não significa não revisado: os revisores ainda decidem o que é seguro para mesclar.

A Crowdin também suporta integrações e automação do Git. A razão para escolher o Glossia não é que a Crowdin não possa se conectar a um repositório; é que a entrega do repositório é a base do fluxo de trabalho do Glossia, não apenas uma fronteira de integração.

## Seus tokens, suas escolhas de modelo

Você não deve ter que reconstruir a configuração do repositório para rotacionar um token do provedor ou alterar o modelo por trás de um fluxo de trabalho de tradução. O Glossia armazena credenciais nas definições da conta e expõe handles estáveis ao repositório. Diferentes áreas de conteúdo ou locais de destino podem selecionar diferentes modelos configurados.

Isso dá à sua equipe controle sobre as relações de provedor suportadas e as escolhas de modelos que usa. Consulte [Configurar um provedor de modelo](/docs/how-to/configure-a-model-provider).

## Valide a saída como parte do seu produto

Uma tradução pode ser lida bem e ainda quebrar uma construção de documentação, componente, marcador ou analisador de aplicativo. O Glossia permite que você reutilize uma verificação do repositório em vez de parar na avaliação do editor do texto.

Se seu repositório já fornece um script de validação de documentação, cite-o diretamente:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

O validador recebe o candidato em seu caminho de destino real, retorna um status não zero em caso de falha e executa dentro do orçamento de tentativa configurado. Suas dependências devem estar disponíveis no ambiente de validação. Consulte [L10N.md](/docs/reference/l10n-md) para o contrato.

## Código fonte público, sem entregar o repositório

Você pode inspecionar como os planejamentos do Glossia funcionam, gerenciam credenciais, preservam Markdown e validam um resultado. Arquivos de tradução existentes permanecem publicáveis através do pipeline do seu repositório, mesmo que o serviço de idioma esteja indisponível.

O Glossia está disponível como código fonte sob a licença [O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md), que permite auto-hospedagem, mas restringe serviços de hospedagem concorrentes. Não é uma licença de código aberto sem restrições.

A Crowdin ainda pode ser apropriada para um programa centrado na coordenação de contribuidores e um editor de tradução dedicado. Para uma equipe de software cuja prioridade seja **conteúdo de propriedade do Git, validação existente e localização que segue a entrega**, o Glossia é projetado para esse trabalho.

Esta comparação não afirma que a Crowdin falta automação ou toda forma de integração de provedor, nem que o Glossia migra automaticamente suas memórias e histórico. Consulte [documentação da Crowdin](https://support.crowdin.com/) para capacidades atuais.
