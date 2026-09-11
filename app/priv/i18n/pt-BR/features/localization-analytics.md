%{
  title: "Análises de localização",
  summary:
    "Veja quais idiomas e países seus visitantes realmente desejam e onde você tem uma lacuna de localização, antes de investir em um novo idioma.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Começar",
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
        "Sem cookies, sem fingerprinting, sem banners de consentimento. Visitantes únicos vêm de um hash rotativo diário que não pode ser vinculado entre dias.",
      icon: "zap"
    },
    %{
      title: "Uma linha para instalar",
      description:
        "Insira uma única tag de script no seu site e a Glossia mede-se sozinha. Publique via npm ou CDN.",
      icon: "code"
    }
  ]
}
---
## Decida o próximo locale com dados

A maioria das equipes escolhe idiomas-alvo baseando-se apenas na intuição. A análise de localização substitui isso por sinal. Adicione o web SDK e o Glossia mostrará a você os idiomas que os navegadores de seus visitantes solicitam, os países de origem deles e, crucialmente, a sobreposição com os idiomas que você já suporta.

A principal métrica é a **lacuna de localização**: a porcentagem de visitantes cujos idiomas preferidos não possuem tradução suportada. Aprofunde-se nela por país, por referrer e por página para ver exatamente onde a demanda subatendida se concentra e qual novo locale trará impacto.

## Privacidade sem compromissos

A análise do Glossia não coleta nada que não seja necessário e não armazena nada identificável. O navegador envia o URL da página, referrer, idiomas preferidos, fuso horário e tamanho da tela. O servidor extrai o visitante único de um hash rotacionado diariamente do IP e User-Agent e depois o descarta. Nenhum cookie é definido, nada é rastreado por impressão digital e nenhum visitante pode ser rastreado entre dias ou entre sites.

O resultado é uma análise que você pode lançar sem um banner de consentimento, alinhada com as expectativas de privacidade que seus visitantes internacionais já têm.

## Instale em segundos

Adicione uma linha ao seu site e o Glossia começa a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Prefere npm? Instale `@glossia/web` e chame `init({ domain })`. De qualquer forma, visualizações de página, navegação do lado do cliente e eventos personalizados fluem para o mesmo painel que classifica suas oportunidades de localização.