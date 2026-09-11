%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma alvo a uma configuração Glossia existente.",
  category: "Tutorial",
  order: 1
}
---
Se você já tiver o Glossia configurado e quiser adicionar outro idioma de destino, siga estes passos.

## 1\. Atualizar L10N.md

Abra o seu `L10N.md` e adicione o código do novo idioma à `targets` lista:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Adicionar contexto específico de idioma (opcional)

Se o novo idioma precisar de instruções especiais, como nível de formalidade ou considerações sobre o conjunto de caracteres, crie um arquivo de sobrescrita de contexto:

    L10N/
      ja.md

Escreva qualquer orientação específica para o idioma nesse arquivo. O Glossia o mescla ao contexto base para as traduções em japonês.

## 3\. Publicar a alteração de configuração

Faça commit e push da configuração atualizada. Se o repositório estiver conectado ao
Glossia, o servidor detecta o novo idioma de destino e inicia uma tradução
sessão.

As traduções existentes para outros idiomas permanecem inalteradas quando suas entradas
e o contexto efetivo não terem mudado.

## 4\. Revisar o pull request de tradução

Acompanhe a sessão de tradução no Glossia e revise a tradução gerada.
arquivos no pull request aberto pelo servidor.