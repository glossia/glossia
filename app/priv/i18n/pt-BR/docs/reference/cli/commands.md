%{
  title: "Comandos",
  summary: "Referência de todos os comandos da linha de comando do Glossia e suas opções.",
  category: "referência",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Crie um inicial `L10N.md` arquivo de configuração no repositório atual.

```bash
glossia init
```

Falha se `L10N.md` já existe.

## A tradução é do lado do servidor

A tradução é executada no servidor da Glossia, não na interface de linha de comando. Quando um commit chega,
A Glossia planeja o trabalho a partir dos seus `L10N.md` arquivos, traduzindo cada arquivo com
o modelo configurado da sua conta e abre um pull request com os resultados. Você
pode acompanhar cada arquivo e os turnos do modelo ao vivo na página da sessão de tradução.

O modelo é escolhido por documento: um `L10N.md` `model:` nomeando um dos seus
um gestor de modelo da sua conta seleciona-o; caso contrário, o modelo padrão da sua conta é usado.

A interface de linha de comando intencionalmente não planeja, traduz, valida,
inspecionar ou excluir traduções geradas. Ela também não lê do servidor
arquivos de bloqueio de tradução.

## `glossia revisit`

Reservado para uma futura revisão de idioma-fonte. A interface de
comando do Rust atualmente retorna um erro não implementado para este comando.

```bash
glossia revisit
```

## Opções globais

| Opção | Descrição |
|---|---|
| `--path <PATH>` | Sobrescrever o diretório raiz do projeto |
| `--no-color` | Desativar saída colorida |