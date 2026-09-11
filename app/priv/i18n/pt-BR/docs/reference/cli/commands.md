%{
  title: "Comandos",
  summary: "Referência para todos os comandos de linha de comando do Glossia e suas flags.",
  category: "Referência",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Crie um modelo`L10N.md` de configuração no repositório atual.

```bash
glossia init
```

Falha se`L10N.md` já existe.

## A tradução é do lado do servidor

A tradução é executada no servidor Glossia, não na interface de linha de comando. Quando um commit é confirmado,
O Glossia planeja o trabalho a partir do seu `L10N.md` arquivos, traduz cada arquivo com
o modelo configurado na sua conta e abre um pull request com os resultados. Você
pode acompanhar cada arquivo e os turnos do modelo ao vivo na página da sessão de tradução.

O modelo é escolhido por documento: um`L10N.md` `model:`referenciando um de seus
se o modelo da sua conta o selecionar; caso contrário, o modelo padrão da sua conta é usado.

A interface de linha de comando não planeja, traduz, valida,
inspecciona ou exclui traduções geradas. Também não lê os servidores
arquivos de bloqueio de tradução.

## `glossia revisit`

Reservado para uma futura passagem de revisão de idioma-fonte. A interface de linha de comando Rust
atualmente retorna um erro de não implementação para este comando.

```bash
glossia revisit
```

## Flags globais

| Flag | Descrição |
|---|---|
| `--path <PATH>` | Substituir o diretório raiz do projeto |
| `--no-color` | Desativar saída colorida |