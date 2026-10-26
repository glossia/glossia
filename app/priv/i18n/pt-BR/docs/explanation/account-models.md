%{
  title: "Modelos de conta",
  summary:
    "Por que os provedores de modelo são configurados uma vez por conta e referenciados pelo handle.",
  category: "Explicação",
  section: "platform",
  order: 2
}
---

Glossia separa instruções de repositório de credenciais do provedor de modelos. Repositórios descrevem o que deve ser traduzido, enquanto contas decidem qual [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) executa o trabalho.

## Por que os modelos pertencem às contas

Uma equipe frequentemente traduz vários repositórios com o mesmo relacionamento com o provedor. Modelos escopados à conta permitem que administradores rotacionem uma chave de provedor ou alternem o modelo subjacente uma vez sem editar todos os repositórios.

Esta fronteira também mantém as credenciais fora do controle de versão. Um repositório contém um identificador legível como `translation-default`, e não a chave do provedor.

## Handles fornecem intenção estável

O campo `model` em `L10N.md` refere-se a um handle de modelo de conta:

```yaml
model: translation-default
```

O handle expressa a intenção do repositório. Um administrador pode posteriormente atualizar qual modelo de provedor aquele handle seleciona enquanto a configuração do repositório permanece estável.

## Como vários modelos são usados

Glossia usa um modelo **gerativo** configurado para cada tradução de documento. Adicionar vários modelos não cria um ensemble, uma cadeia de fallback, ou um nível de qualidade automático. O autor do repositório escolhe seu propósito através de handles estáveis como `translation-default`, `long-form`, ou `japanese-specialist`.

A seleção segue a hierarquia de contexto para o documento e o idioma de destino:

1. O arquivo `L10N/<locale>.md` mais próximo que declara `model` vence para esse idioma.
2. Caso contrário, o arquivo `L10N.md` mais próximo que declara `model` vence para seu diretório.
3. Configurações de `L10N.md` pai são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declarar um handle, Glossia usa o modelo gerativo padrão da conta.

Um handle configurado explicitamente deve existir. Glossia reporta um erro para um handle desconhecido em vez de silenciosamente alternar para o modelo padrão da conta.

## Seleção padrão

A configuração do projeto precisa de um modelo antes que um repositório tenha seu próprio `L10N.md`. Glossia, portanto, seleciona o padrão da conta. O primeiro modelo adicionado a cada categoria torna-se o padrão dessa categoria, e um administrador pode tornar outro modelo o padrão em sua página de configurações.

Quando um repositório possui `L10N.md`, usar um handle explícito torna sua escolha clara para os revisores. Omitir `model` mantém o repositório no padrão da conta.

## Modelos gerativos e de decisão

As configurações de modelo têm duas categorias:

- **Gerativo** modelos escrevem traduções e impulsionam a configuração do projeto. Handles de modelo de repositório e regras de roteamento de idioma selecionam apenas esta categoria.
- **Decisão** modelos avaliam traduções contra uma rubrica de qualidade fixa. Quando uma conta possui um modelo de decisão, seu modelo de decisão padrão verifica automaticamente cada documento de repositório traduzido após validação estrutural e traduções completas de documento único da ponta de conteúdo. Solicitações de fragmento são primitivos de geração; execuções de repositório avaliam sua saída montada.

As categorias têm padrões independentes. Adicionar Jev nunca altera o modelo que escreve suas traduções. O primeiro modelo de decisão habilita avaliação para execuções subsequentes de tradução; deletar o último desabilita avaliação. Contas sem modelos de decisão mantêm seu comportamento existente.

Glossia atualmente suporta [TypeSafe Jev](https://docs.typesafe.ai/introduction) como um provedor de decisão. Jev retorna escolhas e pontuações pré-definidas em vez de prosa. Glossia converte escolhas de fraqueza em dicas de correção, sem apresentá-las como erros localizados ou independentemente verificados.

## Verificações de qualidade e revisões

O avaliador recebe a fonte, tradução, idioma de destino, formato de conteúdo, instruções de projeto e contexto de organização resolvido. Ele avalia preservação de significado, completude, terminologia, fluência, coerência do documento, alcance e adequação de público, e adequação de idioma. Voz e registro são avaliados quando há guia de voz, projeto ou documento.

Cada dimensão deve alcançar a pontuação mínima configurada, que é padrão para 7 de 10. Um erro maior ou crítico sempre solicita correção, independentemente da pontuação. A confiança está incluída nos eventos de avaliação ao vivo e não altera a aceitação. Esses eventos atualmente não são retidos ou exibidos no painel. Um limite de 10 exige uma pontuação ponderada perfeita e é geralmente muito estrito.

Dimensões falhas alimentam suas dicas de correção pré-definidas na próxima tentativa de tradução. A configuração existente do repositório `retries` limita essas revisões; a ponta de conteúdo permite três tentativas de correção, configurável de zero a três com seu campo `retries`. O documento revisado completo passa novamente nas verificações estruturais e avaliação de qualidade antes de ser aceito.

Falhas de provedor transientes repetem com backoff exponencial até três vezes; credenciais inválidas e respostas malformadas falham imediatamente. Falhas de provedor exaustadas param a tradução do arquivo; saída não verificada nunca é aceita. Avaliações usam documentos completos, e entrada de avaliação em tamanho excessivo é rejeitada em vez de truncada. Entrada serializada é conservadoramente limitada a 30.000 bytes para estado mais a pergunta mais longa, e 60.000 bytes através da solicitação completa, para ficar dentro [dos limites de contexto do Jev](https://docs.typesafe.ai/models). Pontuações automatizadas são julgamentos de modelo e ainda requerem calibração contra revisão humana bilíngue.

A configuração do avaliador e a versão da rubrica participam dos arquivos de bloqueio de tradução. Habilitar avaliação, alterar modelos ou limites, ou remover avaliação torna traduções anteriores obsoletas para a próxima execução. Chaves de provedor são excluídas dos lockfiles.

## A fronteira da revisão humana

A saída do modelo é trabalho proposto, não uma mesclagem automática. Atividades de configuração e tradução permanecem visíveis no Glossia, enquanto alterações do repositório são publicadas através de uma pull request para a equipe revisar. Isso preserva a mesma fronteira de qualidade e propriedade que as equipes já usam para código.
