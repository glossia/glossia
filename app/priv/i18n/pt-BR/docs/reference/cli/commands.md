%{
  title: "Comandos",
  summary: "Referência para todos os comandos de linha de comando do Glossia e suas opções.",
  category: "referência",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Criar um inicial `L10N.md` arquivo de configuração no repositório atual.

```bash
glossia init
```

Falha se `L10N.md` já existe.

## A tradução é processada no servidor

A tradução é executada no servidor do Glossia, não na interface de linha de comando. Quando o commit é realizado,
A Glossia planeja o trabalho a partir dos seus `L10N.md` arquivos, traduzindo cada arquivo com
o modelo configurado da sua conta e abre um pull request com os resultados. Você
pode assistper a cada arquivo e aos turnos do modelo ao vivo na página de sessão de tradução.

O modelo é escolhido por documento: um `L10N.md` `model:` nomeando um dos seus
lidadores do modelo da sua conta selecionam-no; caso contrário, o modelo padrão da sua conta é utilizado.

A interface de linha de comando intencionalmente não planeja, traduz, valida,
inspecionar, ou excluir traduções geradas. Ela também não lê os do servidor
arquivos de bloqueio de tradução.

## `glossia revisit`

Reservado para uma futura revisão da linguagem-fonte. A linha de comando do Rust
interface atualmente retorna um erro não implementado para este comando.

```bash
glossia revisit
```

## Opções globais

| Opção | Descrição |
|---|---|
| `--path <PATH>` | Sobrescrever o diretório raiz do projeto |
| `--no-color` | Desabilitar saída colorida |