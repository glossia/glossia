%{
  title: "Comandos",
  summary: "Referência para todos os comandos de linha de comando do Glossia e suas bandeiras.",
  category: "referência",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Crie um arquivo de configuração inicial `L10N.md` no repositório atual.

```bash
glossia init
```

O comando falha se o `L10N.md` já existir.

## A tradução ocorre no servidor

A tradução é executada no servidor Glossia, não na interface de linha de comando. Quando um commit é recebido,
o Glossia planeja o trabalho a partir dos seus arquivos `L10N.md`, traduz cada arquivo com
o modelo configurado na sua conta e abre um pull request com os resultados. Você
pode acompanhar cada arquivo e as execuções do modelo em tempo real na página da sessão de tradução.

O modelo é escolhido por documento: um `L10N.md` em um arquivo `model:` que nomeia um dos
identificadores de modelo da sua conta seleciona-o; caso contrário, é usado o modelo padrão da conta.

A interface de linha de comando intencionalmente não planeja, traduz, valida,
inspeciona ou exclui traduções geradas. Ela também não lê os arquivos de bloqueio de tradução
do servidor.

## `glossia revisit`

Reservado para uma futura revisão do idioma de origem. A interface de linha de comando
em Rust retorna atualmente um erro de não implementado para este comando.

```bash
glossia revisit
```

## Opções globais

| Opção | Descrição |
|---|---|
| `--path <PATH>` | Substituir o diretório da raiz do projeto |
| `--no-color` | Desativar saída colorida |