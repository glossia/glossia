%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma de destino a uma configuração Glossia existente.",
  category: "passo-a-passo",
  order: 1
}
---
Se você já tem o Glossia configurado e quiser adicionar outro idioma de destino, siga estes passos.

## 1\. Atualize L10N.md

Abra o seu `L10N.md` e adicione o novo código do idioma ao `targets` array:

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

Escreva qualquer orientação específica do idioma neste arquivo. O Glossia combina-o com o contexto base para traduções em japonês.

## 3\. Publique a alteração de configuração

Faça o commit e o push da configuração atualizada. Se o repositório estiver conectado ao
Glossia, o servidor detecta o novo idioma de destino e inicia uma tradução
sessão.

Traduções existentes para outros idiomas permanecem inalteradas quando suas entradas
e o contexto efetivo não mudou.

## 4\. Revise a Pull Request de tradução

Siga a sessão de tradução no Glossia, em seguida, revise a tradução gerada
arquivos no pull request aberto pelo servidor.