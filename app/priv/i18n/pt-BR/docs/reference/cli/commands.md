%{
  title: "Comandos",
  summary: "Referência para todos os comandos de linha de comando do Glossia e suas opções.",
  category: "referência",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Crie um modelo inicial`L10N.md`de configuração no repositório atual.

```bash
glossia init
```

Falha se`L10N.md` já estiver presente.

## A tradução é no servidor

A tradução ocorre no servidor do Glossia, não na interface de linha de comando.
O Glossia planeja o trabalho a partir do seu`L10N.md`arquivos, traduz cada arquivo com
modelo configurado em sua conta e abre um pull request com os resultados. Você
pode acompanhar cada arquivo e os turnos do modelo ao vivo na página da sessão de tradução.

O modelo é escolhido por documento:`L10N.md` `model:` nomeando um dos seus
selecionado pela sua conta; caso contrário, o modelo padrão da conta é usado.

A interface de linha de comando intencionalmente não planeja, traduz, valida,
inspeciona ou exclui traduções geradas. Também não lê os
arquivos de bloqueio de tradução do servidor.

## `glossia revisit`

Reservado para uma revisão futura de idioma-fonte.
interface atualmente retorna erro de não implementado para este comando.

```bash
glossia revisit
```

## Flags globais

| Flag | Descrição |
|---|---|
|`--path <PATH>` |
|`--no-color` |