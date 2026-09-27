%{
  title: "Tentar novamente a configuração do projeto",
  summary: "Recuperar um projeto após a configuração apresentar uma falha.",
  category: "Guia",
  section: "tradução",
  order: 4
}
---
Utilize **Retentar configuração** após corrigir a condição que causou falha na configuração do projeto.

## 1\. Ler a falha

Abra a visão geral do projeto. O cartão de progresso da configuração exibe a falha e a atividade mais recente da configuração.

Causas comuns incluem:

- A conta não possui modelo configurado.
- A chave do provedor está ausente ou não é mais válida.
- O aplicativo GitHub do Glossia não pode acessar o repositório.
- O repositório não pôde ser preparado ou verificado.

## 2\. Corrija o pré-requisito

Para problemas de modelo, abra **Configurações** e **Modelos**.

## 3\. Tentar novamente

Retornar à visão geral do projeto e selecionar **Tentar novamente configuração**.

O cartão retorna para **Pendente**, então **Executando**, e exibe novas atividades conforme o trabalho avança. Retentar está disponível apenas enquanto o projeto estiver em **Falhou** estado, o que impede que duas tentativas de configuração sejam executadas simultaneamente.

## 4\. Revisão da contribuição

Quando o estado muda para **Concluído**, revise o pull request resultante no GitHub. Se ele falhar novamente, use a nova atividade no cartão em vez da tentativa anterior para identificar a próxima ação.