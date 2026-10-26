%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma alvo a uma configuração Glossia existente.",
  category: "how-to",
  section: "translation",
  order: 1
}
---

Se você já tem o Glossia configurado e quiser adicionar outro idioma de destino, siga estes passos.

## 1. Atualize o L10N.md

Abra o seu `L10N.md` e adicione o novo código de idioma ao `targets` array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Adicione contexto específico de idioma (opcional)

Se o novo idioma precisar de instruções específicas, como nível de formalidade ou considerações sobre o conjunto de caracteres, crie um arquivo de sobrescrita de contexto:

```
L10N/
  ja.md
```

Escreva qualquer orientação específica de idioma naquele arquivo. O Glossia o mescla com o contexto base para traduções japonesas.

## 3. Publique a alteração de configuração

Faça o commit e realize o push da configuração atualizada. Se o repositório estiver conectado ao Glossia, o servidor detectará o novo idioma de destino e iniciará uma sessão de tradução.

As traduções existentes para outros idiomas permanecem inalteradas quando suas entradas e contexto efetivo não foram alterados.

## 4. Revise o pull request de tradução

Acompanhe a sessão de tradução no Glossia e depois revise os arquivos gerados no pull request aberto pelo servidor.
