%{
  title: "Retentar configuração do projeto",
  summary: "Recuperar um projeto após a configuração relatar uma falha.",
  category: "Tutorial",
  order: 4
}
---
Utilize **Tentar novamente a configuração** após corrigir a condição que causou uma falha na configuração do projeto.

## 1\. Leia a falha

Abra a visão geral do projeto. O cartão de progresso da configuração mostra a falha e a atividade de configuração mais recente.

As causas comuns incluem:

- A conta não possui modelo configurado.
- A chave do provedor não existe ou não é mais válida.
- A aplicação GitHub da Glossia não pode acessar o repositório.
- O repositório não pôde ser preparado ou verificado.

## 2\. Corrija o pré-requisito

Para problemas de modelo, abra **Configurações** e **Modelos**. Para problemas de acesso ao repositório, atualize a instalação da aplicação GitHub da Glossia no GitHub e conceda-lhe acesso ao repositório.

## 3\. Tentar novamente

Retornar à visão geral do projeto e selecionar **Tentar novamente a configuração**.

O cartão retorna para **Pendente**, em seguida **Executando**, e mostra novas atividades conforme o trabalho avança. A reintentação está disponível apenas enquanto o projeto estiver em **Falha** , estado, o que impede que duas tentativas de configuração sejam executadas simultaneamente.

## 4\. Revisão da conclusão

Quando o estado muda para **Concluído**, revise o pull request resultante no GitHub. Se falhar novamente, use a nova atividade no cartão em vez da tentativa anterior para identificar a próxima ação.