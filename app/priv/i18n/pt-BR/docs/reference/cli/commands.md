%{
  title: "Comandos",
  summary: "Referência de todos os comandos da linha de comando do Glossia e suas opções.",
  category: "reference",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Crie um arquivo de configuração inicial `GLOSSIA.md` no repositório atual.

```bash
glossia init
```

Falha se `GLOSSIA.md` já existir.

## A tradução é realizada no servidor

A tradução é executada no servidor da Glossia, não na interface de linha de comando. Quando um commit é incorporado, a Glossia planeja o trabalho com base nos seus arquivos `GLOSSIA.md`, traduz cada arquivo com o modelo configurado para a sua conta e abre uma solicitação de pull com os resultados. Você pode acompanhar cada arquivo e as interações do modelo em tempo real na página da sessão de tradução.

O modelo é escolhido por documento: um `GLOSSIA.md` `model:` que nomeie um dos identificadores de modelo da sua conta seleciona esse modelo; caso contrário, o modelo padrão da sua conta é utilizado.

A interface de linha de comando não planeja, traduz, valida, inspeciona nem exclui traduções geradas. Ela também não lê os lockfiles de tradução do servidor.

## `glossia revisit`

Reservado para uma futura etapa de revisão no idioma de origem. Atualmente, a interface de linha de comando em Rust retorna um erro de não implementado para este comando.

```bash
glossia revisit
```

## Opções globais

| Opção | Descrição |
|---|---|
| `--path <PATH>` | Substitui o diretório raiz do projeto |
| `--no-color` | Desativa a saída colorida |