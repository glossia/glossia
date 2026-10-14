%{
  title: "Configurar login da organização",
  summary:
    "Conecte o Google Workspace ou Okta, verifique seu domínio e gerencie as permissões de membros.",
  category: "passo-a-passo",
  section: "platform",
  order: 8
}
---

## Conecte seu provedor de identidade

Os administradores da organização podem conectar um provedor de identidade de trabalho em **Ajustes → Autenticação**.

1. Escolha **Google Workspace** ou **Okta** e insira o domínio de e-mail de trabalho da equipe.
2. Para o Okta, crie um aplicativo web usando [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Insira seu emissor, identificador de cliente e segredo do cliente. O Glossia suporta emissores padrão de organização do Okta e o `/oauth2/default` servidor de autorização. Segredos são criptografados em repouso. Deixar o segredo em branco ao editar mantém o valor salvo.
3. Para o Okta, registre o endereço de redirecionamento exibido no Glossia com seu provedor de identidade. Para o Google Workspace, o Glossia gerencia a conexão do Google; você não precisa criar um aplicativo do Google ou registrar um endereço de callback.
4. Salve as configurações. Adicione o registro DNS TXT exibido através do provedor de domínio, e depois selecione **Verificar domínio**. Alterar o domínio de e-mail cria um novo token de verificação e desabilita o login da organização até ser verificado novamente.
5. Os membros da equipe inserem seu e-mail de trabalho na página de login e selecionam **Continuar com sua organização**. Membros do Google Workspace também podem usar **Entrar com o Google**.

## Configure o Google Workspace

O Glossia gerencia as credenciais do aplicativo do Google. Você não precisa criar um aplicativo OAuth na Google Cloud, adicionar um aplicativo SAML personalizado no Google Admin, ou registrar um endereço de redirecionamento. Para um domínio do Google Workspace existente, a configuração ocorre no Glossia e no seu provedor de DNS:

1. Em **Ajustes → Autenticação**, escolha **Google Workspace**, insira seu domínio de e-mail de trabalho e selecione **Salvar configurações de autenticação**.
2. Abra as configurações de DNS do seu domínio no provedor que hospeda seu DNS, não necessariamente no Google Workspace. Adicione o registro mostrado em **Verificar propriedade do domínio**:

   | Campo | Valor |
   | --- | --- |
   | Tipo | `TXT` |
   | Nome / Host | O **Nome do registro** exibido no Glossia, como `_glossia-verification.example.com` |
   | Valor / Conteúdo | O **Valor do registro** exibido no Glossia, começando com `glossia-domain-verification=` |

   Alguns provedores de DNS adicionam seu domínio automaticamente. Nesse caso, digite apenas `_glossia-verification` como host para que o domínio não seja incluído duas vezes. Mantenha o registro em local após a verificação.
3. Retorne ao Glossia e selecione **Verificar domínio**. Se a verificação falhar, verifique o nome e o valor e permita tempo para que as alterações de DNS se propaguem antes de tentar novamente.
4. Peça a um membro da equipe que insira seu e-mail de trabalho na página de login e selecione **Continuar com sua organização**, ou use **Entrar com o Google**.

O Glossia verifica o e-mail verificado do Google e [reivindicação de domínio hospedado](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload); uma conta pessoal do Google com o mesmo sufixo de e-mail não se qualifica.

### Se o Google bloquear a entrada

Normalmente não é necessária configuração do lado do Google. Se sua organização restringir o acesso a aplicativos de terceiros, um administrador do Google Workspace pode precisar aprovar o Glossia:

1. Faça login no [Console de Administração do Google](https://admin.google.com/) com uma conta de administrador.
2. Vá para **Segurança → Controle de acesso e dados → Controles de API → Gerenciar acesso a aplicativos de terceiros**.
3. Encontre o Glossia na lista de aplicativos acessados. Se não estiver listado, use **Configurar novo aplicativo** para procurá-lo pelo nome do aplicativo ou pelo ID do cliente OAuth. O ID do cliente OAuth pertence à conexão Google compartilhada do Glossia, não a um aplicativo que você precise criar.
4. Reveja as permissões de login solicitadas e conceda acesso aos usuários relevantes de acordo com a política da sua organização. Veja o guia do Google [Controle quais aplicativos de terceiros e internos acessam dados do Google Workspace](https://support.google.com/a/answer/7281227) para os níveis de acesso e requisitos do administrador.
5. Tente fazer login novamente com uma conta de trabalho após a mudança de política entrar em vigor.

## Gerenciar inscrição e permissões

Uma identidade de provedor verificada com um domínio de e-mail de trabalho exato se junta automaticamente à organização. Para uma conta existente do Glossia conectando-se ao Okta pela primeira vez, faça login com o método existente antes de começar a entrada na organização. Isso vincula o provedor com segurança, sem permitir que um administrador do Okta assuma outra conta do Glossia. O registro público através de outros provedores continua a usar o formulário de interesse. Desabilitar o provedor para de entrada na organização sem deletar os membros existentes.

Novos membros recebem acesso de leitura básico à conta, organização, projetos, voz, glossário, discussões e tickets. Siga [Gerenciar permissões de membros](/docs/how-to/member-permissions) para conceder acesso adicional após o ingresso.

## Proteções de acesso

A verificação de propriedade do domínio dura 30 dias e é verificada automaticamente todos os dias. Mantenha o registro de verificação em local. Se desaparecer, a entrada para quando a última verificação bem-sucedida expirar; restaure o registro e verifique novamente a partir das configurações de Autenticação. Alterar provedores ou desabilitar a entrada na organização limpa a verificação e remove as credenciais do provedor anterior. Reivindicações não verificadas não reservam um domínio.

Para contas existentes, faça login com o método existente primeiro, depois visite `/auth/login` e comece a entrada de e-mail para conectar a identidade de trabalho. O Google também pode usar uma identidade Google já vinculada com o mesmo assunto do provedor. Corresponder um endereço de e-mail sozinho nunca conecta uma conta existente.

Remover um membro bloqueia a re-inscrição automática. Um administrador deve adicioná-los ou convidá-los novamente explicitamente para restaurar o acesso, mesmo que sua identidade de trabalho ainda esteja ativa.

Gerenciamento de convites de membros, credenciais de acesso, edição de modelo de linguagem e exclusão de organização permanecem responsabilidades do administrador. Essas permissões não podem ser delegadas através de caixas de verificação de escopo de membro. Configuração de autenticação, verificação de domínio e alterações de escopo emitem eventos de auditoria.
