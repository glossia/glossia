%{
  title: "Tentar novamente a configuração do projeto",
  summary: "Recuperar um projeto após a configuração relatar uma falha.",
  category: "tutorial",
  order: 4
}
---
Usar **Tentar novamente a configuração** após corrigir a condição que causou a falha na configuração do projeto.

## 1\. Ler a falha

Abra a visão geral do projeto. O cartão de progresso da configuração mostra a falha e a última atividade da configuração.

As causas comuns incluem:

- A conta não possui nenhum modelo configurado.
- A chave do provedor está ausente ou não é mais válida.
- O aplicativo Glossia GitHub não consegue acessar o repositório.
- O repositório não pôde ser preparado ou verificado.

## 2\. Corrija o pré-requisito

Para problemas de modelo, abra **Configurações** e **Modelos**. Para problemas de acesso ao repositório, atualize a instalação do aplicativo Glossia GitHub no GitHub e conceda acesso ao repositório.

## 3\. Tentar novamente

Volte à visão geral do projeto e selecione **Tentar novamente a configuração**.

O cartão retorna a **Pendente**, depois **Em execução**, e mostra novas atividades conforme o trabalho avança. A opção de tentar novamente está disponível apenas enquanto o projeto está no **Falha** , estado, que impede duas tentativas de configuração de rodarem simultaneamente.

## 4\. Revisar conclusão

Quando o estado mudar para **Concluído**, revise o pull request resultante no GitHub. Se falhar novamente, use a nova atividade no cartão em vez da tentativa anterior para identificar a próxima ação.