%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma de destino a uma configuração Glossia existente.",
  category: "Passo a passo",
  order: 1
}
---
Se você já tem o Glossia configurado e quer adicionar outro idioma-alvo, siga estes passos.

## 1\. Atualize L10N.md

Abra seu `L10N.md` e adicione o código do novo idioma ao `targets` array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Adicione contexto específico para o idioma (opcional)

Se o novo idioma precisa de instruções especiais, como nível de formalidade ou considerações de conjunto de caracteres, crie um arquivo de sobreposição de contexto:

    L10N/
      ja.md

Escreva quaisquer orientações específicas do idioma nesse arquivo. O Glossia o funde com o contexto base para traduções japonesas.

## 3\. Publique a alteração de configuração

Faça commit e push da configuração atualizada. Se o repositório estiver conectado ao
Glossia, o servidor detecta o novo idioma alvo e inicia uma tradução
sessão.

Traduções existentes para outros idiomas permanecem inalteradas quando suas entradas
e contexto efetivo não tenham sido alterados.

## 4\. Revise o pull request de tradução

Siga a sessão de tradução no Glossia e, em seguida, revise o idioma gerado
arquivos no pull request aberto pelo servidor.