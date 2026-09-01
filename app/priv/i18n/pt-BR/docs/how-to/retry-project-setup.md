%{
  title: "Retentar configuração do projeto",
  summary: "Recuperar um projeto após falha na configuração.",
  category: "Como fazer",
  order: 4
}
---
Use **Retentar configuração** após corrigir a condição que provocou a falha na configuração do projeto.

## 1\. Ler a falha

Abra a visão geral do projeto. O cartão de progresso da configuração exibe a falha e a última atividade de configuração.

Causas comuns incluem:

- A conta não possui nenhum modelo configurado.
- A chave do provedor está ausente ou já não é mais válida.
- O aplicativo Glossia GitHub não pode acessar o repositório.
- O repositório não pôde ser preparado ou verificado.

## 2\. Corrigir o pré-requisito

Para problemas de modelo, abra **Configurações** e **Modelos**. Para problemas de acesso ao repositório, atualize a instalação do aplicativo Glossia GitHub no GitHub e conceda a ele acesso ao repositório.

## 3\. Retentar

Volte para a visão geral do projeto e selecione **Retentar configuração**.

O cartão volta para **Pendente**, depois **Em execução** e exibe novas atividades conforme o trabalho prossegue. Retentar está disponível apenas enquanto o projeto está no estado **Falhou**, o que impede que duas tentativas de configuração sejam executadas simultaneamente.

## 4\. Revisar a conclusão

Quando o estado muda para **Concluído**, revise o pull request resultante no GitHub. Se ele falhar novamente, use a nova atividade no cartão em vez da tentativa anterior para identificar a próxima ação.