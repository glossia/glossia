%{
  title: "Tentar novamente a configuração do projeto",
  summary: "Recuperar um projeto após a configuração relatar uma falha.",
  category: "Tutoriais",
  section: "translation",
  order: 4
}
---

Quando a configuração automática falha, o Glossia descarta o projeto provisório para que o repositório possa ser selecionado novamente. Um aviso de falha pode aparecer no fluxo de configuração, mas o projeto falho e seu histórico de progresso não são retidos.

## 1. Leia a falha

Leia o aviso de falha antes de sair do fluxo de configuração. Causas comuns incluem:

- A conta não possui modelo configurado.
- A chave do provedor está ausente ou não é mais válida.
- O aplicativo GitHub do Glossia não pode acessar o repositório.
- O repositório não pôde ser preparado ou verificado.

## 2. Corrija o pré-requisito

Para problemas de modelo, abra **Configurações → Modelos**. Para problemas de acesso ao repositório, atualize a instalação do aplicativo GitHub do Glossia no GitHub e conceda acesso ao repositório.

## 3. Inicie a configuração novamente

Abra **Projetos → Novo projeto**, selecione o repositório, escolha **Configuração automática** e selecione os idiomas de destino novamente. Acompanhe a nova tentativa de configuração até que termine.

Se um projeto falho ainda estiver visível e oferecer **Reiniciar configuração**, essa ação inicia outra tentativa. Não conte com que ela permaneça disponível: projetos provisórios falhos são removidos durante a limpeza.

## 4. Revise a conclusão

Quando a configuração terminar, revise o pull request resultante no GitHub. Consulte [Configuração do projeto](/docs/reference/project-setup) para o comportamento de ciclo de vida e limpeza.
