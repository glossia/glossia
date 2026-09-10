%{
  title: "Comandos",
  summary: "Referência para todos os comandos de linha de comando do Glossia e suas bandeiras.",
  category: "Referência",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Crie um arquivo `L10N.md` de configuração no repositório atual.

```bash
glossia init
```

Falla se `L10N.md` já existe.

## Tradução é feita no servidor

A tradução é executada no servidor Glossia, não na interface de linha de comando. Quando um commit é enviado,
Glossia planeja o trabalho a partir do seu `L10N.md` arquivos, traduz cada arquivo com
modelo configurado na sua conta e abre um pull request com os resultados. Você
pode acompanhar cada arquivo e as alterações do modelo ao vivo na página da sessão de tradução.

O modelo é escolhido por documento: um `L10N.md` `model:` na sua
conta seleciona; caso contrário, o modelo padrão da sua conta é usado.

A interface de linha de comando não planeja, traduz, valida,
inspeciona ou exclui intencionalmente as traduções geradas. Também não lê os
lockfiles de tradução.

## `glossia revisit`

Reservado para uma futura passada de revisão da língua de origem. A interface de linha de comando
em Rust atualmente retorna um erro de não implementado para este comando.

```bash
glossia revisit
```

## Flags globais

| Flag | Descrição |
|---|---|
| `--path <PATH>` | Substitua o diretório raiz do projeto |
| `--no-color` | Desative a saída colorida |