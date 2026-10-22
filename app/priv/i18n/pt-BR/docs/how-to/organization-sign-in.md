%{
  title: "Configurar login da organização",
  summary:
    "Conecte o Google Workspace ou o Okta, verifique seu domínio e gerencie as permissões dos membros.",
  category: "Tutorial",
  section: "platform",
  order: 8
}
---

## Conecte seu provedor de identidade

Administradores da organização podem conectar um provedor de identidade de trabalho em **Configurações → Autenticação**.

1. Escolha **Google Workspace** ou **Okta** e insira o domínio de e-mail de trabalho da equipe.
2. Para Okta, crie um aplicativo web usando [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Digite seu emissor, identificador do cliente e segredo do cliente. O Glossia suporta emissores de organização Okta padrão e o `/oauth2/default` servidor de autorização. Os segredos são criptografados em repouso. Deixar o segredo em branco ao editar mantém o valor salvo.
3. Para Okta, registre o endereço de redirecionamento exibido no Glossia com seu provedor de identidade. Para o Google Workspace, o Glossia gerencia a conexão do Google; você não precisa criar um aplicativo Google nem registrar um endereço de callback.
4. Salve as configurações. Adicione o registro TXT DNS exibido passando pelo provedor de seu domínio, em seguida selecione **Verificar domínio**. Alterar o domínio de e-mail cria um novo token de verificação e desabilita o login da organização até que seja verificado novamente.
5. Membros da equipe inserem seu e-mail de trabalho na página de login e selecionam **Continuar com sua organização**. Membros do Google Workspace também podem usar **Fazer login com o Google**.

## Configurar o Google Workspace

O Glossia gerencia as credenciais do aplicativo Google. Você não precisa criar um aplicativo OAuth no Google Cloud, adicionar um aplicativo SAML personalizado no Google Admin ou registrar um endereço de redirecionamento. Para um domínio Google Workspace existente, o setup ocorre no Glossia e em seu provedor de DNS:

1. Em **Configurações → Autenticação**, escolha **Google Workspace**, insira seu domínio de e-mail de trabalho e selecione **Salvar configurações de autenticação**.
2. Acesse as configurações de DNS do seu domínio no provedor que hospeda seu DNS, não necessariamente o Google Workspace. Adicione o registro exibido em **Verificar propriedade do domínio**:

   | Campo | Valor |
   | --- | --- |
   | Tipo | `TXT` |
   | Nome / Host | O **Nome do registro** exibido no Glossia, como `_glossia-verification.example.com` |
   | Valor / Conteúdo | O **Valor do registro** exibido no Glossia, começando com `glossia-domain-verification=` |

   Alguns provedores de DNS anexam seu domínio automaticamente. Nesse caso, digite apenas `_glossia-verification` como host para que o domínio não seja incluído duas vezes. Mantenha o registro em local após a verificação.
3. Retorne ao Glossia e selecione **Verificar domínio**. Se a verificação falhar, verifique o nome e o valor e deixe tempo para que as alterações de DNS se propaguem antes de tentar novamente.
4. Peça a um membro da equipe para inserir seu e-mail de trabalho na página de login e selecione **Continuar com sua organização**, ou use **Fazer login com o Google**.

O Glossia verifica o e-mail verificado do Google e o [testemunho de domínio hospedado](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload); uma conta pessoal do Google com o mesmo sufixo de e-mail não se qualifica.

### Se o Google bloquear o login

Normalmente não é necessária configuração do lado do Google. Se sua organização restringir o acesso a aplicativos de terceiros, um administrador do Google Workspace pode precisar aprovar o Glossia:

1. Faça login no [Painel de administração do Google](https://admin.google.com/) com uma conta de administrador.
2. Vá para **Segurança → Controle de acesso e dados → Controles de API → Gerenciar acesso a aplicativos de terceiros**.
3. Encontre o Glossia na lista de aplicativos acessados. Se não estiver listado, use **Configurar novo aplicativo** para encontrá-lo pelo nome do aplicativo ou ID do cliente OAuth. O ID do cliente OAuth pertence à conexão do Google compartilhada do Glossia, não a um aplicativo que você precisa criar.
4. Revise as permissões de login solicitadas e permita o acesso para os usuários relevantes de acordo com a política da sua organização. Consulte o guia do Google [Controlar quais aplicativos de terceiros e aplicativos internos acessam os dados do Google Workspace](https://support.google.com/a/answer/7281227) para níveis de acesso e requisitos de administrador.
5. Tente o login novamente com uma conta de trabalho após a política entrar em vigor.

## Gerenciar inscrição e permissões

Uma identidade de provedor verificada com um domínio de e-mail de trabalho exato entra na organização automaticamente. Para uma conta Glossia existente conectando o Okta pela primeira vez, faça login com o método existente antes de iniciar o login da organização. Isso vincula o fornecedor com segurança sem permitir que um administrador do Okta assuma outra conta Glossia. O registro público por meio de outros fornecedores continua a usar o formulário de interesse. Desativar o fornecedor interrompe o login da organização sem excluir membros existentes.

Novos membros recebem acesso básico de leitura à conta, organização, projetos, voz, glossário, discussões e tickets. Siga [Gerenciar permissões de membros](/docs/how-to/member-permissions) para conceder acesso adicional após eles entrarem.

## Medidas de proteção de acesso

A verificação de propriedade do domínio dura 30 dias e é verificada automaticamente todos os dias. Mantenha o registro de verificação em local. Se ele desaparecer, o login pára uma vez que a última verificação bem-sucedida expira; restaure o registro e verifique novamente nas configurações de Autenticação. Alterar provedores ou desativar o login da organização limpa a verificação e remove as credenciais pertencentes ao fornecedor anterior. Reivindicações não verificadas não reservam um domínio.

Para contas existentes, faça login primeiro com o método existente, em seguida visite `/auth/login` e inicie o login com e-mail de trabalho para conectar a identidade de trabalho. O Google também pode usar uma identidade do Google já vinculada com o mesmo sujeito do provedor. A correspondência de um endereço de e-mail por si só nunca conecta uma conta existente.

Remover um membro bloqueia a reinscrição automática. Um administrador deve adicioná-los ou convidá-los novamente explicitamente para restaurar o acesso, mesmo se sua identidade de trabalho ainda estiver ativa.

A gestão de convites de membros, credenciais de acesso, edição de modelos de linguagem e exclusão de organização permanecem responsabilidades do administrador. Essas permissões não podem ser delegadas por meio de caixas de seleção de escopo de membro. Configuração de autenticação, verificação de domínio e alterações de escopo emitem eventos de auditoria.
