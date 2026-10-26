%{
  title: "Pull requests de tradução mais tranquilos",
  summary:
    "O que aprendemos ao deixar o Glossia à solta em um repositório movimentado e como os pull requests de tradução mudaram por isso."
}
---

Você aprende bastante da primeira vez que sua ferramenta encontra um repositório real. Para nós, foi o Tuist. A equipe deles faz merge no `main` muitas vezes por dia, e o Glossia fez exatamente o que construímos para que fizesse: traduzia cada mudança e enviava cada arquivo assim que estava pronto. O resultado era um novo pull request para quase cada merge, cada um com cerca de 150 commits e uma fila de CI cheia de verificações que ninguém havia pedido. Algumas páginas de documentação deles também voltavam com componentes e alertas expostos em texto puro. Não era a experiência silenciosa de plano de fundo sobre a qual continuávamos falando.

Isso doeu, porque sempre dissemos que o melhor sistema de tradução é aquele com o qual você não precisa se preocupar. Uma pull request que inunda sua CI ou estraga sua documentação é o oposto disso. Então, voltamos e repensamos como as traduções alcançam seu repositório.

O Glossia agora mantém um único pull request por projeto e o amplia conforme seu conteúdo muda. Ele lê os arquivos de travamento já presentes nessa branch, então só traduz o que é novo e envia em lotes em vez de arquivo por arquivo. Em um repositório como o do Tuist, isso resulta em poucos pushes onde antes havia cento e cinquenta.

Também paramos de mexer em partes dos seus documentos que não são nossas. O Glossia costumava reconstruir cada página que traduzia, e qualquer coisa que não entendeu completamente, como um componente Phoenix ou um alerta do GitHub, poderia sair do outro lado exposta em texto puro. Agora, ele apenas substitui as frases que traduziu e deixa o resto exatamente como você escreveu. Havia um bom efeito colateral que não esperávamos: porque o modelo agora vê frases inteiras e o resto da página, as traduções leem melhor. No japonês, um link não precisa mais ficar estranho onde estava na frase em inglês.

Por fim, o pull request agora informa o que aconteceu. Quais idiomas e arquivos foram traduzidos, de quais commits, como pontuaram, quais termos de glossário os moldaram e quais coisas, se houverem, precisam da sua atenção. Pensamos nisso como a nota que um colega cuidadoso deixaria para você antes de pedir uma revisão.

Agradecemos à equipe do Tuist pela paciência enquanto resolvemos isso. Se o Glossia ficar no seu caminho dessa forma, gostaríamos de ouvir sobre isso.
