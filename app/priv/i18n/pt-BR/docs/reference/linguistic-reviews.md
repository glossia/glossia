%{
  title: "Revisões linguísticas",
  summary:
    "Decisões humanas vinculadas à fonte, continuações de tradução e orientações do repositório revisadas.",
  category: "referência",
  section: "translation",
  order: 31
}
---

## Escalação

As execuções de tradução do repositório com um modelo de decisão configurado podem solicitar entrada linguística para significado da fonte ausente ou contexto de domínio, diretrizes conflitantes, ou adaptação cultural conseqüente. A baixa confiança por si só não aciona uma pergunta. Os erros corrigíveis a partir do contexto existente utilizam o orçamento de correção comum; falhas de qualidade remanescentes após esse orçamento também podem solicitar entrada. Sem um modelo de decisão, o escalonamento linguístico automático está desabilitado.

Apenas o arquivo ou localidade afetada é suspenso. Seu candidato não aprovado não é publicado. Arquivos independentes completam e podem publicar normalmente. Após a conclusão da publicação, a sessão se torna `awaiting_input` e libera seu runner. Não consome um worker enquanto um humano está respondendo.

Cada escalonamento abre uma **conversa compartilhada no Toki com um objetivo linguístico definido**, vinculada à sessão de tradução. Os participantes discutem o significado, fazem perguntas de acompanhamento e refinam uma decisão proposta. A discussão por si só nunca aprova uma tradução ou escreve contexto de repositório. As conversas comuns no Toki permanecem privadas para seu proprietário, inclusive para administradores.

Todos os colegas atualmente autorizados cujos idiomas fluentes declarados correspondem ao localidade-alvo são convidados para a mesma conversa. A fluência é separada da linguagem de exibição e não concede acesso ao projeto ou permissão para aprovar decisões. Um idioma amplo como `es` corresponde a variantes regionais, como `es-MX`; scripts explícitos incompatíveis não correspondem. Declarações regionais como `zh-TW` usam seu script CLDR costumeiro, enquanto `zh` amplo permanece não restringido por script.

Os participantes elegíveis recebem notificações push genéricas móveis apenas quando optaram por receber; o serviço de entrega verifica atual fluentemente, membros, acesso ao projeto e o objetivo aberto. As notificações abrem a conversa compartilhada. Conversas e aprovações estão disponíveis tanto em aplicativos nativos quanto no painel web. Veja [Notificações push nativas](/docs/reference/native-push-notifications) para configuração de provedor e política de entrega.

## Perfil de idioma fluente

`GET /api/me` inclui `user.fluent_languages`. `PUT /api/me/fluent-languages` requer `user:write` e aceita apenas `{"fluent_languages": ["es", "ar", "zh-Hant"]}`. Ele substitui a lista do usuário autenticado e retorna o envelope do perfil. As tags CLDR BCP47 compatíveis mantêm especificidade explícita de região/escrita e usam maiúsculas canônicas; duplicatas são suprimidas. Um array vazio limpa a fluência. Tags inválidas, campos não relacionados ou mais de 50 entradas submetidas retornam 422. Isso nunca muda o idioma da interface do usuário.

## API de Revisão

`GET /api/:handle/projects/:project/translations/:id/reviews` requer `translation:read` e acesso ao projeto. Ele retorna `{"reviews": [...]}`, com perguntas abertas primeiro e depois as mais antigas, limitado a 500 entradas. Atualize após responder para revelar quaisquer perguntas restantes; o histórico respondido nunca esconde uma pergunta aberta atrás do limite.

Cada revisão inclui `id`, `translation_session_id`, `conversation_id`, `participants` (`id` e nullable `name`), `status`, `source_path`, `output_path`, `locale`, `question`, limitado `source_excerpt` e `translation_excerpt`, `answer`, `guidance`, `context_path`, `resolution_message_id`, `resumed_session_id`, e `inserted_at`. O status é `open`, `answered`, ou `stale`.

Use os endpoints de conversa e mensagem de projeto Toki existentes para discussão. Conversas de objetivo compartilhado aparecem ao lado das conversas privadas do ator no histórico do Toki. Histórias compartilhadas exigem permissão de política de leitura/escrita atual do Toki e acesso de leitura de tradução; histórias comuns permanecem apenas para o proprietário. Mensagens humanas incluem sua identidade de autor, e respostas incluem `status` e `reply_to_id`. O Toki recebe trechos limitados de fonte/candidato e o objetivo, não acesso de escrita ao repositório.

`POST /api/:handle/projects/:project/translations/:id/reviews/:review_id/answer` requer tanto `translation:read` quanto `translation:write`, além de acesso ao projeto:

```json
{
  "resolution_message_id": "019a1c6d-4321-7000-8000-123456789abc",
  "answer": "Branch means a source-control release branch.",
  "guidance": "Use the source-control meaning of branch in release documentation.",
  "context_scope": "locale"
}
```

`resolution_message_id` deve identificar a **resposta** mais recente concluída do assistente na conversa de objetivo, não a pergunta inicial dele. `answer` é a decisão aprovada pelo humano e é obrigatória e não em branco. `guidance` e `context_scope` são opcionais; o escopo padrão é `locale` e também pode ser `project`. Resposta e orientação permitem até 8.000 caracteres e 32.000 bytes UTF-8. A orientação não pode conter comentários reservados de marcador de revisão do Glossia. O servidor escolhe os caminhos do repositório; um caminho fornecido pelo cliente nunca é usado.

Uma resposta bem-sucedida é `{"review": {...}}`. Reexecutar a mesma decisão, mensagem de resolução, orientação e escopo é idempotente. Uma conversa ocupada retorna `409 conversation_busy`; uma mensagem mais recente ou referência de resolução inválida retorna `409 resolution_outdated`. Recarregue e revise a discussão atual antes de aprovar novamente. Uma decisão diferente em um objetivo resolvido retorna `409 already_answered`; aprovar um objetivo cancelado ou substituído retorna `409 stale`. Texto inválido ou escopo indisponível retorna 422. Identificadores ausentes e de projetos estrangeiros retornam 404. Autenticação e autorização normais do projeto se aplicam a cada solicitação, incluindo reexecuções. Objetivos fechados rejeitam novas mensagens de discussão com `409 goal_closed`.

## Continuações e contexto obsoleto

Decisões podem ser aprovadas enquanto o trabalho independente ainda está em execução. Nunca iniciam um segundo runner. Uma vez que o runner foi liberado e todo o objetivo naquela execução foi resolvido, o Glossia filas atomicamente uma sessão de continuação. `resumed_session_id` a identifica; a sessão original permanece histórica `awaiting_input`. Ambos os painéis e conversas nativas vinculam à continuação.

A continuação possui uma identidade de execução fresca e mantém o ramo de publicação de tradução e saídas validadas. Cada resposta se aplica apenas à fonte idêntica e à impressão digital de contexto de tradução resolvida. Alteração na fonte, voz, glossário, modelo ou instruções do repositório impede a reutilização da resposta. Um commit da ramagem padrão mais recente invalida sessões de espera e marca perguntas abertas como obsoletas. O cancelamento também marca perguntas abertas como obsoletas.

## Diretrizes de repositório reutilizáveis

Diretrizes reutilizáveis são uma edição explícita e separada do humano. Uma resposta sozinha não se torna contexto do repositório, e as transcrições de chat privadas nunca são copiadas automaticamente.

locale `locale` direciona o overlay de localidade aplicável, como `L10N/es.md`; project `project` direciona o `L10N.md` aplicável. Arquivos de contexto de escopo existentes são respeitados. Overlays de localidade ausentes recebem seu frontmatter de localidade. Frontmatter e prosa existentes são preservados, e cada decisão é anexada com seu UUID de revisão para proveniência e idempotência.

As diretrizes são propostas no pull request de tradução normal, não escritas silenciosamente na ramagem padrão. O repositório deve ainda corresponder ao digesto de contexto registrado; uma edição conflitante falha na publicação em vez de sobrescrevê-lo. Os caminhos devem ser documentos de localização relativos ao repositório, sem travessia ou links simbólicos. Cada documento de contexto é limitado a 1 MiB. A fusão do pull request torna as diretrizes um contexto de localização comum e versionado para execuções futuras.
