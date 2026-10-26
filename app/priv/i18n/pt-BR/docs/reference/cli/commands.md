%{
  title: "Comandos",
  summary: "Referência para todos os comandos de linha de comando do Glossia e suas flags.",
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

Falha se `L10N.md` já existir.

## A tradução é do lado do servidor

A tradução é executada no serviço hospedado da Glossia, não na interface de linha de comando. Quando um commit é realizado, a Glossia planeja o trabalho a partir dos seus `L10N.md` arquivos, traduz cada arquivo com o modelo configurado na sua conta e abre um pull request com os resultados. Você pode acompanhar cada arquivo e os turnos do modelo em tempo real na página de sessão de tradução.

O modelo é escolhido por documento: um `L10N.md` `model:` que nomeia um dos handles do modelo da sua conta seleciona-o; caso contrário, o modelo padrão da sua conta é usado.

A interface de linha de comando intencionalmente não planeja, traduz, valida, inspecciona ou exclui traduções geradas. Ela também não lê os lockfiles de tradução publicados pelo Glossia.

## `glossia revisit`

Reservado para uma futura etapa de revisão da linguagem de origem. A interface de linha de comando do Rust atualmente retorna um erro não implementado para este comando.

```bash
glossia revisit
```

## Opções globais

| Opção | Descrição |
|---|---|
| `--path <PATH>` | Sobrescrever o diretório raiz do projeto |
| `--no-color` | Desativar saída colorida |
