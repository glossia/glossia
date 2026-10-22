%{
  title: "Pull requests de tradução mais calmas",
  summary:
    "O que aprendemos ao deixar o Glossia à solta em um repositório movimentado e como os pull requests de tradução mudaram por isso."
}
---

Você aprende bastante na primeira vez que sua ferramenta encontra um repositório real. Para nós, foi o Tuist. A equipe deles funde ao `main` muitas vezes por dia, e o Glossia fez exatamente o que construímos para que ele fizesse: traduziu toda a mudança e enviou cada arquivo tão logo estivesse pronto. O resultado foi uma nova pull request para quase cada mesclagem, cada uma com cerca de 150 commits, e uma fila de CI cheia de verificações que ninguém tinha solicitado. Algumas das páginas da documentação deles também voltaram com componentes e alertas escapados para texto simples. Não a experiência silenciosa e de fundo que frequentemente mencionamos.

Isso incomodou, pois sempre dissemos que o melhor sistema de tradução é aquele com o qual você não precisa se preocupar. Uma pull request que alaga a sua CI ou estraga sua documentação é o oposto disso. Então, voltamos e repensamos como as traduções atingem o seu repositório.

O Glossia agora mantém uma única pull request por projeto e a expande conforme seus conteúdos mudam. Ele lê os arquivos de bloqueio já naquela ramificação, portanto, apenas traduz o que é novo e faz os envios em lotes em vez de arquivo por arquivo. Em um repositório como o do Tuist, isso resulta em alguns envios onde antes havia cento e cinquenta.

Também paramos de tocar em partes dos seus documentos que não são nossas de tocar. O Glossia costumava reconstruir cada página que traduzia, e qualquer coisa que não compreendesse totalmente, como um componente Phoenix ou um alerta do GitHub, poderia sair do outro lado escapada. Agora, ele apenas troca as frases que traduziu e deixa tudo o resto exatamente como você escreveu. Houve um efeito colateral agradável que não esperávamos: porque o modelo agora vê frases inteiras e o resto da página, as traduções leem melhor. Em japonês, um link não precisa mais ficar no lugar estranho onde estava na frase em inglês.

Finalmente, a pull request agora te diz o que aconteceu. Quais idiomas e arquivos foram traduzidos, de quais commits, como foram pontuados, quais termos de glossário os moldaram e o que, se houver, precisa da sua atenção. Nós a vemos como a nota que um colega cuidadoso deixaria para você antes de solicitar uma revisão.

Graças à equipe do Tuist pela paciência enquanto resolvíamos isso. Se o Glossia atrapalhar você dessa forma, gostaríamos de ouvir sobre isso.
