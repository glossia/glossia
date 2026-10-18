%{
  title: "Pull requests de tradução mais calmas",
  summary:
    "O que aprendemos ao deixar o Glossia à solta em um repositório movimentado e como os pull requests de tradução mudaram por isso."
}
---

Você aprende muito na primeira vez que sua ferramenta se encontra com um repositório real. Para nós, isso foi o Tuist. A equipe deles faz merges para `main` inúmeras vezes ao dia, e o Glossia fez exatamente o que construímos para que fizesse: traduzia cada alteração e empurrava cada arquivo assim que estava pronto. O resultado foi um novo pull request para quase cada merge, cada um com cerca de 150 commits, e uma fila de CI cheia de verificações que ninguém havia pedido. Algumas páginas de documentação deles também retornavam com componentes e alertas escapados para texto plano. Não a experiência silenciosa e de plano de fundo sobre a qual constantemente conversamos.

Isso feriu, porque sempre dissemos que o melhor sistema de tradução é aquele no qual você não precisa pensar. Um pull request que sobrecarrega sua CI ou destrói sua documentação é o oposto disso. Então voltamos e repensamos como as traduções chegam ao seu repositório.

O Glossia agora mantém um único pull request por projeto e o expande conforme seu conteúdo muda. Ele lê os lockfiles já presentes naquela branch, então traduz apenas o que é novo e empurra em lotes em vez de arquivo por arquivo. Em um repositório como o do Tuist, isso é uma pequena quantidade de pushes onde anteriormentehou honestamente cem e cinquenta.

Também paramos de mexer em partes de sua documentação que não eram da nossa alçada. O Glossia costumava reconstruir cada página que traduzia, e qualquer coisa que não entendesse totalmente, como um componente Phoenix ou um alerta do GitHub, poderia sair do outro lado com conteúdo escapado. Agora ele apenas substitui as frases traduzidas e deixa o restante exatamente como você o escreveu. Havia um efeito colateral agradável que não esperávamos: porque o modelo agora vê frases inteiras e o resto da página, as traduções leem melhor. Em Japonês, um link não precisa mais ficar em um local desconfortável onde estava na frase em inglês.

Finalmente, o pull request agora te informa o que aconteceu. Quais idiomas e arquivos foram traduzidos, de quais commits, como pontuaram, quais termos do glossário os moldaram e o que, se houver algo, precisa da sua atenção. Pensamos nisso como a nota que um colega cuidadoso deixaria para você antes de solicitar uma revisão.

Agradecemos à equipe do Tuist pela paciência enquanto resolvíamos isso. Se o Glossia um dia se entrometer em seu caminho assim, gostaríamos de ouvir sobre isso.
