%{
  title: "Retentar a configuração do projeto",
  summary: "Recuperar um projeto após a configuração relatar uma falha.",
  category: "Como fazer",
  order: 4
}
---
Utilize **Tentar novamente a configuração** após corrigir a condição que causou a falha na configuração do projeto.

## 1\. Ler a falha

Abra a visão geral do projeto. O cartão de progresso da configuração mostra a falha e a última atividade da configuração.

As causas comuns incluem:

- A conta não tem um modelo configurado.
- A chave do provedor está ausente ou não é mais válida.
- O aplicativo GitHub do Glossia não consegue acessar o repositório.
- Não foi possível preparar ou verificar o repositório.

## 2\. Corrija o pré-requisito

Para problemas de modelo, abra **Configurações** e **Modelos**. Para problemas de acesso ao repositório, atualize a instalação do aplicativo GitHub do Glossia no GitHub e conceda acesso ao repositório.

## 3\. Retentar

Voltar para a visão geral do projeto e selecionar **Retentar configuração**.

O cartão retorna para **Pendente**, depois **Em andamento**e mostra novas atividades conforme o trabalho prossegue. Retentar está disponível apenas enquanto o projeto está em **Falho** , estado, o que impede duas tentativas de configuração de ocorrerem simultaneamente.

## 4\. Revisar conclusão

Quando o estado muda para **Concluído**, revise o pull request resultante no GitHub. Se falhar novamente, use a nova atividade no cartão em vez da tentativa anterior para identificar a próxima ação.