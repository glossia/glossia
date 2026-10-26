%{
  title: "Análises de localização",
  summary:
    "Veja quais idiomas e países seus visitantes realmente desejam, e onde você tem uma lacuna de localização, antes de investir em um novo idioma.",
  order: 6,
  icon: "Globo",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidade, não vaidade",
      description:
        "Os painéis são construídos em torno da lacuna de localização: a parcela do tráfego que deseja um idioma que você ainda não atende.",
      icon: "Globo"
    },
    %{
      title: "Sem cookies por design",
      description:
        "Sem cookies, sem rastreamento, sem banners de consentimento. Visitantes únicos vêm de um hash rotativo diário que não pode ser vinculado entre dias.",
      icon: "Rápido"
    },
    %{
      title: "Uma linha para instalar",
      description:
        "Insira uma única tag de script no seu site e o Glossia gera suas próprias métricas. Lance via npm ou CDN.",
      icon: "Código"
    }
  ]
}
---

## Decida seu próximo idioma com dados

A maioria das equipes escolhe idiomas-alvo por intuição. A análise de localização substitui isso por dados concretos. Adicione o SDK web e o Glossia mostrará os idiomas que os navegadores dos seus visitantes solicitam, os países de origem e, crucialmente, a sobreposição com os idiomas que você já suporta.

O indicador principal é a **lacuna de localização**: a porcentagem dos seus visitantes cujo idioma preferido não possui tradução suportada. Analise-o em profundidade por país, por remetente e por página para identificar exatamente onde a demanda não atendida se concentra e qual novo idioma faria diferença.

## Privacidade sem compromissos

A análise do Glossia não coleta nada que não seja necessário e não armazena nada identificável. O navegador envia a URL da página, o remetente, idiomas preferidos, fuso horário e tamanho da tela. O servidor deriva o visitante único a partir de um hash rotacionado diariamente do IP e do User-Agent, em seguida o descarta. Nenhum cookie é definido, nada é identificado digitalmente e nenhum visitante pode ser rastreado ao longo dos dias ou entre sites.

O resultado é uma análise que você pode implementar sem um banner de consentimento, alinhada com as expectativas de privacidade que seus visitantes internacionais já possuem.

## Instale em segundos

Adicione uma linha ao seu site e o Glossia começa a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Prefere npm? Instale `@glossia/web` e chame `init({ domain })`. De qualquer forma, visualizações de página, navegação do lado do cliente e eventos personalizados fluem para o mesmo painel que classifica suas oportunidades de localização.
