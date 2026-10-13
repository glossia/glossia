%{
  title: "Retentar configuração do projeto",
  summary: "Recuperar o projeto após falha na configuração.",
  category: "Tutorial",
  section: "translation",
  order: 4
}
---

Quando a configuração automatizada falha, o Glossia descarta o projeto provisório para que o repositório possa ser selecionado novamente. Um aviso de falha pode aparecer no fluxo de configuração, mas o projeto falhado e seu histórico de progresso não são mantidos.

## 1. Leia a falha

Leia o aviso de falha antes de sair do fluxo de configuração. As causas comuns incluem:

- A conta não possui um modelo configurado.
- A chave do provedor está ausente ou não é mais válida.
- O Glossia GitHub App não pode acessar o repositório.
- O repositório não pôde ser preparado ou verificado.

## 2. Corrija o pré-requisito

Para problemas de modelo, abra **Configurações → Modelos**. Para problemas de acesso ao repositório, atualize a instalação do Glossia GitHub App no GitHub e conceda-lhe acesso ao repositório.

## 3. Inicie a configuração novamente

Abra **Projetos → Novo projeto**, selecione o repositório, escolha **Configuração automatizada** e selecione os idiomas-alvo novamente. Siga a nova tentativa de configuração até que termine.

Se um projeto falho ainda estiver visível e oferecer **Retentar configuração**, essa ação inicia outra tentativa. Não confie que ele permaneça disponível: projetos provisórios falhos são removidos durante a limpeza.

## 4. Revise a conclusão

Quando a configuração é concluída, revise a solicitação de pull resultante no GitHub. Veja [Configuração do projeto](/docs/reference/project-setup) para o ciclo de vida e comportamento de limpeza.
