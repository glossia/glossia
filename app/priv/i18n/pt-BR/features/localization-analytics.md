%{
  title: "Análise de localização",
  summary:
    "Veja quais idiomas e países seus visitantes realmente desejam e onde você tem uma lacuna de localização, antes de investir em uma nova localidade.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Comece",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidade, não vaidade",
      description:
        "Os painéis são construídos em torno da lacuna de localização: a parte do tráfego que deseja um idioma que você ainda não oferece.",
      icon: "globe"
    },
    %{
      title: "Sem cookies por design",
      description:
        "Sem cookies, sem fingerprinting, sem banners de consentimento. Visitantes únicos provêm de um hash rotacionado diariamente que não pode ser correlacionado entre dias.",
      icon: "zap"
    },
    %{
      title: "Uma linha para instalar",
      description:
        "Adicione uma única tag de script ao seu site e o Glossia mede-se. Libere via npm ou CDN.",
      icon: "code"
    }
  ]
}
---

## Decida sua próxima localização com dados

A maioria das equipes escolhe idiomas-alvo baseada na intuição. A análise de localização substitui isso por dados concretos. Adicione o SDK web e o Glossia mostra os idiomas que os navegadores dos seus visitantes solicitam, os países de origem deles e, crucialmente, a sobreposição com os idiomas que você já suporta.

O indicador principal é o **lacuna de localização**: a porcentagem dos seus visitantes cujo idioma preferido não possui tradução suportada. Explore por país, por referrer e por página para ver exatamente onde a demanda não atendida se concentra e qual nova localização faria a diferença.

## Privacidade sem concessões

A análise do Glossia não coleta nada que não precise e não armazena nada identificável. O navegador envia a URL da página, o referrer, os idiomas preferidos, o fuso horário e o tamanho da tela. O servidor determina o visitante único a partir de um hash rotacionado diariamente do IP e do User-Agent, e então os descarta. Nenhum cookie é definido, nada é submetido a fingerprinting e nenhum visitante pode ser rastreado ao longo de dias ou entre sites.

O resultado é uma análise que você pode implementar sem um banner de consentimento, alinhada com as expectativas de privacidade que seus visitantes internacionais já possuem.

## Instale em segundos

Adicione uma linha ao seu site e o Glossia começará a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Prefere npm? Instale `@glossia/web` e chame `init({ domain })`. De qualquer forma, visualizações de página, navegação do lado do cliente e eventos personalizados fluem para o mesmo painel que classifica suas oportunidades de localização.
