%{
  title: "Comandos",
  summary: "Referência para todos os comandos de linha de comando da Glossia e suas opções.",
  category: "Referência",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Crie um modelo inicial`GLOSSIA.md` de configuração no repositório atual.

```bash
glossia init
```

Falha se`GLOSSIA.md` já existir.

## A tradução ocorre no servidor

A tradução execute no servidor da Glossia, não na interface de linha de comando. Quando um commit é realizado,
a Glossia planeja o trabalho a partir dos seus`GLOSSIA.md` arquivos, traduz cada arquivo com
modelo de configuração da sua conta, e abre um pull request com os resultados. Você
pode acompanhar cada arquivo e os movimentos do modelo em tempo real na página de sessão de tradução.

O modelo é escolhido por documento: um`GLOSSIA.md` `model:` nomeando um dos seus
 o modelo de configuração da sua conta será selecionado; caso contrário, o modelo padrão da sua conta será usado.

A interface de linha de comando intencionalmente não planeja, traduz, valida,
inspeciona ou exclui traduções geradas. Também não lê os
arquivos de bloqueio de tradução.

## `glossia revisit`

Reservado para uma futura revisão de revisão de origem. A interface de linha de comando
em Rust atualmente retornará um erro de não implementado para este comando.

```bash
glossia revisit
```

## Bandas globais

| Flag | Descrição |
|---|---|
| `--path <PATH>` | Substituir o diretório raiz do projeto |
| `--no-color` | Desativar saída colorida |