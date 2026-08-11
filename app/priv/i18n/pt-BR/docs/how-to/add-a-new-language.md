%{
  title: "Adicionar um novo idioma",
  summary: "Como adicionar um idioma de destino a uma configuração existente do Glossia.",
  category: "how-to",
  order: 1
}
---
Se você já configurou o Glossia e deseja adicionar outro idioma de destino, siga estas etapas.

## 1. Atualize o GLOSSIA.md

Abra seu `GLOSSIA.md` e adicione o código do novo idioma ao array `targets`:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Adicione contexto específico do idioma (opcional)

Se o novo idioma exigir instruções específicas, como nível de formalidade ou considerações sobre o conjunto de caracteres, crie um arquivo de substituição de contexto:

```
GLOSSIA/
  ja.md
```

Adicione a esse arquivo todas as orientações específicas do idioma. O Glossia as combina com o contexto base para as traduções em japonês.

## 3. Publique a alteração de configuração

Faça commit e push da configuração atualizada. Se o repositório estiver conectado ao
Glossia, o servidor detectará o novo idioma de destino e iniciará uma sessão de
tradução.

As traduções existentes para outros idiomas permanecerão inalteradas se suas entradas
e seu contexto efetivo não tiverem sido alterados.

## 4. Revise a solicitação de pull da tradução

Acompanhe a sessão de tradução no Glossia e, em seguida, revise os arquivos do idioma
gerados na solicitação de pull aberta pelo servidor.