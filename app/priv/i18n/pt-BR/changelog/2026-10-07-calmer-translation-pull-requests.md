%{
  title: "Solicitações de pull de tradução mais tranquilas",
  summary:
    "O que aprendemos ao deixar o Glossia solto em um repositório movimentado, e como as solicitações de pull de tradução mudaram por causa disso."
}
---

Você aprende muito na primeira vez que sua ferramenta conhece um repositório real. Para nós, isso foi o Tuist. A equipe deles faz merges para `main` muitas vezes por dia, e o Glossia fez exatamente o que construímos para fazer: traduziu cada alteração e enviou cada arquivo assim que ficou pronto. O resultado foi um novo pull request para quase cada merge, cada um com cerca de 150 commits, e uma fila de CI cheia de verificações que ninguém havia pedido. Algumas de suas páginas de documentação também voltaram com componentes e alertas que escaparam como texto plano. Não é a experiência tranquila e em segundo plano que continuamos falando sobre.

Isso doeu, porque sempre dissemos que o melhor sistema de tradução é um em que você não precisa pensar. Um pull request que alaga seu CI ou corrompe seus documentos é o oposto disso. Por isso, voltamos e repensamos como as traduções chegam ao seu repositório.

O Glossia agora mantém um único pull request por projeto e o expande conforme seu conteúdo muda. Ele lê os arquivos de lock já naquela branch, então traduz apenas o que é novo, e empurra em lotes em vez de arquivo por arquivo. Em um repositório como o do Tuist, são alguns poucos pushes onde antes havia cento e cinquenta.

Também paramos de tocar em partes da sua documentação que não deveríamos tocar. O Glossia costumava reconstruir cada página que traduzia, e qualquer coisa que não entendesse completamente, como um componente Phoenix ou um alerta do GitHub, poderia chegar do outro lado escapada. Agora ele apenas troca as sentenças que traduziu e deixa o resto exatamente como você escreveu. Havia um efeito colateral agradável que não esperávamos: porque o modelo agora vê frases inteiras e o resto da página, as traduções leem-se melhor. Em Japonês, um link não precisa mais ficar estranho onde estava na frase em inglês.

Por fim, o pull request agora diz o que aconteceu. Quais idiomas e arquivos foram traduzidos, de quais commits, como eles pontuaram, quais termos de glossário os moldaram e o que, se alguma coisa, precisa da sua atenção. Nós o vemos como a nota que um colaborador cuidadoso deixaria para você antes de pedir uma revisão.

Obrigado à equipe do Tuist pela paciência enquanto descobríamos isso. Se o Glossia nunca atrapalhar seu caminho dessa forma, adoraríamos ouvir sobre isso.
