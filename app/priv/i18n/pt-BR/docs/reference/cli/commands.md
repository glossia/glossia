%{
  title: "Comandos",
  summary: "Referência para todos os comandos de linha de comando do Glossia e suas opções.",
  category: "referência",
  subcategory: "cli",
  order: 1
}
---

## `glossia init`

Crie um arquivo `L10N.md` de configuração inicial no repositório atual.

```bash
glossia init
```

Falha se `L10N.md` já existir.

## A tradução é feita no servidor.

A tradução é executada no serviço Glossia hospedado, não na interface de linha de comando. Quando um commit é efetivado, o Glossia planeja o trabalho a partir dos seus arquivos `L10N.md` e traduz cada arquivo com o modelo configurado da sua conta, abrindo um pull request com os resultados. Você pode acompanhar cada arquivo e os turnos do modelo ao vivo na página de sessão de tradução.

O modelo é escolhido por documento: um arquivo `L10N.md` com `model:` definindo um dos identificadores de modelo da sua conta seleciona-o; caso contrário, o modelo padrão da sua conta é usado.

A interface de linha de comando intencionalmente não planeja, traduz, valida, inspeciona ou exclui traduções geradas. Também não lê os lockfiles de tradução publicados pelo Glossia.

## `glossia revisit`

Reservado para uma futura etapa de revisão de idioma-fonte. A interface de linha de comando em Rust atualmente retorna um erro de não implementado para este comando.

```bash
glossia revisit
```

## Parâmetros globais

| Parâmetro | Descrição |
|---|---|
| `--path <PATH>` | Sobrescrever o diretório raiz do projeto |
| `--no-color` | Desativar saída colorida |
