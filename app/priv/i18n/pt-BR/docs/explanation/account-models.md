%{
  title: "Modelos de conta",
  summary:
    "Por que os provedores de modelos são configurados uma vez por conta e referenciados pelo handle.",
  category: "Explicação",
  section: "platform",
  order: 2
}
---
O Glossia separa as instruções do repositório das credenciais do provedor de modelos. Os repositórios descrevem o que deve ser traduzido, enquanto as contas decidem qual [modelo de linguagem grande](https://en.wikipedia.org/wiki/Large_language_model) realiza o trabalho.

## Por que os modelos pertencem às contas

Equipes frequentemente traduzem vários repositórios com a mesma relação de provedor. Modelos com escopo de conta permitem que administradores rotacionem uma chave de provedor ou alterem o modelo subjacente uma vez sem editar todos os repositórios.

Essa fronteira também mantém as credenciais fora do controle de versão. Um repositório contém um identificador legível, tal como `translation-default`, e não a chave do provedor.

## Identificadores fornecem intenção estável

O `model` campo em `L10N.md` refere-se a um handle do modelo de conta:

```yaml
model: translation-default
```

O handle expressa a intenção do repositório. Um administrador pode posteriormente atualizar qual modelo de provedor o handle seleciona enquanto a configuração do repositório permanece estável.

## Como vários modelos são utilizados.

O Glossia usa um configurado **gerativo** modelo para cada tradução de documento. Adicionar vários modelos não cria um conjunto, uma cadeia de fallback nem um nível de qualidade automático. O autor do repositório escolhe seus objetivos através de handles estáveis como `translation-default`, `long-form`, ou `japanese-specialist`.

Seleção segue a hierarquia de contexto do documento e do idioma de destino:

1. O mais próximo `L10N/<locale>.md` arquivo que declara `model` vence para essa localidade.
2. Caso contrário, o mais próximo `L10N.md` arquivo que declara `model` prevalece para o seu diretório.
3. Pai `L10N.md` as configurações são herdadas quando um arquivo mais próximo não declara um modelo.
4. Quando nenhum arquivo de contexto aplicável declara um handle, Glossia usa o modelo gerativo padrão da conta.

Um handle configurado explicitamente deve existir. Glossia exibe um erro para um handle desconhecido em vez de alternar silenciosamente para o padrão da conta.

## Seleção padrão

A configuração do projeto precisa de um modelo antes que um repositório tenha o seu próprio. `L10N.md`. Portanto, o Glossia seleciona o padrão da conta. O primeiro modelo adicionado a cada categoria torna-se o padrão dessa categoria e um administrador pode definir outro modelo como padrão na página de configurações.

Assim que um repositório possui `L10N.md`, ao utilizar um identificador explícito, torna sua escolha clara para os revisores. Omitindo `model` mantém o repositório no padrão da conta.

## Modelos generativos e de decisão

As configurações de modelo possuem duas categorias:

- **Generativos** Os modelos escrevem traduções e habilitam a configuração do projeto. Os identificadores de modelo de repositório e as regras de roteamento de localização selecionam apenas esta categoria.
- **Decisão** os modelos avaliam as traduções contra uma rubrica de qualidade fixa. Quando uma conta possui um modelo de decisão, seu modelo de decisão padrão verifica automaticamente cada documento do repositório traduzido após a validação estrutural e traduções completas de documento único provenientes do endpoint de conteúdo. Solicitações fragmentadas são primitivas de geração; execuções do repositório avaliam sua saída montada.

As categorias possuem padrões independentes. Adicionar Jev nunca altera o modelo que escreve suas traduções. O primeiro modelo de decisão habilita a avaliação para execuções subsequentes de tradução; excluir o último desabilita a avaliação. As contas sem modelos de decisão mantêm seu comportamento existente.

O Glossia atualmente suporta [TypeSafe Jev](https://docs.typesafe.ai/introduction) como provedor de decisões. O Jev retorna escolhas e pontuações predefinidas em vez de prosa. O Glossia converte escolhas de fraqueza em dicas de correção, sem apresentá-las como erros localizados ou independentemente verificados.

## Verificações de qualidade e revisões

O avaliador recebe a fonte, a tradução, o idioma-alvo, o formato de conteúdo, as instruções do projeto e o contexto organizacional resolvido. Ele avalia a preservação de significado, completude, terminologia, fluência, coerência do documento, adequação ao propósito e ao público, e adequação ao idioma. A voz e o registro são avaliados quando há orientação de voz, de projeto ou de documento disponíveis.

Cada dimensão deve atingir a pontuação mínima configurada, que por padrão é 7 de 10. Um erro severo ou crítico sempre solicita correção, independentemente da pontuação. A confiança está incluída nos eventos de avaliação em tempo real e não altera a aceitação. Estes eventos, atualmente, não são armazenados nem exibidos no painel. Um limite de 10 exige uma pontuação ponderada perfeita e geralmente é muito rigoroso.

As dimensões falhas fornecem suas dicas de correção predefinidas para a próxima tentativa de tradução. A configuração existente `retries` do repositório limita estas revisões; o endpoint de conteúdo permite três tentativas de correção, configuráveis de zero a três com seu campo `retries`. O documento revisado completo passa novamente pelas verificações estruturais e avaliação de qualidade antes de ser aceito.

Falhas transitórias do provedor tentam novamente com recuo exponencial até três vezes; credenciais inválidas e respostas malformadas falham imediatamente. Falhas de provedor esgotadas interrompem a tradução do arquivo; saída não verificada nunca é aceita. As avaliações usam documentos completos, e entrada de avaliação excessivamente grande é rejeitada em vez de truncada. A entrada serializada é conservadoramente limitada a 30.000 bytes para o estado mais a pergunta mais longa, e 60.000 bytes ao longo de toda a solicitação, para se manter nos [limites de contexto do Jev](https://docs.typesafe.ai/models). Pontuações automatizadas são julgamentos do modelo e ainda exigem calibração em comparação à revisão humana bilíngue.

A configuração do avaliador e a versão da rubrica participam nos arquivos de bloqueio de tradução. Ativar a avaliação, alterar modelos ou limites, ou remover a avaliação torna as traduções anteriores obsoletas para a próxima execução. As chaves dos provedores são excluídas dos arquivos de bloqueio.

## O limite da revisão humana

A saída do modelo é trabalho proposto, não uma mesclagem automática. A atividade de configuração e tradução permanece visível no Glossia, enquanto as alterações do repositório são publicadas por meio de um pull request para a equipe revisar. Isso preserva o mesmo limite de qualidade e propriedade que as equipes já usam para o código.