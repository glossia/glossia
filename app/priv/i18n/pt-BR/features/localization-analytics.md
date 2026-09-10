%{
  title: "Análises de localização",
  summary:
    "Veja quais idiomas e países seus visitantes realmente desejam e onde você tem uma lacuna de localização antes de investir em uma nova localização.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidade, não vaidade",
      description:
        "Painéis são construídos em torno da lacuna de localização: a parte do tráfego que deseja um idioma que você ainda não atende.",
      icon: "globe"
    },
    %{
      title: "Sem cookies por design",
      description:
        "Sem cookies, sem fingerprinting, sem banners de consentimento. Visitantes únicos vêm de um hash rotacionado diariamente que não pode ser vinculado entre os dias.",
      icon: "zap"
    },
    %{
      title: "Uma linha para instalar",
      description:
        "Adicione uma tag script ao seu site e o Glossia se mede. Distribua via npm ou CDN.",
      icon: "code"
    }
  ]
}
---
## Decida sua próxima localização com dados

A maioria das equipes escolhe idiomas-alvo por intuição. A análise de localização substitui isso por dados. Adicione o SDK web e o Glossia mostra os idiomas que os navegadores dos seus visitantes solicitam, os países de onde eles vêm e, crucialmente, a sobreposição com os idiomas que você já suporta.

A métrica principal é a **brecha de localização**: a porcentagem de seus visitantes cujos idiomas preferidos não possuem tradução suportada. Revise-a por país, por referrer e por página para ver exatamente onde a demanda não atendida se concentra e qual nova posição traria o melhor impacto.

## Privacidade sem compromissos

A análise do Glossia não coleta nada desnecessário e não armazena nada identificável. O navegador envia o URL da página, o referrer, os idiomas preferidos, o fuso horário e o tamanho da tela. O servidor deriva o visitante único a partir de um hash rotativo diário do IP e User-Agent, e os descarta em seguida. Nenhum cookie é definido, nada é identificado e nenhum visitante pode ser rastreado entre dias ou entre sites.

O resultado é uma análise que você pode lançar sem um banner de consentimento, alinhada às expectativas de privacidade que seus visitantes internacionais já possuem.

## Instale em segundos

Adicione uma linha ao seu site e o Glossia começa a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Prefere npm? Instale `@glossia/web` e chame `init({ domain })`. De qualquer forma, visualizações de página, navegação do lado do cliente e eventos personalizados fluem para o mesmo painel que classifica suas oportunidades de localização.