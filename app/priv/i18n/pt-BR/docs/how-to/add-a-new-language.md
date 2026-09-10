%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma de destino a uma configuração existente do Glossia.",
  category: "tutorial",
  order: 1
}
---
Se você já tiver o Glossia configurado e quiser adicionar outro idioma de destino, siga estes passos.

## 1\. Atualize o L10N.md

Abra o seu `L10N.md` e adicione o novo código de idioma ao `targets` array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Adicionar contexto específico do idioma (opcional)

Se o novo idioma precisar de instruções especiais, como nível de formalidade ou considerações sobre o conjunto de caracteres, crie um arquivo de substituição de contexto:

    L10N/
      ja.md

Escreva quaisquer orientações específicas do idioma naquele arquivo. O Glossia as mescla com o contexto base para traduções em japonês.

## 3\. Publique as alterações de configuração

Faça o commit e push da configuração atualizada. Se o repositório estiver conectado ao
Glossia, o servidor detecta o novo idioma de destino e inicia uma tradução
sessão.

As traduções existentes para outros idiomas permanecem inalteradas quando suas entradas
e o contexto efetivo não tenham mudado.

## 4\. Revise o pull request de tradução

Acompanhe a sessão de tradução no Glossia e depois revise o idioma gerado
arquivos na solicitação pull aberta pelo servidor.