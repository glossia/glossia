%{
  title: "Notificações push nativas",
  summary:
    "Configuração do provedor, registro de dispositivos com consentimento, política de entrega e payloads nativos.",
  category: "referência",
  section: "platform",
  order: 30
}
---

## Transporte e credenciais

O Glossia envia diretamente para o APNs no iOS e o FCM HTTP v1 no Android. PostgreSQL armazena os registros o Oban fila a entrega. Nenhum serviço de mensagens ou Firebase iOS SDK é necessário. A aceitação do provedor não é um comprovante de entrega ou de leitura. Falhas de rede ambíguas podem produzir alertas duplicados.

Segredos do provedor pertencem apenas ao sistema de gerenciamento de segredos existente do servidor. Nunca coloque chaves privadas do APNs ou JSON de conta-service do Firebase em compilados móveis, arquivos de repositório, logs ou configurações visíveis ao cliente. Identificadores públicos do app Android do Firebase não são credenciais de conta-service.

| Variável de ambiente | Significado |
| --- | --- |
| `GLOSSIA_APNS_TEAM_ID` | ID da equipe Apple de dez caracteres. |
| `GLOSSIA_APNS_KEY_ID` | ID da chave de assinatura Apple de dez caracteres. |
| `GLOSSIA_APNS_PRIVATE_KEY` | Chave de assinatura privada P-256 codificada em PEM, preservando quebras de linha. |
| `GLOSSIA_APNS_TOPIC` | O identificador do pacote exato do aplicativo iOS assinado. Clientes não podem escolher. |
| `GLOSSIA_APNS_ENVIRONMENT` | `production` (padrão), `sandbox`, ou explicitamente `both` para uma chave que suporta ambos. |
| `GLOSSIA_FCM_SERVICE_ACCOUNT_JSON` | JSON de conta do serviço do Firebase do Android com `type`, `project_id`, `client_email` e RSA `private_key`. |

Credenciais do APNs ausentes desativam apenas o iOS. Credenciais do FCM ausentes desativam apenas o Android. Provedores configurados parciais ou malformados falham na análise de configuração com um erro sem segredos. O ambiente do APNs é verificado no registro e entrega; derive-o do perfil de provisionamento assinado, não de suposições de modo-compilar. O APNs usa um agrupamento Finch dedicado HTTP/2-apenas e autenticação ES256. O FCM troca uma afirmação de conta RS256 no endpoint OAuth fixo do Google, então usa seu endpoint HTTP v1 fixo. Redirecionamentos e re-tentativas do cliente HTTP são desativados.

## API de Registro

Todas as rotas exigem um token portador OAuth emitido ao cliente PKCE público por-instalação dinamicamente registrado do app nativo. Seu único URI de redirecionamento deve ser `glossia://oauth/callback`; refresh e revoke devem ser públicos, sem métodos de autenticação client-secret. O cliente de Expo compartilhado legado, tokens de conta, sessões do navegador e outros clientes OAuth não são identidades de instalação e não podem registrar dispositivos. Isso verifica a forma do cliente, não a atestação do dispositivo.

`PUT /api/me/push-devices/:installation_id` aceita exatamente:

```json
{"platform":"ios","token":"<OS device token>","environment":"production"}
```

- `installation_id`: UUID gerado por cliente. É também o `registration_id` retornado e entregue.
- `platform`: `ios` ou `android`.
- `environment`: `sandbox` ou `production` para iOS; apenas `production` para Android.
- Tokens do iOS: 32–512 caracteres hexadecimais, comprimento par, normalizado para minúsculas.
- Tokens do Android: 16–4096 caracteres ASCII imprimíveis não-apósescis.
- PUT bem-sucedido: `{"registered":true,"registration_id":"<installation UUID>"}`.
- Campos desconhecidos, incluindo seletores de proprietário, tópico, host e URLs do provedor, são rejeitados.

`DELETE /api/me/push-devices/:installation_id` retorna `{"deleted":true}` idempotentemente. IDs desconhecidos tornam-se tombstones, assim um PUT diferido não pode ressuscitar uma instalação após sign-out. Instalação irrelevante de usuário diferente nunca é alterada. O mesmo cliente OAuth nativo pode aposentar a instalação de usuário anterior durante recuperação sign-out offline, mas propriedade nunca se move. Rota para um UUID de instalação fresco após `409 installation_retired`.

`GET /api/me/push-devices/capabilities` retorna `{"ios":true,"android":false}` segundo provedores configurados; tem o mesmo requisito de autenticação. Uma capacidade do iOS verdadeira não anula restrições de ambiente do APNs.

Respostas são `no-store`. Mutações limitadas a 120 requisições por usuário por hora, além do limite da API. Autenticação portador ausente/inválida retorna 401; credenciais não-nativas retornam 403; dados de dispositivo inválido retornam 400; instalações aposentadas/conflictivas retornam 409; provedores não-disponíveis retornam 503. Limpeza permanecia disponível quando um provedor é desativado.

## Intenções de entrega

Chamadores internos usam a API fixa após seu commit de transação de origem:

```elixir
Glossia.Push.notify_user(user_id, "toki_completed", %{
  conversation_id: conversation.id,
  message_id: completed_user_message.id
})

Glossia.Push.notify_user(user_id, "linguistic_input_needed", %{
  translation_session_id: session.id,
  review_id: review.id
})
```

O tipo pode também ser o átomo correspondente. O retorno é `{:ok, queued_count}` ou `{:error, :invalid_notification}`. Não há API pública de envio com destinatário arbitrário, texto de notificação personalizado, re-tentativa de inferência ou opt-in implícito.

`toki_completed` requer a mensagem do usuário **user** exata e completada e sua resposta do assistente completada. Nas conversas privadas o destinatário deve possuir o histórico; nas conversas de objetivo compartilhadas ainda devem ser um participante fluente convidado elegível e o objetivo deve estar aberto. Verifica acesso atual do Toki/projeto e, para conversas correlacionadas com fonte, acesso de leitura da tradução e existência da fonte. Uma mensagem diferente completada ou um ID de mensagem de assistente não é substituto.

`linguistic_input_needed` requer o objetivo aberto identificado na sessão de tradução especificada e um participante fluente convidado elegível. Uma fonte apenas-sessão permanece aceita para compatibilidade e resolve um objetivo aberto elegível. Avaliações em outra sessão não qualificam. Todos os pares autorizados atingem a mesma conversa do Toki; entrega independentemente re-verifica fluência atual, acesso Toki/tradução/projeto e membresia.

Há no máximo dez registros vivos por usuário. Tokens são criptografados com o Cloak vault existente e indexados por digest SHA-256. Movimento do token aposenta o registro antigo, e invalidação do provedor compara o digest tentado/ambiente antes de limpar algo. Timestamps last-invalid do APNs não aposentam registros refrescados após timestamp.

Empregos de entrega contêm apenas IDs, tipo, IDs de origem e expiry. Cada tentativa re-verifica o registro, proprietário, concessão refresh OAuth nativo persistida atual e escopos, origem, membresia e expiry. Verifica novamente após aquisição de credencial do provedor, imediatamente antes do transporte. Expiry de token de acesso sozinho não termina sessão de refresh ainda válida. Revogação, expiry do refresh, acesso de origem ausente, sign-out ou reviews resolvidos cancela entrega.

Ambos os tipos expiram após uma hora. Há no máximo cinco tentativas do provedor, incluindo snoozes de back-pressure do provedor. Retry-After é respeitado apenas na duração da notificação. Nenhum corpo de resposta ou token do provedor é retornado como erro de trabalho. Atualize os registros no foreground; registros não refrescados por 60 dias são aposentados. O worker de poda horário varre um lote rotativo limitado de 1.000 linhas e remove tokens para sessões antigas ou encerradas. Tombstones retêm apenas IDs de instalação/cliente, plataforma/ambiente e timestamps de ciclo de vida indefinidamente para proteger solicitações atrasadas; linhas aposentadas não têm usuário, token ou digest. Exclusão da conta rompe a referência de usuário, impede toda a entrega imediatamente e o worker de poda limpa o token retido.

Credenciais do provedor usam cache Cachex limitado e sensível a expiração. Rotação de chaves altera a identidade do cache. JWTs do APNs são reutilizados por 50 minutos; credenciais do FCM expiram cinco minutos antes da expiração do provedor (no máximo 50 minutos). Erros não são armazenados em cache.

## Versão do payload 1

O APNs inclui o alerta genérico **Glossia / Você tem uma atualização na Glossia.** O FCM envia mensagens de dados apenas com o mesmo `title` e `body`, para renderização local. Nenhum inclui prompts privados, respostas, perguntas, trechos de fonte ou títulos do projeto. Os campos de roteamento são strings:

```json
{"v":"1","url":"glossia://navigate/org/project/toki/CONVERSATION_UUID?server=https%3A%2F%2Fglossia.ai","registration_id":"INSTALLATION_UUID"}
```

Ambos os tipos de notificação abrem `/org/project/toki/CONVERSATION_UUID`; solicitações de ajuda linguística abrem seu próprio thread de objetivo compartilhado. O `server` é a origem HTTPS do endpoint configurado do Phoenix, nunca cabeçalhos da requisição ou entrada do cliente. Configurações de endpoint exclusivamente HTTP falham em entrega fechada. Clientes nativos devem rejeitar versões desconhecidas, origens/instituições/inscrições não correspondentes e rotas não reconhecidas; tocar nunca altera servidores ou executa mutações. O destino buscado ainda deve passar autorização normal de API.

## Integração de runtime

O aplicativo pai inicia `Glossia.Push.Supervisor` antes do Oban, fornecendo o cache de credenciais e piscina dedicada Finch do APNs. Configuração do runtime chama `Glossia.Push.Config.parse!(System.get_env())`. A fila `push` do Oban tem concorrência cinco e roda `Glossia.Push.Prune` a cada hora. As três rotas de registro executam no pipeline de API existente autenticado com credencial bearer.

O log de requisições redige os tokens de dispositivo. O endpoint estende o filtrador padrão de corpo do Sentry com o filtro de parâmetros do Phoenix, preservando suas proteções existentes:

```elixir
config :phoenix, :filter_parameters, ["password", "passwd", "secret", "token"]

# Endpoint request-body scrubber
plug Sentry.PlugContext, body_scrubber: {__MODULE__, :scrub_request_body}
def scrub_request_body(conn) do
  conn
  |> Sentry.PlugContext.default_body_scrubber()
  |> Phoenix.Logger.filter_values()
end

# Defense in depth: no Phoenix parameter logging for enrollment
put "/me/push-devices/:installation_id", PushDeviceController, :update, log: false
```

Não retenha corpos brutos de requisições push em telemetria personalizada ou relatórios de exceção.

Apenas processos pai de web/trabalhador precisam do supervisor de push e fila. Pods da execução de tradução podem enfileirar IDs sem credenciais, piscina do APNs ou novo serviço de mensagens. Aplique a migração através do fluxo de pipeline de lançamento normal. Mantenha os dados de conta exportados livres de tokens do provedor. Não exclua tombstones como limpeza de retenção rotineira.

Verificações de dispositivo físico permanecem necessárias: compilações iOS/Android assinadas e configuradas, permissão permitida/negada, entrega em foreground/background/terminada, toques de inicialização na hora fria, end-to-end, credenciais expiradas, limpeza de sign-off offline e alternância de conta. Testes de provedor simulados não estabelecem entrega ao vivo. Compilações nativas incluem suporte a ciclo de vida de notificação e dependências do Firebase Android, mas este código não fornece credenciais, infraestrutura compartilhada, perfis de provisionamento assinados ou identificadores de apps Firebase.
