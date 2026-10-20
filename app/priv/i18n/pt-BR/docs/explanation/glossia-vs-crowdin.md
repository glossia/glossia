%{
  title: "Glossia versus Crowdin",
  summary:
    "Escolha Glossia para manter a localização no Git, trazer seus próprios tokens de modelo e validar com as verificações do seu repositório.",
  category: "explicação",
  section: "translation",
  order: 20
}
---

Escolha **o Glossia** quando a localização precisa avançar com a velocidade da entrega do seu software. Seu repositório já define como as alterações são revisadas, validadas e distribuídas. O Glossia traz o trabalho de idioma para esse ciclo em vez de fazer de um espaço de trabalho de tradução separado o centro do seu processo.

[Crowdin](https://crowdin.com/) oferece gerenciamento colaborativo de tradução, fluxos de revisão, memórias de tradução e integrações de repositório. A vantagem do Glossia para uma equipe de software é a combinação de conteúdo de propriedade do repositório, fonte inspecionável, suas próprias credenciais do modelo e validação que entende o projeto real.

## Por que escolher o Glossia

| Sua prioridade | A vantagem do Glossia |
|---|---|
| Entregue continuamente | As execuções de tradução seguem alterações no código fonte e devolvem atualizações do repositório revisáveis. O conteúdo não precisa de um processo de lançamento próprio e não relacionado. |
| Mantenha controle da implementação | Aplicação pública, CLI e código de implantação podem ser inspecionados, modificados e hospedados localmente pelos termos da licença. |
| Traga seus próprios tokens | Configure modelos suportados com seus próprios tokens de API do provedor. Arquivos do repositório referenciam handles de modelo estáveis, não segredos. |
| Reutilize as verificações que você confia | Execute um comando de validação de repositório contra o candidato em seu caminho real de destino antes de aceitá-lo. |
| Mantenha o conteúdo seu | Arquivos de origem, saídas traduzidas, configuração e histórico de pull request permanecem no seu repositório. |

## Localização que acompanha os commits

O Glossia funciona a partir de instruções versionadas `L10N.md` e detecta qual conteúdo precisa ser atualizado. Entradas não alteradas não precisam ser traduzidas novamente. Um projeto mantem um único pull request de tradução aberto e publica o progresso em lotes, reduzindo pull requests desnecessários e execuções de CI repetidas conforme o código fonte evolui.

O resultado é um fluxo de trabalho linguístico projetado ao redor das mesmas pequenas alterações revisáveis que sua equipe já entrega. Contínuo não significa sem revisão: revisores ainda decidem o que é seguro para mesclar.

O Crowdin também suporta integrações Git e automação. A razão para escolher o Glossia não é que o Crowdin não possa se conectar a um repositório; é que a entrega do repositório é a base do fluxo de trabalho do Glossia, não apenas uma fronteira de integração.

## Seus tokens, suas escolhas de modelo

Você não deve ter que reconstruir a configuração do repositório para rotacionar um token de provedor ou mudar o modelo por trás de um fluxo de trabalho de tradução. O Glossia armazena credenciais nas configurações da conta e expõe handles estáveis ao repositório. Diferentes áreas de conteúdo ou locais de destino podem selecionar modelos configurados diferentes.

Isso dá a sua equipe controle sobre as relações de provedor suportadas e escolhas de modelo que ela usa. Veja [Configurar um provedor de modelo](/docs/how-to/configure-a-model-provider).

## Valide a saída como parte do seu produto

Uma tradução pode ler bem e ainda quebrar uma build de documentação, componente, placeholder ou parser de aplicação. O Glossia permite reutilizar uma verificação do repositório em vez de parar na avaliação do editor do texto.

Se seu repositório já fornece um script de validação de documentação, referencie-o diretamente:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

O validador recebe o candidato em seu caminho real de destino, retorna um status não zero em caso de falha e executa dentro da cota de tentativa configurada. Suas dependências devem estar disponíveis no ambiente de validação. Veja [L10N.md](/docs/reference/l10n-md) para o contrato.

## Fonte pública, sem entregar o repositório

Você pode inspecionar como o Glossia planeja funciona, gerencia credenciais, preserva Markdown e valida um resultado. Arquivos de tradução existentes continuam publicáveis através da pipeline do seu repositório, mesmo que o serviço de idioma esteja indisponível.

O Glossia está disponível como fonte sob a [O'Saasy license](https://github.com/glossia/glossia/blob/main/LICENSE.md), o que permite hospedagem local, mas restringe serviços hospedados concorrentes. Não é uma licença de código aberto sem restrições.

O Crowdin ainda pode ser apropriado para um programa centrado na coordenação de colaboradores e um editor de tradução dedicado. Para uma equipe de software cuja prioridade é **Conteúdo de propriedade do Git, validação existente e localização que segue a entrega**, o Glossia é projetado para esse trabalho.

Esta comparação não afirma que o Crowdin carece de automação ou qualquer forma de integração de provedor, nem que o Glossia migra automaticamente suas memórias e histórico. Consulte [Documentação do Crowdin](https://support.crowdin.com/) para as capacidades atuais.
