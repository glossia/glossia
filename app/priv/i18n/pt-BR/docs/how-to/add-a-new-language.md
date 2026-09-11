%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma de destino a uma configuração existente do Glossia.",
  category: "tutoriais",
  order: 1
}
---
Se você já tem o Glossia configurado e deseja adicionar outro idioma de destino, siga estes passos.

## 1\. Atualize L10N.md

Abra o seu `L10N.md` e adicione o novo código de idioma à `targets` array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Adicione contexto específico do idioma (opcional)

Se o novo idioma precisar de instruções especiais, como nível de formalidade ou considerações sobre o conjunto de caracteres, crie um arquivo de substituição de contexto:

    L10N/
      ja.md

Escreva qualquer orientação específica para o idioma neste arquivo. O Glossia mescla isso com o contexto base para as traduções em japonês.

## 3\. Publicar a alteração de configuração

Faça o commit e o push da configuração atualizada. Se o repositório estiver conectado ao
Glossia, o servidor detecta o novo idioma de destino e inicia uma tradução
sessão.

As traduções existentes para outros idiomas permanecem inalteradas quando suas entradas
e o contexto efetivo não mudou.

## 4\. Revise o pull request de tradução

Acompanhe a sessão de tradução no Glossia e, em seguida, revise o idioma gerado
arquivos na solicitação de pull aberta pelo servidor.