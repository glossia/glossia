%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma-alvo a uma configuração existente do Glossia.",
  category: "tutorial",
  section: "tradução",
  order: 1
}
---
Se você já tem o Glossia configurado e quiser adicionar outro idioma de destino, siga estes passos.

## 1\. Atualize L10N.md

Abra o seu `L10N.md` e adicione o código do novo idioma à `targets` lista:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Adicione contexto específico ao idioma (opcional)

Se o novo idioma precisar de instruções especiais, como nível de formalidade ou considerações sobre o conjunto de caracteres, crie um arquivo de sobrescrita de contexto:

    L10N/
      ja.md

Escreva quaisquer orientações específicas do idioma nesse arquivo. O Glossia o combina com o contexto base para traduções em japonês.

## 3\. Publique a alteração de configuração

Comite e envie a configuração atualizada. Se o repositório estiver conectado ao
Glossia, o servidor detecta o novo idioma-alvo e inicia uma sessão de
sessão.

As traduções existentes de outros idiomas permanecem inalteradas quando seus inputs
e contexto efetivo não mudaram.

## 4\. Revise o pull request de tradução

Acompanhe a sessão de tradução no Glossia, então revise o idioma gerado
arquivos no pull request aberto pelo servidor.