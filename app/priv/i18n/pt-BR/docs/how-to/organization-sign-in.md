%{
  title: "Configurar login da organização",
  summary:
    "Conecte o Google Workspace ou Okta, verifique seu domínio e gerencie as permissões de membros.",
  category: "Passo a passo",
  section: "platform",
  order: 8
}
---

## Conecte seu provedor de identidade

Administradores de organização podem conectar um provedor de identidade de trabalho em **Configurações → Autenticação**.

1. Escolha **Google Workspace** ou **Okta** e insira o domínio de e-mail de trabalho da equipe.
2. Para o Okta, crie um aplicativo web usando [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Insira seu emissor, identificador do cliente e segredo do cliente. O Glossia suporta emissores de organização Okta padrão e o `/oauth2/default` servidor de autorização. Os segredos são criptografados em repouso. Deixar o segredo em branco ao edição mantém o valor salvo.
3. Para o Okta, registre o endereço de redirecionamento exibido no Glossia com seu provedor de identidade. Para o Google Workspace, o Glossia gerencia a conexão com o Google; você não precisa criar um aplicativo do Google ou registrar um endereço de callback.
4. Salve as configurações. Adicione o registro DNS TXT exibido através do seu provedor de domínio, em seguida selecione **Verificar domínio**. Alterar o domínio de e-mail cria um novo token de verificação e desabilita o login de organização até que seja verificado novamente.
5. Os membros da equipe inserem seu e-mail de trabalho na página de login e selecionam **Continuar com sua organização**. Os membros do Google Workspace também podem usar **Entrar com o Google**.

## Configure o Google Workspace

O Glossia gerencia as credenciais do aplicativo do Google. Você não precisa criar um aplicativo OAuth na Google Cloud, adicionar um aplicativo SAML personalizado no Google Admin ou registrar um endereço de redirecionamento. Para um domínio do Google Workspace existente, a configuração ocorre no Glossia e no seu provedor de DNS:

1. Em **Configurações → Autenticação**, escolha **Google Workspace**, insira seu domínio de e-mail de trabalho e selecione **Salvar configurações de autenticação**.
2. Acesse as configurações de DNS do seu domínio no provedor que hospeda seu DNS, não necessariamente o Google Workspace. Adicione o registro mostrado em **Verificar propriedade do domínio**:

   | Campo | Valor |
   | --- | --- |
   | Tipo | `TXT` |
   | Nome / Host | O **Nome do registro** exibido no Glossia, tal como `_glossia-verification.example.com` |
   | Valor / Conteúdo | O **Valor do registro** exibido no Glossia, iniciando com `glossia-domain-verification=` |

   Alguns provedores de DNS anexam seu domínio automaticamente. Nesse caso, insira apenas `_glossia-verification` como host para que o domínio não seja incluído duas vezes. Mantenha o registro em vigor após a verificação.
3. Volte ao Glossia e selecione **Verificar domínio**. Se a verificação falhar, verifique o nome e o valor e permita tempo para as alterações de DNS propagarem antes de tentar novamente.
4. Peça a um membro da equipe para inserir seu e-mail de trabalho na página de login e selecionar **Continuar com sua organização**, ou usar **Entrar com o Google**.

O Glossia verifica o e-mail verificado do Google e a [reivindicação de domínio hospedado](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload); uma conta pessoal do Google com o mesmo sufixo de e-mail não se qualifica.

### Se o Google bloquear o login

Normalmente, nenhuma configuração do lado do Google é necessária. Se sua organização restringir o acesso a aplicativos de terceiros, um administrador do Google Workspace pode precisar aprovar o Glossia:

1. Faça login no [Console de administração do Google](https://admin.google.com/) com uma conta de administrador.
2. Vá para **Segurança → Controle de acesso e dados → Controles de API → Gerenciar acesso a aplicativos de terceiros**.
3. Localize o Glossia na lista de aplicativos acessados. Se não estiver listado, use **Configurar novo aplicativo** para buscá-lo pelo nome do aplicativo ou ID de cliente OAuth. O ID de cliente OAuth pertence à conexão comum do Google do Glossia, não a um aplicativo que você precise criar.
4. Revise as permissões de login solicitadas e permita acesso aos usuários relevantes conforme a política de sua organização. Veja o guia do Google [Controlar quais aplicativos de terceiros e internos acessam dados do Google Workspace](https://support.google.com/a/answer/7281227) para níveis de acesso e requisitos de administrador.
5. Tente realizar login novamente com uma conta de trabalho após a mudança na política entrar em vigor.

## Gerenciar inscrição e permissões

Uma identidade de provedor verificada com um domínio de e-mail de trabalho correspondente exato se junta automaticamente à organização. Para uma conta do Glossia existente conectando o Okta pela primeira vez, faça login com o método existente antes de começar o login de organização. Isso vincula o provedor com segurança sem permitir que um administrador Okta assuma outra conta do Glossia. O registro público através de outros provedores continua a usar o formulário de interesses. Desativar o provedor interrompe o login de organização sem excluir membros existentes.

Novos membros recebem acesso básico de leitura à conta, organização, projetos, voz, glossário, discussões e tickets. Siga [Gerenciar permissões de membro](/docs/how-to/member-permissions) para conceder acesso adicional após o cadastro.

## Proteções de acesso

A verificação de propriedade de domínio dura 30 dias e é verificada automaticamente todos os dias. Mantenha o registro de verificação em vigor. Se desaparecer, o login para assim que a última verificação bem-sucedida expirar; restaure o registro e verifique novamente nas configurações de Autenticação. Alterar provedores ou desativar o login de organização limpa a verificação e remove as credenciais pertencentes ao provedor anterior. Reivindicações não verificadas não reservam um domínio.

Para contas existentes, faça login com o método existente primeiro, em seguida visite `/auth/login` e inicie o login de e-mail de trabalho para conectar a identidade de trabalho. O Google também pode usar uma identidade do Google já vinculada com o mesmo assunto do provedor. Coincidir apenas um endereço de e-mail nunca conecta uma conta existente.

Remover um membro bloqueia a re-inscrição automática. Um administrador deve adicioná-lo ou convidá-lo novamente explicitamente para restaurar o acesso, mesmo que sua identidade de trabalho ainda esteja ativa.

O gerenciamento de convites de membros, credenciais de acesso, edição do modelo de idioma e exclusão de organização continuam sendo responsabilidades do administrador. Essas permissões não podem ser delegadas através das caixas de verificação de escopo de membros. Configuração de autenticação, verificação de domínio e alterações de escopo emitem eventos de auditoria.
