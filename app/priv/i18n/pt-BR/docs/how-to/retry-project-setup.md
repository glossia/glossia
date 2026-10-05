%{
  title: "Retentar a configuração do projeto",
  summary: "Recuperar o projeto após a configuração relatar uma falha.",
  category: "como fazer",
  section: "translation",
  order: 4
}
---
Quando a configuração automática falha, o Glossia descarta o projeto provisório para que o repositório possa ser selecionado novamente. Um aviso de falha pode aparecer no fluxo de configuração, mas o projeto falho e seu histórico de progresso não são retidos.

## 1\. Ler a falha

Leia o aviso de falha antes de sair do fluxo de configuração. Causas comuns incluem:

- A conta não possui modelo configurado.
- A chave do provedor está ausente ou não é mais válida.
- O Glossia GitHub App não consegue acessar o repositório.
- O repositório não pôde ser preparado ou verificado.

## 2\. Corrigir o pré-requisito

Para problemas de modelo, abra **Configurações → Modelos**. Para problemas de acesso ao repositório, atualize a instalação do Glossia GitHub App no GitHub e conceda acesso ao repositório.

## 3\. Inicie a configuração novamente

Abrir **Projetos → Novo projeto**, selecione o repositório, escolha **Configuração automatizada**, e selecione os idiomas de destino novamente. Siga a nova tentativa de configuração até que seja concluída.

Se um projeto falho ainda estiver visível e oferecer **Reiniciar configuração**, essa ação inicia outra tentativa. Não conte com ela permanecendo disponível: projetos falhos provisórios são removidos durante a limpeza.

## 4\. Revisar conclusão

Quando a configuração for concluída, revise o Pull Request resultante no GitHub. Veja [Configuração do projeto](/docs/reference/project-setup) para o comportamento de ciclo de vida e limpeza.