%{
  title: "Modelos de conta",
  summary:
    "Por que os provedores de modelos são configurados uma vez por conta e referenciados por handle.",
  category: "Explicação",
  section: "platform",
  order: 2
}
---

O Glossia separa instruções de repositório das credenciais do provedor-modelo. Os repositórios descrevem o que deve ser traduzido, enquanto as contas decidem qual [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) executa o trabalho.

## Por que os modelos pertencem às contas

Uma equipe frequentemente traduz vários repositórios com a mesma relação de provedor. Modelos limitados à conta permitem que administradores rotacionem uma chave de provedor ou alternem o modelo subjacente uma vez sem editar todos os repositórios.

Esta fronteira também mantém as credenciais fora do controle de código-fonte. Um repositório contém um manipulador legível como `translation-default`, não a chave do provedor.

## Manipuladores fornecem intenção estável

O campo `model` em `L10N.md` refere-se a um manipulador de modelo de conta:

```yaml
model: translation-default
```

O manipulador expressa a intenção do repositório. Um administrador pode atualizar posteriormente qual modelo de provedor esse manipulador seleciona enquanto a configuração do repositório permanece estável.

## Como vários modelos são usados

O Glossia usa um modelo configurado **gerativo** para cada tradução de documento. Adicionar vários modelos não cria um conjunto, uma cadeia de fallback ou um nível de qualidade automático. O autor do repositório escolhe seu propósito através de manipuladores estáveis como `translation-default`, `long-form`, ou `japanese-specialist`.

A seleção segue a hierarquia de contexto para o documento e o locale de destino:

1. O arquivo `L10N/<locale>.md` mais próximo que declara `model` vence para esse locale.
2. Caso contrário, o arquivo `L10N.md` mais próximo que declara `model` vence para seu diretório.
3. As configurações do `L10N.md` pai são herdadas quando um arquivo mais próximo não declarar um modelo.
4. Quando nenhum arquivo de contexto aplicável declarar um manipulador, o Glossia usa o modelo gerativo padrão da conta.

Um manipulador configurado explicitamente deve existir. O Glossia reporta um erro para um manipulador desconhecido em vez de silenciosamente alternar para o padrão da conta.

## Seleção padrão

A configuração do projeto precisa de um modelo antes que um repositório tenha seu próprio `L10N.md`. Portanto, o Glossia seleciona o padrão da conta. O primeiro modelo adicionado a cada categoria torna-se o padrão dessa categoria, e um administrador pode tornar outro modelo o padrão em sua página de configurações.

Uma vez que um repositório tem `L10N.md`, usar um manipulador explícito torna sua escolha clara para revisores. Omitir `model` mantém o repositório no padrão da conta.

## Modelos gerativos e decisivos

As configurações de modelo têm duas categorias:

- **Gerativo** escreve traduções e ativa a configuração de projeto. Os manipuladores de modelo de repositório e as regras de roteamento de locale selecionam apenas esta categoria.
- **Decisivo** avalia traduções contra um quadro de qualidade fixo. Quando uma conta tem um modelo decisório, seu modelo decisório padrão verifica automaticamente cada documento traduzido do repositório após validação estrutural e traduções completas, de arquivo único, do endpoint de conteúdo. Solicitações fragmentadas são primitivas de geração; execuções de repositório avaliam seu output montado.

As categorias têm padrões independentes. Adicionar o Jev nunca altera o modelo que escreve suas traduções. O primeiro modelo decisório habilita avaliação para execuções subsequentes de tradução; deletar o último desabilita a avaliação. Contas sem modelos decisórios mantêm seu comportamento existente.

O Glossia atualmente suporta [TypeSafe Jev](https://docs.typesafe.ai/introduction) como um provedor decisório. O Jev retorna escolhas e pontuações predefinidas em vez de texto corrido. O Glossia converte escolhas de fraqueza em dicas de correção, sem apresentá-las como erros localizados ou verificados independentemente.

## Verificações de qualidade e revisões

O avaliador recebe o texto fonte, tradução, locale de destino, formato de conteúdo, instruções do projeto e contexto de organização resolvido. Ele avalia preservação de significado, completude, terminologia, fluência, coerência de documento, adequação de propósito e público, e adequação de locale. Voz e registro são avaliados quando orientação de voz, projeto ou documento está disponível.

Cada dimensão deve alcançar a pontuação mínima configurada, que por padrão é 7 de 10. Um erro grande ou crítico sempre solicita correção, independentemente da pontuação. A confiança está incluída em eventos de avaliação ao vivo e não altera a aceitação. Esses eventos atualmente não são retidos ou exibidos no painel. Um limite de 10 requer uma pontuação ponderada perfeita e geralmente é excessivamente rigoroso.

Dimensões falhas alimentam suas dicas de correção predefinidas na próxima tentativa de tradução. A configuração `retries` existente do repositório delimita essas revisões; o endpoint de conteúdo permite três tentativas de correção, configuráveis de zero a três com seu `retries`. O documento revisado completo passa nas verificações estruturais e na avaliação de qualidade novamente antes de ser aceito.

Falhas do provedor transitórias são rejeitadas com backoff exponencial até três vezes; credenciais inválidas e respostas malformadas falham imediatamente. Falhas do provedor esgotadas param a tradução do arquivo; output não verificado nunca é aceito. Avaliações usam documentos completos, e entrada de avaliação excessiva é rejeitada em vez de truncada. A entrada serializada é conservadoramente limitada a 30.000 bytes para estado mais a pergunta mais longa, e 60.000 bytes ao longo da solicitação completa, para permanecer dentro dos [limites de contexto do Jev](https://docs.typesafe.ai/models). Pontuações automatizadas são julgamentos de modelo e ainda requerem calibração contra revisão humana bilíngue.

A configuração do avaliador e a versão do quadro participam dos arquivos de bloqueio de tradução. Habilitar avaliação, alterar modelos ou limites, ou remover avaliação torna traduções anteriores desatualizadas para a próxima execução. Chaves de provedor são excluídas dos arquivos de bloqueio.

## A fronteira de revisão humana

O output do modelo é trabalho proposto, não uma mesclagem automática. A atividade de configuração e tradução permanece visível no Glossia, enquanto alterações do repositório são publicadas através de um pull request para a equipe revisar. Isso preserva a mesma fronteira de qualidade e propriedade que as equipes já usam para código.
