%{
  title: "Análise de localização",
  summary:
    "Veja quais idiomas e países seus visitantes realmente desejam e onde existe uma lacuna de localização, antes de investir em um novo idioma.",
  order: 6,
  icon: "Mundo",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidade, não vaidade",
      description:
        "Os painéis são construídos em torno da lacuna de localização: a parcela do tráfego que deseja um idioma que você ainda não oferece.",
      icon: "Mundo"
    },
    %{
      title: "Sem cookies por design",
      description:
        "Sem cookies, sem fingerprinting, sem banners de consentimento. Visitantes únicos provêm de um hash rotacionado diariamente que não pode ser vinculado entre dias.",
      icon: "Relâmpago"
    },
    %{
      title: "Uma linha para instalar",
      description:
        "Insira uma única tag script em seu site e a Glossia faz a medição. Publique via npm ou CDN.",
      icon: "Código"
    }
  ]
}
---
## Decida o próximo idioma com dados

A maioria das equipes escolhe idiomas-alvo baseando-se na intuição. A análise de localização substitui isso por sinais. Adicione o SDK da web e o Glossia mostrará os idiomas solicitados pelos navegadores dos seus visitantes, os países de origem e, crucialmente, a sobreposição com os idiomas que você já suporta.

O indicador principal é o **lacuna de localização**: a porcentagem dos visitantes cujos idiomas preferidos não possuem tradução suportada. Explore-a por país, por referrer e por página para ver exatamente onde a demanda subatendida se concentra e qual novo idioma moverá a agulha.

## Privacidade sem concessões

A análise do Glossia coleta apenas o necessário e nada identificável. O navegador envia a URL da página, referrer, idiomas preferidos, fuso horário e tamanho da tela. O servidor deriva o visitante único a partir de um hash rotativo diário do IP e User-Agent, e depois descarta-os. Nenhum cookie é definido, nada é rastreado por impressão digital e nenhum visitante pode ser monitorado entre dias ou sites.

O resultado é uma análise que você pode lançar sem um banner de consentimento, alinhada às expectativas de privacidade dos seus visitantes internacionais.

## Instale em segundos

Adicione uma linha ao seu site e Glossia começa a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Prefere npm? Instale `@glossia/web` e chame `init({ domain })`. De qualquer forma, visualizações de página, navegação do lado do cliente e eventos personalizados fluem para o mesmo painel que classifica suas oportunidades de localização.