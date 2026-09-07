%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma de destino a uma configuração Glossia existente.",
  category: "guia",
  order: 1
}
---
Se você já tem o Glossia configurado e deseja adicionar outro idioma de destino, siga esses passos.

## Atualize o GLOSSIA.md

Abra o `GLOSSIA.md` e adicione o novo código de idioma ao `targets`array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## Adicione um contexto específico do idioma (opcional)

Se o novo idioma precisar de instruções especiais, como nível de formalidade ou considerações sobre o conjunto de caracteres, crie um arquivo de sobrescrita de contexto:

    GLOSSIA/
      ja.md

Escreva qualquer orientação específica do idioma nesse arquivo. O Glossia o mescla com o contexto base para traduções em japonês.

## Publicar a alteração na configuração

Faça o commit e empurre a configuração atualizada. Se o repositório estiver conectado ao
Glossia, o servidor detecta o novo idioma de destino e inicia uma tradução
sessão.

As traduções existentes para outros idiomas permanecem inalteradas quando suas entradas
e contexto efetivo não tenham mudado.

## Revise os arquivos do idioma no pull request

Siga a sessão de tradução no Glossia e, em seguida, revise os arquivos do idioma gerados
nos arquivos do pull request aberto pelo servidor.