%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma de destino a uma configuração Glossia existente.",
  category: "Tutorial",
  order: 1
}
---
Se você já possui o Glossia configurado e quiser adicionar outro idioma de destino, siga estes passos.

## 1\. Atualize L10N.md

Abra o seu `L10N.md` e adicione o novo código de idioma ao `targets` array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Adicione contexto específico do idioma (opcional)

Se o novo idioma exigir instruções especiais, como o nível de formalidade ou considerações sobre o conjunto de caracteres, crie um arquivo de sobrescrita de contexto:

    L10N/
      ja.md

Escreva qualquer orientação específica do idioma nesse arquivo. O Glossia combina-o com o contexto base para traduções em japonês.

## 3\. Publique a alteração de configuração

Faça o commit e push da configuração atualizada. Se o repositório estiver conectado a
Glossia, o servidor detecta o novo idioma de destino e inicia uma tradução
sessão.

As traduções existentes para outros idiomas permanecem inalteradas quando suas entradas
e o contexto efetivo não mudaram.

## 4\. Revise a solicitação de pull de tradução

Acompanhe a sessão de tradução no Glossia, depois revise a tradução gerada
arquivos na pull request aberta pelo servidor.