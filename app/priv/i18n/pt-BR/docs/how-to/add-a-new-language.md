%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma de destino a uma configuração existente do Glossia.",
  category: "tutoriais",
  section: "translation",
  order: 1
}
---

Se você já tiver o Glossia configurado e quiser adicionar outro idioma de destino, siga esses passos.

## 1. Atualize L10N.md

Abra seu `L10N.md` e adicione o novo código de idioma ao `targets` array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Adicione o contexto específico do idioma (opcional)

Se o novo idioma precisar de instruções especiais, como nível de formalidade ou considerações sobre o conjunto de caracteres, crie um arquivo de substituição de contexto:

```
L10N/
  ja.md
```

Escreva qualquer orientação específica do idioma neste arquivo. O Glossia o combina com o contexto base para as traduções japonesas.

## 3. Publique a alteração de configuração

Faça commit e empurre a configuração atualizada. Se o repositório estiver conectado ao Glossia, o servidor detecta a nova linguagem de destino e inicia uma sessão de tradução.

As traduções existentes para outros idiomas permanecem inalteradas quando suas entradas e contexto efetivo não forem alterados.

## 4. Revise o pedido de pull de tradução

Siga a sessão de tradução no Glossia e revise os arquivos de linguagem gerados no pedido de pull aberto pelo servidor.
