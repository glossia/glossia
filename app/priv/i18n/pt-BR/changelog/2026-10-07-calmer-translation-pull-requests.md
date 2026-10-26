%{
  title: "Solicitações de tradução mais tranquilas",
  summary:
    "O que aprendemos ao deixar o Glossia solto em um repositório movimentado e como as solicitações de tradução mudaram por conta disso."
}
---

Você aprende muito na primeira vez que sua ferramenta encontra um repositório real. Para nós, isso foi o Tuist. Sua equipe faz merge para `main` muitas vezes por dia, e o Glossia fez exatamente o que construímos para ele fazer: traduziu cada alteração e enviou cada arquivo assim que estava pronto. O resultado foi um novo pull request para quase cada merge, cada um com cerca de 150 commits, e uma fila de CI cheia de verificações que ninguém havia solicitado. Algumas das páginas de docs deles também voltaram com componentes e alertas escapados para texto plano. Não a experiência silenciosa de fundo na qual continuamos falando.

Isso magoou, porque sempre dissemos que o melhor sistema de tradução é aquele do qual não é preciso se preocupar. Um pull request que inunda seu CI ou estaga seus docs é o oposto disso. Então voltamos e repensamos como as traduções chegam ao seu repositório.

O Glossia agora mantém um único pull request por projeto e o expande conforme seu conteúdo muda. Ele lê os lockfiles já naquele ramo, então ele só traduz o que é novo, e envia em lotes em vez de arquivo por arquivo. Em um repositório como o do Tuist, isso é uma pequena quantidade de envios onde antes havia cento e cinquenta.

Também paramos de mexer em partes de seus documentos que não são de nossa responsabilidade. O Glossia costumava reconstruir cada página que traduzia, e qualquer coisa que não compreendesse totalmente, como um componente Phoenix ou um alerta GitHub, poderia sair do outro lado escapada. Agora ele só substitui as frases que traduziu e deixa tudo o resto exatamente como você o escreveu. Houve um efeito colateral agradável que não esperávamos: porque o modelo agora vê frases inteiras e o resto da página, as traduções leem melhor. Em japonês, um link não precisa mais se posicionar constrangedamente onde estava na frase em inglês.

Finalmente, o pull request agora informa o que aconteceu. Quais idiomas e arquivos foram traduzidos, de quais commits, como foram pontuados, quais termos do glossário os formaram e o que, se houver, precisa da sua atenção. Pensamos nisso como a nota que um colega cuidadoso deixaria para você antes de solicitar uma revisão.

Agradecemos à equipe do Tuist pela paciência enquanto descobríamos isso. Se o Glossia jamais atrapalhar seu jeito de trabalhar dessa forma, adoraríamos ouvir sobre isso.
