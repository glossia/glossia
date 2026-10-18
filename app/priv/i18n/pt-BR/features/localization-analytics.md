%{
  title: "Análise de localização",
  summary:
    "Veja quais idiomas e países seus visitantes realmente desejam, e onde há uma lacuna de localização, antes de investir em uma nova localização.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidade, não vaidade",
      description:
        "Os painéis são construídos em torno da lacuna de localização: a parcela do tráfego que deseja um idioma que você ainda não atende.",
      icon: "globe"
    },
    %{
      title: "Sem cookies por design",
      description:
        "Sem cookies, sem rastreamento, sem banners de consentimento. Visitantes únicos vêm de um hash rotacionado diariamente que não pode ser vinculado entre dias.",
      icon: "zap"
    },
    %{
      title: "Uma linha para instalar",
      description:
        "Adicione uma única tag script em seu site e o Glossia faz a medição automaticamente. Disponibilize via npm ou CDN.",
      icon: "code"
    }
  ]
}
---

## Defina seu próximo idioma com dados

A maioria das equipes escolhe idiomas-alvo baseando-se apenas em palpite. A análise de localização substitui isso por sinal. Adicione o SDK web e o Glossia te mostrará os idiomas que os navegadores dos seus visitantes solicitam, os países de origem deles e, crucialmente, a sobreposição com os idiomas que você já suporta.

O indicador principal é a **lacuna de localização**: a porcentagem dos seus visitantes cujos idiomas preferidos não têm tradução suportada. Explore por país, por referência e por página para ver exatamente onde a demanda subatendida se concentra e qual novo idioma moveria a agulha.

## Privacidade sem concessões

A análise do Glossia não coleta nada que não seja necessário e não armazena nada identificável. O navegador envia o URL da página, o referrer, os idiomas preferidos, o fuso horário e o tamanho da tela. O servidor deriva o visitante único a partir de um hash rotacionado diariamente do IP e do User-Agent, e depois os descarta. Não são definidos cookies, nada é fingerprinting e nenhum visitante pode ser rastreado entre dias ou entre sites.

O resultado é uma análise que você pode lançar sem um banner de consentimento, alinhada às expectativas de privacidade que seus visitantes internacionais já têm.

## Instale em segundos

Adicione uma linha ao seu site e o Glossia começa a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Prefere npm? Instale `@glossia/web` e chame `init({ domain })`. De qualquer forma, visualizações de página, navegação do lado do cliente e eventos personalizados fluem para o mesmo painel que classifica suas oportunidades de localização.
