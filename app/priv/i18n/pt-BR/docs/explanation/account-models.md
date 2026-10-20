%{
  title: "Modelos de conta",
  summary:
    "Por que provedores de modelo são configurados uma vez por conta e referenciados por handle.",
  category: "explicação",
  section: "platform",
  order: 2
}
---

O Glossia separa as instruções do repositório das credenciais de provedor de modelo. Os repositórios descrevem o que deve ser traduzido, enquanto as contas decidem qual [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) executa o trabalho.

## Por que os modelos pertencem às contas

Uma equipe frequentemente traduz vários repositórios com a mesma relação de provedor. Modelos com escopo de conta permitem que administradores rotem uma chave de provedor ou altere o modelo subjacente uma vez sem editar todos os repositórios.

Essa fronteira também mantém as credenciais fora do controle de versão. Um repositório contém um identificador legível, como `translation-default`, e não a chave do provedor.

## Identificadores fornecem intenção estável

O campo `model` no `L10N.md` refere-se a um identificador de modelo de conta:

```yaml
model: translation-default
```

O identificador expressa a intenção do repositório. Um administrador pode atualizar posteriormente qual modelo do provedor aquele identificador seleciona, enquanto a configuração do repositório permanece estável.

## Como vários modelos são usados

O Glossia usa um modelo **gerativo** configurado para cada tradução de documento. Adicionar vários modelos não cria um conjunto, uma cadeia de retorno ou um nível automático de qualidade. O autor do repositório escolhe seu propósito através de identificadores estáveis, como `translation-default`, `long-form`, ou `japanese-specialist`.

A seleção segue a hierarquia de contexto para o documento e a localização de destino:

1. O arquivo `L10N/<locale>.md` mais próximo que declara `model` vence para essa localização.
2. Caso contrário, o arquivo `L10N.md` mais próximo que declara `model` vence para seu diretório.
3. Configurações de `L10N.md` do pai são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um identificador, o Glossia usa o modelo gerativo padrão da conta.

Um identificador configurado explicitamente deve existir. O Glossia relata um erro para um identificador desconhecido em vez de silenciosamente alternar para o padrão da conta.

## Seleção padrão

O setup do projeto precisa de um modelo antes que um repositório tenha seu próprio `L10N.md`. O Glossia, portanto, seleciona o padrão da conta. O primeiro modelo adicionado a cada categoria torna-se o padrão dessa categoria, e um administrador pode tornar outro modelo o padrão a partir de sua página de configurações.

Assim que um repositório tem `L10N.md`, usar um identificador explícito torna sua escolha clara para revisores. Omitir `model` mantém o repositório no padrão da conta.

## Modelos gerativos e de decisão

As configurações de modelo têm duas categorias:

- **Gerativo** escreve traduções e alimenta o setup do projeto. Manuseios de modelo de repositório e regras de roteamento de localização selecionam apenas esta categoria.
- **Decisão** avaliam traduções contra uma rubrica de qualidade fixa. Quando uma conta tem um modelo de decisão, seu modelo de decisão padrão verifica automaticamente cada documento do repositório traduzido após a validação estrutural e as traduções completas, de documento único, provenientes do endpoint de conteúdo. Solicitações de fragmento são primitivas de geração; execuções do repositório avaliam sua saída criada.

As categorias têm padrões independentes. Adicionar o Jev nunca altera o modelo que escreve suas traduções. O primeiro modelo de decisão habilita a avaliação para execuções subsequentes de tradução; eliminar o último desabilita a avaliação. Contas sem modelos de decisão mantêm seu comportamento existente.

O Glossia atualmente suporta [TypeSafe Jev](https://docs.typesafe.ai/introduction) como um provedor de decisão. O Jev retorna escolhas e pontuações pré-definidas em vez de prosa. O Glossia converte escolhas de fraqueza em dicas de correção, sem apresentá-las como erros localizados ou independentemente verificados.

## Verificações de qualidade e revisões

O avaliador recebe a origem, a tradução, a localização de destino, o formato de conteúdo, as instruções do projeto e o contexto da organização resolvido. Ele avalia a preservação de significado, completude, terminologia, fluência, coerência de documento, adequação de propósito e público, e adequação à localização. Voz e registro são avaliados quando orientação de voz, projeto ou documento está disponível.

Cada dimensão deve alcançar a nota mínima configurada, que padrão para 7 de 10. Um erro importante ou crítico sempre solicita correção, independentemente da nota. Confiança está incluída em eventos de avaliação ao vivo e não altera a aceitação. Esses eventos atualmente não são retidos ou exibidos no painel. Um limiar de 10 exige uma nota ponderada perfeita e geralmente é muito restritivo.

Dimensões falhas alimentam suas dicas de correção pré-definidas na próxima tentativa de tradução. A configuração existente de `retries` do repositório limita essas revisões; o endpoint de conteúdo permite três tentativas de correção, configurável de zero a três com seu campo `retries`. O documento revisado completo passa verificações estruturais e avaliação de qualidade novamente antes de ser aceito.

Falhas transitórias do provedor repetem com backoff exponencial até três vezes; credenciais inválidas e respostas malformadas falham imediatamente. Falhas de provedor exaustadas param a tradução do arquivo; saída não verificada nunca é aceita. Avaliações usam documentos completos, e entrada de avaliação oversized é rejeitada em vez de truncada. Entrada serializada é conservadoramente limitada a 30.000 bytes para estado mais a pergunta mais longa, e 60.000 bytes em toda a solicitação, para ficar dentro dos [limites de contexto do Jev](https://docs.typesafe.ai/models). Pontuações automáticas são julgamentos de modelo e ainda exigem calibração contra revisão humana bilíngue.

A configuração do avaliador e a versão da rubrica participam dos lockfiles de tradução. Habilitar avaliação, alterar modelos ou limiares, ou remover avaliação torna traduções anteriores obsoletas para a próxima execução. Chaves de provedor são excluídas dos lockfiles.

## A fronteira da revisão humana

A saída do modelo é trabalho proposto, não uma mesclagem automática. Atividade de configuração e tradução permanece visível no Glossia, enquanto alterações do repositório são publicadas através de uma pull request para a equipe revisar. Isso preserva a mesma fronteira de qualidade e propriedade que as equipes já usam para código.
