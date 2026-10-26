%{
  title: "Reiniciar configuração do projeto",
  summary: "Recuperar um projeto após falha na configuração.",
  category: "Tutorial",
  section: "translation",
  order: 4
}
---

Quando a configuração automatizada falha, o Glossia descarta o projeto provisório para que o repositório possa ser selecionado novamente. Um aviso de falha pode aparecer no fluxo de configuração, mas o projeto falhado e seu histórico de progresso não são retidos.

## 1. Leia a falha

Leia o aviso de falha antes de sair o fluxo de configuração. As causas comuns incluem:

- A conta não possui modelo configurado.
- A chave do provedor está ausente ou não é mais válida.
- O aplicativo Glossia do GitHub não pode acessar o repositório.
- O repositório não pôde ser preparado ou verificado.

## 2. Corrija o pré-requisito

Para problemas de modelo, abra **Configurações → Modelos**. Para problemas de acesso ao repositório, atualize a instalação do aplicativo Glossia no GitHub e conceda a ele acesso ao repositório.

## 3. Inicie a configuração novamente

Abra **Projetos → Novo projeto**, selecione o repositório, escolha **Configuração automatizada** e selecione os idiomas de destino novamente. Acompanhe a nova tentativa de configuração até que ela seja concluída.

Se um projeto falhado ainda estiver visível e oferecer **Tentar configuração novamente**, essa ação inicia outra tentativa. Não conte com que permaneça disponível: os projetos provisórios falhos são removidos durante a limpeza.

## 4. Confira a conclusão

Quando a configuração é concluída, revise o pull request resultante no GitHub. Consulte [Configuração do projeto](/docs/reference/project-setup) para o ciclo de vida e o comportamento de limpeza.
