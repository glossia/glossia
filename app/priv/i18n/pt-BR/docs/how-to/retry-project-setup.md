%{
  title: "Tentar novamente a configuração do projeto",
  summary: "Recupere um projeto após uma falha na configuração.",
  category: "how-to",
  order: 4
}
---
Use **Tentar configuração novamente** após corrigir a condição que causou a falha na configuração de um projeto.

## 1. Examine a falha

Abra a visão geral do projeto. O cartão de progresso da configuração mostra a falha e a atividade de configuração mais recente.

As causas comuns incluem:

- A conta não tem um modelo configurado.
- A chave do provedor está ausente ou não é mais válida.
- O Glossia GitHub App não consegue acessar o repositório.
- Não foi possível preparar ou verificar o repositório.

## 2. Corrija o pré-requisito

Para problemas com o modelo, abra **Configurações** e **Modelos**. Para problemas de acesso ao repositório, atualize a instalação do Glossia GitHub App no GitHub e conceda a ela acesso ao repositório.

## 3. Tente novamente

Retorne à visão geral do projeto e selecione **Tentar configuração novamente**.

O cartão retorna para **Pendente**, depois para **Em execução**, e mostra novas atividades à medida que o trabalho avança. A opção para tentar novamente está disponível somente enquanto o projeto estiver no estado **Falhou**, o que impede a execução simultânea de duas tentativas de configuração.

## 4. Revise a conclusão

Quando o estado mudar para **Concluído**, revise a solicitação de pull resultante no GitHub. Se houver uma nova falha, use a nova atividade exibida no cartão, em vez da tentativa anterior, para identificar a próxima ação.