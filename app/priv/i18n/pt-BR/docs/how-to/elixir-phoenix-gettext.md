%{
  title: "Elixir e Phoenix (Gettext)",
  summary:
    "Configure a tradução Gettext, preserve metadados do catálogo e reduza conflitos de mesclagem.",
  category: "passo a passo",
  section: "ecosystems",
  order: 1
}
---

Use este guia para conectar um aplicativo Elixir ou Phoenix existente usando [Gettext](https://hexdocs.pm/gettext/) ao Glossia e manter seus catálogos amigáveis para mesclagem. Execute comandos Mix a partir do diretório contendo `mix.exs`.

## ## 1. Configure extração determinística

Adicione estas opções à sua configuração `project/0` existente em `mix.exs`:

```elixir
def project do
  [
    # Keep the application's other project options here.
    gettext: [
      write_reference_line_numbers: false,
      sort_by_msgid: :case_sensitive
    ]
  ]
end
```

Mantenha quaisquer outras opções Gettext que você já utiliza. `sort_by_msgid: :case_sensitive` é suportado pela versão Gettext usada pelo Glossia; verifique as [opções de extração](https://hexdocs.pm/gettext/Mix.Tasks.Gettext.Extract.html) da sua dependência ao aplicar isso a outro projeto.

Regenere os modelos e arquivos de local:

```sh
mix gettext.extract --merge
```

Revise e comite esta normalização de uma única vez separadamente das mudanças de redação. A ordem das mensagens deve mudar, não as traduções existentes. Coordene esta normalização com pull requests abertos para que seus catálogos possam ser atualizados para a mesma ordem.

A ordenação coloca novas mensagens independentes em suas posições canônicas em vez de anexar cada adição ao final do arquivo. Omitir números de referência de linha evita diferenças não relacionadas quando o código se move; referências de arquivo de origem permanecem. Estas opções reduzem conflitos, mas não podem eliminar conflitos sobre a mesma mensagem ou garantir que cada par de inserções seja mesclado automaticamente.

## ## 2. Traduza modelos, não o código de aplicação

Crie um `L10N.md` ao lado de `mix.exs`, ou adicione os mapeamentos a seguir à sua configuração existente:

```yaml
---
source_language: en
sources:
  "priv/gettext/default.pot": "priv/gettext/{locale}/LC_MESSAGES"
  "priv/gettext/errors.pot": "priv/gettext/{locale}/LC_MESSAGES"
targets:
  - es
  - fr
---

Translate user-facing messages naturally and preserve all Gettext metadata.
Keep interpolation placeholders unchanged, including their names and syntax.
```

Inclua apenas domínios presentes no aplicativo. Adicione um mapeamento para cada domínio adicional, como `dashboard_projects.pot`. O destino é um diretório: o manipulador de objetos portáteis escreve `default.po`, `errors.po` e outros nomes de arquivo de domínio correspondentes ali.

Use `.pot` como fontes e arquivos de local `.po` como saídas. Não use um arquivo de local traduzido como a fonte para outros arquivos de local. Veja a [referência L10N.md](/docs/reference/l10n-md) para configurações aninhadas e o [tutorial de início rápido](/docs/tutorials/getting-started) para conectar o repositório ao Glossia.

## ## 3. Extração antes de publicar mudanças de fonte

Quando uma pull request altera uma chamada `gettext`, `dgettext`, ou `ngettext`:

1. Atualize o código do aplicativo.
2. Execute `mix gettext.extract --merge`.
3. Revise as diferenças do modelo e dos arquivos de local junto com a mudança de código.
4. Comite as mudanças geradas antes de mesclar a pull request.

Após a mesclagem das mudanças de fonte, o Glossia traduz os modelos atualizados e publica as mudanças de local em uma pull request de tradução. Revise essas traduções através do processo normal do repositório.

Mantenha `msgid` e `msgctxt` como identificadores de fonte. Traduza os valores `msgstr`, incluindo as variantes de plural necessárias. Preserve espaços reservados de interpolação, cabeçalhos de forma plural, referências de fonte, comentários do tradutor e flags. Uma entrada `fuzzy` precisa revisão: não remova a flag apenas para fazer uma verificação passar, e não assuma que sua tradução anterior esteja correta para uma mensagem alterada.

## ## 4. Valide mudanças de catálogo em CI

Execute:

```sh
mix gettext.extract --merge --check-up-to-date
mix compile --warnings-as-errors
```

A verificação de extração detecta modelos ou arquivos de local que não coincidem mais com a fonte do aplicativo. A compilação verifica se o Gettext pode compilar os catálogos. Nenhum destes comandos verifica qualidade linguística ou comprova que todas as mensagens tenham uma tradução revisada.

Se a extração relatar arquivos desatualizados, regenere localmente, revise a diferença e comite-a. Não contorne a verificação ou reescreva modelos repetidamente no trabalhador de tradução para esconder uma desajuste de fonte.

## ## 5. Resolva conflitos de catálogo por identidade de mensagem

Ao atualizar um ramo a partir do ramo padrão:

1. Resolva conflitos de fonte de aplicativo primeiro, preservando o texto da UI pretendido.
2. Reconcilie entradas de catálogo de ambos os ramos usando seu contexto e identidade de mensagem de fonte, incluindo identificadores de plural onde presente. Preserve traduções existentes, comentários, flags e formas de plural; remova marcadores de conflito e entradas duplicadas antes de executar o analisador.
3. Execute `mix gettext.extract --merge` contra a fonte resolvida.
4. Execute as verificações de CI acima e revise a diferença resultante do catálogo.

Não resolva um conflito de catálogo aceitando cegamente um lado inteiro, habilitando um driver de mesclagem de texto-união ou concatenando os catálogos. Essas abordagens podem perder traduções válidas, duplicar identificadores ou deixar um arquivo inválido. Para conflitos recorrentes, adicione um teste de regressão que gere catálogos em dois ramos com novas mensagens diferentes e verifique que o Git mescla tanto o modelo quanto o catálogo traduzido sem perder entradas.
