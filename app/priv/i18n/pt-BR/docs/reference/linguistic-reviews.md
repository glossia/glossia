%{
  title: "Revisões linguísticas",
  summary:
    "Decisões humanas vinculadas à fonte, continuações de tradução e orientações revisadas do repositório.",
  category: "referência",
  section: "translation",
  order: 31
}
---

## Escalonamento

Execuções de tradução de repositório com um modelo de decisão configurado podem solicitar input lingüístico para significado fonte ausente ou contexto de domínio, orientação conflitante, ou adaptação cultural consequente. Apenas a baixa confiança não aciona uma questão. Erros corrigíveis a partir do contexto existente consomem o orçamento de correção ordinário; falhas de qualidade que persistem após esse orçamento podem também solicitar input. Sem um modelo de decisão, o escalonamento lingüístico automático está desativado.

Apenas o arquivo ou/locale afetado pára. Seu candidato não aprovado não é publicado. Arquivos independentes completam e podem publicar normalmente. Após a conclusão da publicação, a sessão adota `awaiting_input` e libera seu runner. Ela não consome um worker enquanto um humano está respondendo.

Cada escalonação abre uma **conversa compartilhada Toki com um objetivo lingüístico definido**, vinculada à sessão de tradução. Participantes discutem o significado, exigem perguntas de acompanhamento e refinam uma decisão proposta. A discussão sozinha nunca aprova uma tradução ou escreve contexto de repositório. Conversas Toki comuns permanecem privadas para seu proprietário, incluindo administradores.

Todos os colegas autorizados atualmente cujas linguagens fluentes declaradas correspondem ao local-alvo são convidados para a mesma conversa. A fluência é separada da linguagem de exibição e não concede acesso ao projeto ou permissão para aprovar decisões. Uma linguagem ampla como `es` coincide com variantes regionais como `es-MX`; scripts explícitos incompatíveis não correspondem. Declarações regionais como `zh-TW` usam seu script CLDR costumeiro, enquanto a `zh` ampla permanece ilimitada por script.

Participantes elegíveis recebem notificações push genéricas de celular apenas quando optaram por isso; a entrega reconfere a fluência atual, associação, acesso ao projeto e o objetivo aberto. Notificações abrem a conversa compartilhada. Conversas e aprovações estão disponíveis tanto em s apps nativos quanto no dashboard web. Veja [Notificações push nativas](/docs/reference/native-push-notifications) para configuração do provedor e política de entrega.

## Perfil de linguagem fluente

`GET /api/me` inclui `user.fluent_languages`. `PUT /api/me/fluent-languages` requer `user:write` e aceita apenas `{"fluent_languages": ["es", "ar", "zh-Hant"]}`. Ele substitui a lista do usuário autenticado e retorna o envelope de perfil. Tags CLDR BCP47 suportadas mantêm especificidade explícita de região/script e usam casing canônico; duplicatas colapsam. Um array vazio limpa a fluência. Tags inválidas, campos sem relevância ou mais de 50 entradas enviadas retornam 422. Isso nunca altera o idioma de interface.

## API de revisão

`GET /api/:handle/projects/:project/translations/:id/reviews` requer `translation:read` e acesso ao projeto. Ele retorna `{"reviews": [...]}`, com perguntas abertas primeiro e depois as mais antigas, limitado a 500 entradas. Atualize após responder para revelar quaisquer perguntas restantes; o histórico respondido nunca oculta uma pergunta aberta atrás do limite.

Cada revisão inclui `id`, `translation_session_id`, `conversation_id`, `participants` (`id` e `name` opcional), `status`, `source_path`, `output_path`, `locale`, `question`, limitado `source_excerpt` e `translation_excerpt`, `answer`, `guidance`, `context_path`, `resolution_message_id`, `resumed_session_id`, e `inserted_at`. O status é `open`, `answered`, ou `stale`.

`answered_by` identifica a pessoa que aprovou a decisão como `{"id": "<user UUID>", "name": "<current display name>"}`; `name` pode ser nulo. O campo é nulo antes da aprovação ou quando o aprovador está indisponível. Não contém e-mail ou outros campos de perfil privado, e reexcutar uma aprovação não altera o aprovador. O mesmo campo é incluído na `linguistic_review` aninhada em conversas Toki compartilhadas. Nenhuma marca de tempo de aprovação é exposta; `inserted_at` é o tempo de criação da revisão, não o tempo de aprovação.

Utilize os endpoints de conversa e mensagem do projeto Toki existentes para discussão. Conversas de objetivos compartilhados aparecem ao lado das conversas privadas do ator no histórico do Toki. Históricos compartilhados exigem permissão de política atual de leitura/escrita do Toki e acesso de leitura de tradução; históricos comuns permanecem restritos ao proprietário. Mensagens humanas incluem sua identidade de autor, e as respostas incluem `status` e `reply_to_id`. O Toki recebe trechos limitados de fonte/candidato e o objetivo, não acesso de escrita do repositório.

`POST /api/:handle/projects/:project/translations/:id/reviews/:review_id/answer` exige tanto `translation:read` quanto `translation:write`, além de acesso ao projeto:

```json
{
  "resolution_message_id": "019a1c6d-4321-7000-8000-123456789abc",
  "answer": "Branch means a source-control release branch.",
  "guidance": "Use the source-control meaning of branch in release documentation.",
  "context_scope": "locale"
}
```

`resolution_message_id` deve identificar a **resposta** de assistente mais recente concluída na conversa de objetivo, não sua pergunta de abertura. `answer` é a decisão aprovada pelo humano e é obrigatória e não vazia. `guidance` e `context_scope` são opcionais; o âmbito padrão é `locale` e também pode ser `project`. Resposta e orientação permitem até 8.000 caracteres e 32.000 bytes UTF-8. Orientação não pode conter comentários de marcador de revisão reservados do Glossia. O servidor escolhe os caminhos do repositório; um caminho fornecido pelo cliente nunca é usado.

Uma resposta bem-sucedida é `{"review": {...}}`. Reproduzir a mesma decisão, mensagem de resolução, orientação e âmbito é idempotente. Uma conversa ocupada retorna `409 conversation_busy`; uma mensagem mais recente ou referência de resolução inválida retorna `409 resolution_outdated`. Carregue e revise a discussão atual antes de aprovar novamente. Uma decisão diferente em um objetivo resolvido retorna `409 already_answered`; aprovar um objetivo cancelado ou substituído retorna `409 stale`. Texto inválido ou âmbito indisponível retorna 422. IDs ausentes e de outro projeto retornam 404. Autenticação normal e autorização do projeto aplicam-se a cada requisição, incluindo reproduções. Objetivos fechados rejeitam novas mensagens de discussão com `409 goal_closed`.

## Continuações e contexto obsoleto

Decisões podem ser aprovadas enquanto o trabalho independente ainda está em execução. Elas nunca iniciam um segundo runner naquela altura. Uma vez que o runner libere e todo objetivo nessa execução esteja resolvido, o Glossia enfileira atomicamente uma sessão de continuação. `resumed_session_id` o identifica; a sessão original permanece histórica `awaiting_input`. Tanto o dashboard quanto conversas nativas vinculam-se à continuação.

A continuação possui identidade de execução nova e mantém o branch de publicação de tradução e os outputs validados. Cada resposta se aplica apenas à fonte idêntica e à impressão digital de contexto de tradução resolvida. Fonte alterada, voz, glossário, modelo ou instruções do repositório impedem reuso da resposta. Um commit mais recente do branch padrão suplanta sessões pendentes e marca perguntas abertas como obsoletas. Cancelamento também marca perguntas abertas como obsoletas.

## Orientação de repositório reutilizável

A orientação de repositório reutilizável é uma edição humana separada e explícita. Uma resposta isolada não se torna contexto de repositório, e transcrições de chat privado nunca são copiadas automaticamente.

`locale` visa o overlay de locale aplicável, como `L10N/es.md`; `project` visa o `L10N.md` aplicável. Arquivos de contexto com escopo existentes são respeitados. Overlays de locale ausentes recebem seu frontmatter de locale. Frontmatter e texto existentes são preservados, e cada decisão é anexada com seu UUID de revisão para procedência e idempotência.

A orientação é proposta no pull request de tradução normal, sem ser escrita silenciosamente no default branch. O repositório deve ainda corresponder ao digest de contexto registrado; uma edição conflitante falha na publicação em vez de substituí-la. Os caminhos devem ser documentos de localização relativos ao repositório, sem traversal ou symlinks. Cada documento de contexto é limitado a 1 MiB. Integrar o pull request torna a orientação um contexto de localização versionado comum para execuções futuras.
