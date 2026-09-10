%{
  title: "Comandos",
  summary: "Referência para todos os comandos de linha de comando do Glossia e suas bandeiras.",
  category: "referência",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Crie um inicial`L10N.md`de configuração no repositório atual.

```bash
glossia init
```

Falha se`L10N.md` já existe.

## A tradução é do servidor

A tradução ocorre no servidor Glossia, e não na interface de linha de comando. Quando um commit é recebido,
O Glossia planeja o trabalho a partir do seu `L10N.md` arquivos, traduz cada arquivo com
o modelo configurado da sua conta, e abre um pull request com os resultados. Você
pode acompanhar cada arquivo e os turnos do modelo ao vivo na página da sessão de tradução.

O modelo é escolhido por documento: um `L10N.md` `model:` nomeando uma de suas
modelo de conta selecionado; caso contrário, o modelo padrão da sua conta é usado.

A interface de linha de comando não planeja, traduz ou valida,
inserir, nem excluir traduções geradas. Também não lê os
arquivos de bloqueio de tradução.

## `glossia revisit`

Reservado para uma revisão futura da linguagem de origem. A linha de comando Rust
interface atualmente retorna um erro de não implementado para este comando.

```bash
glossia revisit
```

## Opções globais

| Opção | Descrição |
|---|---|
| `--path <PATH>` | Substituir o diretório raiz do projeto |
| `--no-color` | Desativar saída colorida |