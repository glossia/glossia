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

Administradores da organização podem conectar um provedor de identidade corporativa em **Configurações → Autenticação**.

1. Escolha **Google Workspace** ou **Okta** e digite o domínio do e-mail de trabalho da equipe.
2. Para o Okta, crie um aplicativo web usando [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Insira seu emissor, identificador de cliente e segredo do cliente. O Glossia suporta emissores padrão de organização do Okta e o `/oauth2/default` servidor de autorização. Os segredos são criptografados em repouso. Deixar o segredo em branco ao editar mantém o valor salvo.
3. Para o Okta, registre o endereço de redirecionamento exibido no Glossia com seu provedor de identidade. Para o Google Workspace, o Glossia gerencia a conexão do Google; você não precisa criar um aplicativo Google nem registrar um endereço de retorno.
4. Salve as configurações. Adicione o registro DNS TXT exibido no seu provedor de domínio e, em seguida, selecione **Verificar domínio**. Alterar o domínio de e-mail cria um novo token de verificação e desabilita o login da organização até ser verificado novamente.
5. Membros da equipe inserem seu e-mail de trabalho na página de login e selecionam **Continuar com sua organização**. Membros do Google Workspace também podem usar **Fazer login com o Google**.

## . Configurar o Google Workspace

O Glossia gerencia as credenciais da aplicação do Google. Não é necessário criar um aplicativo OAuth no Google Cloud, adicionar um aplicativo SAML personalizado no Google Admin ou registrar um endereço de redirecionamento. Para um domínio existente do Google Workspace, a configuração ocorre no Glossia e no seu provedor de DNS:

1. Em **Configurações → Autenticação**, escolha **, Google Workspace**, digite seu domínio de e-mail corporativo e selecione **Salvar as configurações de autenticação**.

2. Abra as configurações DNS do seu domínio no provedor que hospeda seu DNS, não necessariamente Google Workspace. Adicione o registro mostrado em **Verificar propriedade do domínio**:
   
   | Campo | Valor |
   | --- | --- |
   | Tipo | `TXT` |
   | Nome / Host | O **nome do registro** exibido no Glossia, como `_glossia-verification.example.com` |
   | Valor / Conteúdo | O **Valor do registro** exibido no Glossia, começando com `glossia-domain-verification=` |
   
   Alguns provedores de DNS adicionam seu domínio automaticamente. Nesse caso, insira apenas `_glossia-verification` como o host para que o domínio não seja incluído duas vezes. Mantenha o registro no lugar após a verificação.

3. Voltar ao Glossia e selecionar **Verificar domínio**. Se a verificação falhar, verifique o nome e o valor e permita tempo para as alterações de DNS se propagarem antes de tentar novamente.

4. Peça a um membro da equipe para inserir seu e-mail de trabalho na página de login e selecione **Continuar com sua organização**, ou use **Entrar com o Google**.

O Glossia verifica o e-mail verificado do Google e [afirmação de domínio hospedado](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload); uma conta Google pessoal com o mesmo sufixo de e-mail não se qualifica.

### Se o Google bloquear o login

Nenhuma configuração do lado do Google é normalmente necessária. Se sua organização restringir o acesso a aplicativos de terceiros, um administrador do Google Workspace pode precisar aprovar o Glossia:

1. Faça login no [Console de Administração do Google](https://admin.google.com/) com uma conta de administrador.
2. Ir para **Segurança → Controle de acesso e dados → Controles de API → Gerenciar acesso a aplicativos de terceiros**.
3. Encontre o Glossia na lista de aplicativos acessados. Se ele não estiver listado, use **Configurar novo aplicativo** para pesquisar por nome do aplicativo ou ID do cliente OAuth. O ID do cliente OAuth pertence à conexão compartilhada do Glossia com o Google, não a um aplicativo que você precise criar.
4. Revise as permissões de acesso solicitadas e conceda acesso aos usuários relevantes de acordo com a política da sua organização. Veja no Google [Controlar quais aplicativos de terceiros e internos acessam os dados do Google Workspace](https://support.google.com/a/answer/7281227) guia de níveis de acesso e requisitos do administrador.
5. Tente novamente o login com uma conta de trabalho após a alteração da política entrar em vigor.

## Gerenciar inscrição e permissões

Uma identidade de provedor verificada com um domínio de e-mail do trabalho correspondente exatamente entra automaticamente na organização. Para uma conta Glossia existente conectando o Okta pela primeira vez, faça login usando o método existente antes de iniciar o login na organização. Isso vincula o provedor com segurança sem permitir que um administrador do Okta assuma outra conta Glossia. O registro público por meio de outros provedores continua usando o formulário de interesses. Desabilitar o provedor interrompe o login na organização sem excluir os membros existentes.

Novos membros recebem acesso básico de leitura à conta, organização, projetos, voz, glossário, discussões e chamados. Siga [Gerenciar permissões de membros](/docs/how-to/member-permissions) para conceder acesso adicional após o ingresso.

## Proteções de acesso

A verificação de propriedade do domínio dura 30 dias e é verificada automaticamente todos os dias. Mantenha o registro de verificação ativo. Se desaparecer, o login para assim que a última verificação válida expirar; restaure o registro e verifique novamente nas Configurações de Autenticação. Alterar provedores ou desabilitar o login na organização invalida a verificação e remove as credenciais pertencentes ao provedor anterior. Reivindicações não verificadas não reservam um domínio.

Para contas existentes, faça login primeiro com o método existente, depois visite `/auth/login` e inicie o login com e-mail do trabalho para conectar a identidade de trabalho. O Google também pode usar uma identidade do Google já vinculada com o mesmo identificador do provedor. Combinar apenas um endereço de e-mail nunca conecta uma conta existente.

Remover um membro bloqueia a re-inscrição automática. Um administrador deve adicionar ou convidá-los novamente explicitamente para restaurar o acesso, mesmo que sua identidade de trabalho ainda esteja ativa.

Gerenciamento de convites de membros, credenciais de acesso, edição de modelos de linguagem e exclusão da organização permanecem como responsabilidades do administrador. Essas permissões não podem ser delegadas por meio de caixas de seleção de escopo de membro. Configuração de autenticação, verificação de domínio e alterações de escopo emitem eventos de auditoria.