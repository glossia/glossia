%{
  title: "Comandos",
  summary: "Referência de todos os comandos de linha de comando do Glossia e suas opções.",
  category: "Referência",
  subcategory: "CLI",
  order: 1
}
---

## `glossia init`

Crie um arquivo de configuração inicializador `L10N.md` no repositório atual.

```bash
glossia init
```

Falha se `L10N.md` já existir.

## A tradução ocorre no servidor

A tradução é executada no serviço hospedado do Glossia, não na interface de linha de comando. Quando um commit é adicionado, o Glossia planeja o trabalho a partir dos arquivos `L10N.md` do seu projeto, traduz cada arquivo com o modelo configurado na sua conta e abre um pull request com os resultados. Você pode acompanhar cada arquivo e os turnos do modelo ao vivo na página de sessão de tradução.

O modelo é escolhido por documento: um `L10N.md` `model:` designando um dos identificadores do modelo da sua conta o seleciona; caso contrário, o modelo padrão da sua conta é usado.

A interface de linha de comando intencionalmente não planeja, traduz, valida, inspeciona ou excluir traduções geradas. Também não lê os arquivos de bloqueio de tradução publicados pelo Glossia.

## `glossia revisit`

Reservado para uma futura revisão da versão da língua de origem. A interface de linha de comando do Rust atualmente retorna um erro de não implementado para este comando.

```bash
glossia revisit
```

## Parâmetros globais

| Parâmetro | Descrição |
|---|---|
| `--path <PATH>` | Substituir o diretório raiz do projeto |
| `--no-color` | Desabilitar saída colorida |
