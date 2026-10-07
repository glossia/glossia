%{
  title: "Pull requests de tradução mais calmos",
  summary:
    "O que aprendemos ao soltar o Glossia em um repositório movimentado, e como os pull requests de tradução mudaram por causa disso."
}
---
Você aprende bastante na primeira vez em que sua ferramenta encontra um repositório real. Para nós, foi o Tuist. Sua equipe faz merge no `main` várias vezes por dia, e o Glossia fez exatamente o que criamos para que ele fizesse: traduzia cada alteração e enviava cada arquivo assim que estivesse pronto. O resultado foi um novo pull request para quase cada merge, cada um com cerca de 150 commits, e uma fila de CI cheia de verificações que ninguém havia solicitado. Algumas páginas de documentação deles também voltaram com componentes e alertas escapados em texto simples. Não era a experiência silenciosa e em segundo plano de que falávamos.

Isso doeu, porque sempre dissemos que o melhor sistema de tradução é aquele que você não precisa pensar em. Um pull request que sobrecarrega seu CI ou corrompe sua documentação é o oposto disso. Então, voltamos e repensamos como as traduções chegam no seu repositório.

O Glossia agora mantém um único pull request por projeto e o expande conforme seu conteúdo muda. Ele lê os arquivos de bloqueio já presentes naquele ramo, de forma que traduz apenas o que é novo e envia em lotes em vez de arquivo por arquivo. Em um repositório como o do Tuist, isso agora é uma meia dúzia de envios, que antes eram cento e cinquenta.

Também paramos de mexer em partes de seus documentos que não são do nosso domínio alterar. O Glossia costumava reconstruir cada página que traduzia, e qualquer coisa que não entendesse totalmente, como um componente Phoenix ou um alerta do GitHub, poderia sair do outro lado em texto simples. Agora, ele apenas substitui as frases traduzidas e deixa o restante exatamente como você escreveu. Houve um bom efeito colateral que não esperávamos: porque o modelo agora vê frases inteiras e o restante da página, as traduções fluem melhor. Em japonês, um link não precisa mais ficar torto onde estava na frase em inglês.

Finalmente, o pull request agora te informa o que aconteceu. Quais idiomas e arquivos foram traduzidos, de quais commits, como eles foram pontuados, quais termos do glossário os influenciaram, e o que, se houver, precisa da sua atenção. Pensamos nisso como a nota que um colega atencioso deixaria para você antes de solicitar uma revisão.

Obrigado à equipe do Tuist pela paciência enquanto resolvemos isso. Se o Glossia algum dia atrapalhar sua operação dessa forma, adoraríamos ouvir sobre isso.