%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma de destino a uma configuração Glossia existente.",
  category: "tutorial",
  order: 1
}
---
Se você já tem o Glossia configurado e deseja adicionar outro idioma de destino, siga estes passos.

## 1\. Atualize o L10N.md

Abra seu `L10N.md` e adicione o código do novo idioma à `targets` lista:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Adicione contexto específico do idioma (opcional)

Se o novo idioma precisar de instruções especiais, como nível de formalidade ou considerações sobre o conjunto de caracteres, crie um arquivo de sobrescrita de contexto:

    L10N/
      ja.md

Digite qualquer orientação específica do idioma naquele arquivo. O Glossia o mescla com o contexto base para as traduções do japonês.

## 3\. Publique a alteração de configuração

Faça o commit e o push da configuração atualizada. Se o repositório estiver conectado ao
Glossia, o servidor detecta o novo idioma de destino e inicia uma tradução
sessão.

As traduções existentes para outros idiomas permanecem inalteradas quando suas entradas
e o contexto efetivo não tiverem mudado.

## 4\. Revise o pull request de tradução

Siga a sessão de tradução no Glossia e, em seguida, revise o idioma gerado
arquivos na solicitação de pull aberta pelo servidor.