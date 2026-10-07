%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma-alvo a uma configuração Glossia existente.",
  category: "guias",
  section: "translation",
  order: 1
}
---
Se você já tem o Glossia configurado e quiser adicionar outro idioma de destino, siga estes passos.

## 1\. Atualize o L10N.md

Abra seu `L10N.md` e adicione o código do novo idioma ao `targets` array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Adicione contexto específico por idioma (opcional)

Se o novo idioma precisar de instruções especiais, como nível de formalidade ou considerações de conjunto de caracteres, crie um arquivo de sobrescrita de contexto:

    L10N/
      ja.md

Escreva qualquer diretriz específica de idioma nesse arquivo. O Glossia o mescla com o contexto base para traduções em japonês.

## 3\. Publique a alteração de configuração

Faça o commit e o push da configuração atualizada. Se o repositório estiver conectado ao
Glossia, o servidor detecta a nova linguagem-alvo e inicia uma tradução
sessão.

As traduções existentes para outras línguas permanecem inalteradas quando suas entradas
e o contexto efetivo não tenham sido alterados.

## 4\. Revise a solicitação de pull de tradução

Acompanhe a sessão de tradução no Glossia, em seguida, revise a tradução gerada
arquivos no pull request aberto pelo servidor.