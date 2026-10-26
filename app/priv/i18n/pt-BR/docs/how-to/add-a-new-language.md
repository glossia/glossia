%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma de destino a uma configuração Glossia existente.",
  category: "guia",
  section: "translation",
  order: 1
}
---

Se você já tem o Glossia configurado e deseja adicionar outro idioma de destino, siga estes passos.

## 1. Atualize L10N.md

Abra seu `L10N.md` e adicione o novo código do idioma ao array `targets`:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Adicione contexto específico para o idioma (opcional)

Se o novo idioma precisa de instruções especiais, como nível de formalidade ou considerações de conjunto de caracteres, crie um arquivo de substituição de contexto:

```
L10N/
  ja.md
```

Escreva qualquer orientação específica para o idioma naquele arquivo. O Glossia a mescla com o contexto base para traduções em japonês.

## 3. Publique a alteração de configuração

Faça commit e empurre a configuração atualizada. Se o repositório estiver conectado ao Glossia, o servidor detecta o novo idioma de destino e inicia uma sessão de tradução.

Traduções existentes para outros idiomas permanecem inalteradas quando suas entradas e contexto efetivo não tiverem mudado.

## 4. Revise a solicitação de pull de tradução

Acompanhe a sessão de tradução no Glossia, em seguida, revise os arquivos de idioma gerados na solicitação de pull aberta pelo servidor.
