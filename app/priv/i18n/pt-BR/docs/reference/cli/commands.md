%{
  title: "Comandos",
  summary: "Referência para todos os comandos de linha de comando do Glossia e suas bandeiras.",
  category: "Referência",
  subcategory: "CLI",
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

A tradução roda no serviço Glossia hospedado, não na interface de linha de comando. Quando um commit chega,
O Glossia planeja o trabalho a partir dos seus `L10N.md` arquivos, traduz cada arquivo com
do seu modelo configurado da sua conta, e abre um pull request com os resultados. Você
pode acompanhar cada arquivo e os turnos do modelo ao vivo na página da sessão de tradução.

O modelo é escolhido por documento: a `L10N.md` `model:` nomeando um dos seus
o manipulador do modelo da sua conta seleciona-o; caso contrário, o modelo padrão da sua conta é usado.

A interface de linha de comando intencionalmente não planeja, traduz, valida,
inspecionar, ou excluir traduções geradas. Também não lê os arquivos de travamento publicados pela Glossia.

## `glossia revisit`

Reservado para uma etapa futura de revisão do idioma de origem. A linha de comando Rust
A interface atualmente retorna um erro não implementado para este comando.

```bash
glossia revisit
```

## Opções globais

| Opção | Descrição |
|---|---|
| `--path <PATH>` | Sobrescrever o diretório raiz do projeto |
| `--no-color` | Desativar saída colorida |