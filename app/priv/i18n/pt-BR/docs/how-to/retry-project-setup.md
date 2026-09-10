%{
  title: "Tentar novamente a configuração do projeto",
  summary: "Recuperar o projeto após falha na configuração.",
  category: "Tutorial",
  order: 4
}
---
Usar **Reiniciar configuração** após corrigir a condição que causou a falha na configuração do projeto.

## 1\. Ler a falha

Abra a visão geral do projeto. O cartão de progresso da configuração mostra a falha e a atividade mais recente de configuração.

As causas comuns incluem:

- A conta não possui nenhum modelo configurado.
- A chave do provedor está ausente ou não é mais válida.
- O aplicativo GitHub do Glossia não pode acessar o repositório.
- O repositório não pôde ser preparado ou verificado.

## 2\. Corrija o pré-requisito

Para problemas de modelo, abra **Configurações** e **Modelos**. Para problemas de acesso ao repositório, atualize a instalação do aplicativo GitHub do Glossia no GitHub e conceda-lhe acesso ao repositório.

## 3\. Tentar novamente

Voltar à visão geral do projeto e selecionar **Reiniciar configuração**.

O cartão retorna ao **Pendente**, em seguida **Em andamento**, e exibe novas atividades conforme o trabalho avança. Uma nova tentativa está disponível apenas enquanto o projeto estiver em **Falha** estado, o que impede que duas tentativas de configuração sejam executadas simultaneamente.

## 4\. Revisão da conclusão

Quando o estado muda para **Concluído**, revise o pull request resultante no GitHub. Se falhar novamente, utilize a nova atividade no cartão em vez da tentativa anterior para identificar a próxima ação.