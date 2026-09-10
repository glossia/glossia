%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma de destino a uma configuração Glossia existente.",
  category: "Tutorial",
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

## 2\. Adicione contexto específico para o idioma (opcional)

Se o novo idioma precisar de instruções especiais, como nível de formalidade ou considerações sobre o conjunto de caracteres, crie um arquivo de sobrescrita de contexto:

    L10N/
      ja.md

Escreva qualquer orientação específica para o idioma nesse arquivo. O Glossia o mescla com o contexto base para traduções em japonês.

## 3\. Publique a alteração de configuração

Faça o commit e empurre a configuração atualizada. Se o repositório estiver conectado ao
Glossia, o servidor detecta o novo idioma-alvo e inicia uma tradução
sessão.

As traduções existentes para outros idiomas permanecem inalteradas quando suas entradas
e contexto efetivo não tiverem mudado.

## 4\. Revise o pull request de tradução

Acompanhe a sessão de tradução no Glossia, em seguida revise o idioma gerado
arquivos no pull request aberto pelo servidor.