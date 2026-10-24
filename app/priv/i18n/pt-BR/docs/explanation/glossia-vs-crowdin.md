%{
  title: "Glossia vs Crowdin",
  summary:
    "Escolha o Glossia para manter a localização no Git, trazer seus próprios tokens de modelo e validar com as verificações do seu repositório.",
  category: "explicação",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Escolha Glossia quando a localização precisa avançar à velocidade da entrega do seu software.** Seu repositório já define como alterações são revisadas, validadas e distribuídas. O Glossia traz o trabalho de linguagem para esse ciclo em vez de criar um espaço de trabalho de tradução separado no centro do seu processo.

[Crowdin](https://crowdin.com/) oferece gerenciamento colaborativo de tradução, workflows de revisão, memórias de tradução e integrações de repositório. A vantagem de Glossia para uma equipe de software é a combinação de conteúdo do repositório, código-fonte inspecionável, credenciais do seu próprio modelo e validação que compreende o projeto real.

## Por que escolher Glossia

| Sua prioridade | A vantagem da Glossia |
|---|---|
| Entregar continuamente | As execuções de tradução seguem alterações no código-fonte e retornam atualizações de repositório revisáveis. O conteúdo não precisa de seu próprio processo de lançamento desconexo. |
| Mantenha o controle da implementação | Aplicação pública, CLI e código de implantação podem ser inspecionados, modificados e auto-hospedados sob os termos de licença. |
| Leve seus próprios tokens | Configure modelos suportados com seus próprios tokens de API do provedor. Arquivos do repositório referenciam manipuladores de modelo estáveis, não segredos. |
| Reutilize as verificações em que confie | Execute um comando de validação de repositório contra o candidato em seu caminho de destino real antes de aceitá-lo. |
| Mantenha o conteúdo seu | Arquivos fonte, saídas traduzidas, configurações e histórico de solicitações pull permanecem em seu repositório. |

## Localização que acompanha commits

O Glossia funciona a partir de instruções `L10N.md` versionadas e detecta qual conteúdo precisa de atualização. Entradas não alteradas não precisam ser traduzidas novamente. Um projeto mantém um único pull request de tradução aberto e publica o progresso em lotes, reduzindo pull requests desnecessários e execuções repetidas de CI conforme o código-fonte evolui.

O resultado é um fluxo de trabalho de idioma projetado ao redor das mesmas pequenas alterações revisáveis que sua equipe já envia. Contínuo não significa irrevisado: revisores ainda decidem o que é seguro mesclar.

O Crowdin também suporta integrações e automação Git. A razão para escolher o Glossia não é que o Crowdin não consiga se conectar a um repositório; é que a entrega do repositório é a base do fluxo de trabalho do Glossia, não apenas um limite de integração.

## Seus tokens, suas escolhas de modelo

Você não deveria ter que reconstruir a configuração do repositório para girar um token do provedor ou alterar o modelo atrás de um fluxo de tradução. O Glossia armazena credenciais nas configurações de conta e expõe manipuladores sólidos para o repositório. Diferentes áreas de conteúdo ou locais-alvo podem selecionar modelos configurados diferentes.

Isso dá à sua equipe controle sobre as relações de provedor suportadas e escolhas de modelo que usa. Consulte [Configurar um provedor de modelo](/docs/how-to/configure-a-model-provider).

## Valide a saída como parte do seu produto

Uma tradução pode ler bem e ainda quebrar uma compilação de documentação, componente, placeholder ou analisador de aplicação. O Glossia permite que você reutilize uma verificação de repositório em vez de parar na avaliação de um editor de texto.

Se seu repositório já fornece um script de validação de documentação, referência-o diretamente:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

O validador recebe o candidato em seu caminho alvo real, retorna um status não zero ao falhar e executa dentro do orçamento de tentativa configurado. Suas dependências devem estar disponíveis no ambiente de validação. Consulte [L10N.md](/docs/reference/l10n-md) para o contrato.

## Código fonte público, sem ceder o repositório

Você pode inspecionar como os planos do Glossia funcionam, tratam credenciais, preservam Markdown e validam um resultado. Arquivos traduzidos existentes permanecem publicáveis através do pipeline do seu repositório mesmo que o serviço de idioma esteja indisponível.

O Glossia segue um modelo open core. O núcleo utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite uso comercial, modificação, distribuição, auto-hospedagem e serviços hospedados concorrentes conforme seus termos. O código em `ee/` é visível, mas não é código aberto. Ele possui uma [licença Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada e seu uso em produção exige um acordo comercial por escrito.

O Crowdin ainda pode ser adequado para um programa centrado na coordenação de contribuidores e um editor de tradução dedicado. Para uma equipe de software cuja prioridade é **conteúdo do repositório Git, validação existente e localização que segue a entrega**, a Glossia é projetada para esse trabalho.

Essa comparação não afirma que o Crowdin falta automação ou cada forma de integração de provedor, ou que o Glossia migra automaticamente suas memórias e histórico. Consulte [documentação do Crowdin](https://support.crowdin.com/) para capacidades atuais.
