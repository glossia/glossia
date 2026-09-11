%{
  title: "Tentar novamente a configuração do projeto",
  summary: "Recuperar um projeto após a configuração relatar uma falha.",
  category: "tutorial",
  order: 4
}
---
Utilize **Reiniciar configuração** após corrigir a condição que causou a falha na configuração do projeto.

## 1\. Leia a falha

Abra a visão geral do projeto. O cartão de progresso da configuração mostra a falha e a última atividade da configuração.

As causas comuns incluem:

- A conta não possui um modelo configurado.
- A chave do provedor está faltando ou não é mais válida.
- O aplicativo GitHub da Glossia não pode acessar o repositório.
- O repositório não pôde ser preparado ou verificado.

## 2\. Corrija o pré-requisito

Para problemas de modelo, abra **Configurações** e **Modelos**. Para problemas de acesso ao repositório, atualize a instalação do aplicativo GitHub da Glossia no GitHub e conceda acesso ao repositório.

## 3\. Tentar novamente

Volte ao resumo do projeto e selecione **Configurar novamente**.

O cartão retorna ao **Pendente**, em seguida **Em andamento**", e mostra nova atividade conforme o trabalho prossegue. Tentar novamente está disponível apenas enquanto o projeto estiver em **Falha** estado, o que impede que duas tentativas de configuração sejam executadas ao mesmo tempo.

## 4\. Revisar conclusão

Quando o estado muda para **Concluído**", revise o pull request resultante no GitHub. Se falhar novamente, use a nova atividade no cartão em vez da tentativa anterior para identificar a próxima ação.