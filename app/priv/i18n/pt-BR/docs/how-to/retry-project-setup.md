%{
  title: "Reiniciar configuração do projeto",
  summary: "Recuperar um projeto após falha na configuração.",
  category: "Passo a passo",
  order: 4
}
---
Usar **Reiniciar configuração** após corrigir a condição que causou a falha na configuração do projeto.

## 1\. Ler a falha

Abra a visão geral do projeto. O cartão de progresso da configuração mostra a falha e a última atividade de configuração.

Causas comuns incluem:

- A conta não possui um modelo configurado.
- A chave do provedor está ausente ou não é mais válida.
- O aplicativo GitHub da Glossia não pode acessar o repositório.
- O repositório não pôde ser preparado ou verificado.

## 2\. Corrija o pré-requisito

Para problemas de modelo, abra **Configurações** e **Modelos**.

## 3\. Tentar novamente

Retornar à visão geral do projeto e selecionar **Retentar configuração**.

O cartão retorna a **Pendente**, então **Em andamento**, e mostra novas atividades conforme o trabalho avança. Retentar está disponível apenas enquanto o projeto estiver em **Falhada** estado, o que impede que duas tentativas de configuração sejam executadas simultaneamente.

## 4\. Revisar conclusão

Quando o estado mudar para **Concluído**, revise o pull request resultante no GitHub. Se falhar novamente, use a nova atividade no cartão em vez da tentativa anterior para identificar a próxima ação.