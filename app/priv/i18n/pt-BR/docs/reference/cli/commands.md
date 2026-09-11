%{
  title: "Comandos",
  summary: "Referência para todos os comandos de linha de comando do Glossia e suas opções.",
  category: "referência",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Crie um inicializador`L10N.md`de arquivo de configuração no repositório atual.

```bash
glossia init
```

Falha se`L10N.md`já existe.

## A tradução é executada no servidor

A tradução roda no servidor Glossia, não na interface de linha de comando. Quando um commit é enviado,
Glossia planeja o trabalho a partir do seu`L10N.md`arquivos, traduz cada arquivo com
o modelo configurado na sua conta e abre uma pull request com os resultados. Você
pode acompanhar cada arquivo e os turns do modelo ao vivo na página de sessão de tradução.

O modelo é escolhido por documento: um`L10N.md` `model:`nome de um dos seus
modelos de conta o selecionam; caso contrário, o modelo padrão da sua conta é usado.

A interface de linha de comando intencionalmente não planeja, traduz, valida,
inspeciona, ou deleta traduções geradas. Ela também não lê os
lockfiles de tradução.

## `glossia revisit`

Reservado para uma futura passagem de revisão de idioma de origem. A interface de linha de comando em Rust
atualmente retorna um erro de não implementado para este comando.

```bash
glossia revisit
```

## Flags globais

| Flag | Descrição |
|---|---|
| `--path <PATH>` | Substituir o diretório raiz do projeto |
| `--no-color` | Desativar saída colorida |