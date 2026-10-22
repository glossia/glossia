%{
  title: "Modelos de conta",
  summary:
    "Por que os provedores de modelos são configurados uma vez por conta e referenciados por handle.",
  category: "Explicação",
  section: "platform",
  order: 2
}
---

O Glossia separa as instruções do repositório das credenciais do provedor de modelo. Repositórios descrevem o que deve ser traduzido, enquanto as contas decidem qual [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) executa o trabalho.

## Por que os modelos pertencem às contas

Uma equipe muitas vezes traduz vários repositórios com a mesma relação de provedor. Modelos com escopo de conta permitem que administradores rotacionem a chave do provedor ou troquem o modelo subjacente uma única vez sem editar todos os repositórios.

Essa fronteira também mantém as credenciais fora do controle de código-fonte. Um repositório contém um identificador legível, como `translation-default`, e não a chave do provedor.

## Identificadores fornecem intenção estável

O campo `model` no `L10N.md` refere-se a um identificador de modelo da conta:

```yaml
model: translation-default
```

O identificador expressa a intenção do repositório. Um administrador pode atualizar posteriormente qual modelo do provedor esse identificador seleciona, enquanto a configuração do repositório permanece estável.

## Como vários modelos são usados

O Glossia usa um modelo **gerativo** configurado para cada tradução de documento. Adicionar vários modelos não cria um conjunto, uma cadeia de planos de backup, nem um nível de qualidade automático. O autor do repositório escolhe seu propósito através de identificadores estáveis como `translation-default`, `long-form`, ou `japanese-specialist`.

A seleção segue a hierarquia de contexto do documento e do local-alvo:

1. O arquivo `L10N/<locale>.md` mais próximo que declara `model` vence para esse local.
2. Caso contrário, o arquivo `L10N.md` mais próximo que declara `model` vence para seu diretório.
3. As configurações `L10N.md` do pai são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um identificador, o Glossia usa o modelo gerativo padrão da conta.

Um identificador configurado explicitamente deve existir. O Glossia relata um erro para um identificador desconhecido em vez de silenciosamente alternar para o padrão da conta.

## Seleção padrão

O setup do projeto precisa de um modelo antes que um repositório tenha o seu próprio `L10N.md`. Portanto, o Glossia seleciona o padrão da conta. O primeiro modelo adicionado a cada categoria torna-se o padrão dessa categoria, e um administrador pode fazer outro modelo o padrão em sua página de configurações.

Uma vez que um repositório tem `L10N.md`, usar um identificador explícito torna sua escolha clara para revisores. Omitir `model` mantém o repositório no padrão da conta.

## Modelos gerativos e de decisão

As configurações de modelo têm duas categorias:

- Os modelos **Gerativo** escrevem traduções e alimentam o setup do projeto. Os identificadores de modelo do repositório e as regras de roteamento de local selecionam apenas esta categoria.
- Os modelos **Decisão** avaliam traduções contra uma rubrica fixa de qualidade. Quando uma conta tem um modelo de decisão, seu modelo de decisão padrão verifica automaticamente cada documento de repositório traduzido após a validação estrutural e traduções completas, de um único documento, do endpoint de conteúdo. As solicitações de fragmento são primitivas de geração; as execuções do repositório avaliam sua saída montada.

As categorias têm padrões independentes. Adicionar o Jev nunca altera o modelo que escreve suas traduções. O primeiro modelo de decisão habilita a avaliação para execuções subsequentes de tradução; deletar o último desabilita a avaliação. Contas sem modelos de decisão mantêm seu comportamento existente.

O Glossia atualmente suporta [TypeSafe Jev](https://docs.typesafe.ai/introduction) como um provedor de decisão. O Jev devolve escolhas pré-definidas e pontuações em vez de prosa. O Glossia converte escolhas de fraqueza em dicas de correção, sem apresentá-las como erros localizados ou verificados independentemente.

## Verificações de qualidade e revisões

O avaliador recebe a origem, a tradução, o local-alvo, o formato de conteúdo, as instruções do projeto e o contexto da organização resolvido. Ele avalia a preservação de significado, completude, terminologia, fluência, coerência do documento, adequação de propósito e público, e apropriação do local. A voz e o registro são avaliados quando orientações de voz, projeto ou documento estão disponíveis.

Cada dimensão deve atingir a pontuação mínima configurada, que é 7 em 10 por padrão. Um erro de grandeza ou crítico sempre solicita correção, independentemente da pontuação. A confidência é incluída em eventos de avaliação ao vivo e não altera a aceitação. Estes eventos atualmente não são retidos ou exibidos no dashboard. Um limite de 10 requer uma pontuação ponderada perfeita e geralmente é muito restritivo.

As dimensões falhas fornecem suas dicas de correção pré-definidas para o próximo tentativo de tradução. A configuração `retries` existente do repositório limita essas revisões; o endpoint de conteúdo permite três repetições de correção, configuráveis de zero a três com seu campo `retries`. O documento revisado completo passa novamente na verificação estrutural e avaliação de qualidade antes de ser aceito.

Falhas transitórias de provedor tentam novamente com backoff exponencial até três vezes; credenciais inválidas e respostas mal formatadas falham imediatamente. Falhas de provedor esgotadas param a tradução do arquivo; saída não verificada nunca é aceita. Avaliações usam documentos completos, e entrada de avaliação de tamanho excessivo é rejeitada em vez de truncada. A entrada serializada é conservadoramente limitada a 30.000 bytes para estado mais a pergunta mais longa, e 60.000 bytes através da solicitação completa, para permanecer dentro dos [limites de contexto do Jev](https://docs.typesafe.ai/models). Pontuações automatizadas são julgamentos de modelo e ainda requerem calibração contra revisão bilíngue humana.

A configuração do avaliador e a versão da rubrica participam dos arquivos de bloqueio de tradução. Habilitar avaliação, alterar modelos ou limites, ou remover avaliação torna as traduções anteriores obsoletas para a próxima execução. As chaves do provedor são excluídas dos arquivos de bloqueio.

## O limite de revisão humana

A saída do modelo é trabalho proposto, não uma mesclagem automática. A atividade de setup e tradução permanece visível no Glossia, enquanto as alterações do repositório são publicadas através de um pull request para a equipe revisar. Isso preserva a mesma fronteira de qualidade e propriedade que as equipes já usam para código.
