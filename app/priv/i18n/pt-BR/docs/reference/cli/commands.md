%{
  title: "Comandos",
  summary: "Referência para todos os comandos de linha de comando do Glossia e suas opções.",
  category: "Referência",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Crie um`L10N.md` arquivo de configuração inicial no repositório atual.

```bash
glossia init
```

Falha se`L10N.md` já existe.

## A tradução é executada no servidor

A tradução é executada no servidor Glossia, não na interface de linha de comando. Quando um commit é recebido,
Glossia planeja o trabalho a partir dos seus`L10N.md` arquivos, traduz cada arquivo com
o modelo configurado na sua conta, e abre um pull request com os resultados. Você
pode monitorar cada arquivo e os turnos do modelo ao vivo na página da sessão de tradução.

O modelo é escolhido por documento: um`L10N.md` `model:` nome de um dos seus
modelo de conta seleciona isso; caso contrário, o modelo padrão da sua conta é usado.

A interface de linha de comando intencionalmente não planeja, traduz, valida,
inspeção, nem excluir traduções geradas. Também não lê os do servidor
arquivos de bloqueio de tradução.

## `glossia revisit`

Reservado para uma futura passagem de revisão de idioma-fonte. A interface de linha de comando em
Rust atualmente retorna um erro de não implementado para este comando.

```bash
glossia revisit
```

## Bandeiras globais

| Bandeira | Descrição |
|---|---|
 | `--path <PATH>` | Substitua o diretório raiz do projeto |
| `--no-color` | Desabilite a saída colorida |