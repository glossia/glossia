%{
  title: "Modelos de conta",
  summary:
    "Por que os provedores de modelo são configurados uma vez por conta e referenciados por handle.",
  category: "explicação",
  section: "platform",
  order: 2
}
---

O Glossia separa instruções de repositório das credenciais de provedor-modelo. Repositórios descrevem o que deve ser traduzido, enquanto contas decidem qual [grande modelo de linguagem](https://en.wikipedia.org/wiki/Large_language_model) executa o trabalho.

## Por que os modelos pertencem às contas

Uma equipe frequentemente traduz vários repositórios com a mesma relação do provedor. Modelos com escopo da conta permitem que administradores rotacionem uma chave de provedor ou alternem o modelo subjacente uma vez sem editar todos os repositórios.

Essa lacuna também mantém credenciais fora do controle de versão. Um repositório contém um manipulador legível como `translation-default`, não a chave do provedor.

## Manipuladores fornecem intenção estável

O campo `model` em `L10N.md` refere-se a um manipulador de modelo de conta:

```yaml
model: translation-default
```

O manipulador expressa a intenção do repositório. Um administrador pode atualizar posteriormente qual modelo de provedor esse manipulador seleciona, enquanto a configuração do repositório permanece estável.

## Como vários modelos são usados

O Glossia usa um modelo **gerativo** configurado para cada tradução de documento. Adicionar vários modelos não cria um ensemble, uma cadeia de retorno ou um nível de qualidade automático. O autor do repositório escolhe seu propósito através de manipuladores estáveis como `translation-default`, `long-form`, ou `japanese-specialist`.

A seleção segue a hierarquia de contexto para o documento e localização-alvo:

1. O arquivo `L10N/<locale>.md` mais próximo que declara `model` vence para essa localização.
2. Caso contrário, o arquivo `L10N.md` mais próximo que declara `model` vence para seu diretório.
3. Configurações pai `L10N.md` são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um manipulador, o Glossia usa o modelo gerativo padrão da conta.

Um manipulador configurado explicitamente deve existir. O Glossia relata um erro para um manipulador desconhecido em vez de silenciosamente alternar para o padrão da conta.

## Seleção padrão

O projeto precisa de um modelo antes que um repositório tenha seu próprio `L10N.md`. Portanto, o Glossia seleciona o padrão da conta. O primeiro modelo adicionado a cada categoria se torna o padrão dessa categoria, e um administrador pode tornar outro modelo padrão da sua página de configurações.

Uma vez que um repositório tem `L10N.md`, usar um manipulador explícito torna sua escolha clara para revisores. Omitir `model` mantém o repositório no padrão da conta.

## Modelos gerativos e de decisão

Configurações de modelo têm duas categorias:

- **Gerativo** modelos escrevem traduções e impulsionam configuração de projeto. Manipuladores de modelo de repositório e regras de roteamento de localização selecionam apenas esta categoria.
- **Decisão** modelos avaliam traduções contra um rubrica de qualidade fixa. Quando uma conta tem um modelo de decisão, seu modelo de decisão padrão verifica automaticamente cada documento de repositório traduzido após validação estrutural e traduções completas de documento único a partir do endpoint de conteúdo. Solicitações fragmentadas são primitivos de geração; execuções de repositório avaliam seu output montado.

As categorias têm padrões independentes. Adicionar Jev nunca altera o modelo que escreve suas traduções. O primeiro modelo de decisão habilita avaliação para execuções subsequentes de tradução; deletar o último desabilita avaliação. Contas sem modelos de decisão mantêm seu comportamento existente.

O Glossia atualmente suporta [TypeSafe Jev](https://docs.typesafe.ai/introduction) como provedor de decisão. Jev retorna escolhas e pontuações pré-definidas em vez de prosa. O Glossia converte escolhas de fraqueza em dicas de correção, sem apresentá-las como erros localizados ou independentemente verificados.

## Verificações de qualidade e revisões

O avaliador recebe origem, tradução, localização-alvo, formato de conteúdo, instruções de projeto e contexto de organização resolvido. Ele avalia preservação de significado, completude, terminologia, fluência, coerência de documento, ajuste de propósito e público, e adequação da localização. Voz e registro são avaliados quando orientação de voz, projeto ou documento está disponível.

Cada dimensão deve atingir o limite de pontuação mínima configurado, que padrão para 7 de 10. Um erro importante ou crítico sempre solicita correção, independentemente da pontuação. Confiança está incluída em eventos de avaliação em tempo real e não altera aceitação. Estes eventos atualmente não são retidos ou exibidos no dashboard. Um limite de 10 exige pontuação ponderada perfeita e geralmente é muito estrito.

Dimensões falhas alimentam suas dicas de correção pré-definidas para a próxima tentativa de tradução. A configuração existente do repositório `retries` delimita essas revisões; o endpoint de conteúdo permite três retentativas de correção, configurável de zero a três com seu `retries` campo. O documento revisado completo passa verificações estruturais e avaliação de qualidade novamente antes de ser aceito.

Falhas transitórias de provedor retentam com backoff exponencial até três vezes; credenciais inválidas e respostas malformadas falham imediatamente. Falhas de provedor esgotadas param tradução do arquivo; output não verificado nunca é aceito. Avaliações usam documentos completos, e input de avaliação excessivo é rejeitado em vez de truncado. Input serializado é limitado conservadoramente a 30.000 bytes para estado mais a pergunta mais longa, e 60.000 bytes na requisição completa, para permanecer dentro [limites de contexto do Jev](https://docs.typesafe.ai/models). Pontuações automatizadas são julgamentos de modelo e ainda requerem calibração contra revisão humana bilíngue.

Configuração do avaliador e versão do rubrica participam de bloqueios de tradução. Habilitar avaliação, mudar modelos ou limites, ou remover avaliação torna traduções anteriores obsoletas para a próxima execução. Chaves de provedor são excluídas de bloqueios.

## A lacuna de revisão humana

Output do modelo é trabalho proposto, não uma mesclagem automática. Configuração e atividade de tradução permanece visível no Glossia, enquanto mudanças de repositório são publicadas através de uma pull request para a equipe revisar. Isso preserva o mesmo limite de qualidade e propriedade que as equipes já usam para código.
