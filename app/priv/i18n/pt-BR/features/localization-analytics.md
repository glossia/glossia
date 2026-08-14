%{
  title: "Análises de localização",
  summary: "Veja quais idiomas e países seus visitantes realmente demandam e onde existe uma lacuna de localização antes de investir em uma nova localidade.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Oportunidade, não vaidade", description: "Os painéis são estruturados em torno da lacuna de localização: a parcela do tráfego que demanda um idioma ainda não oferecido.", icon: "globe"},
    %{title: "Sem cookies por concepção", description: "Sem cookies, identificação por impressão digital ou banners de consentimento. Os visitantes únicos são identificados por um hash com rotação diária que não pode ser associado entre dias.", icon: "zap"},
    %{title: "Uma linha para instalar", description: "Adicione uma única tag de script ao seu site e a Glossia começa a medir automaticamente. Distribua via npm ou CDN.", icon: "code"}
  ]
}
---
## Decida seu próximo idioma com base em dados

A maioria das equipes escolhe os idiomas de destino com base na intuição. As análises de localização substituem essa abordagem por dados concretos. Adicione o kit de desenvolvimento de software (SDK) para web e a Glossia mostrará os idiomas solicitados pelos navegadores dos visitantes, os países de origem e, principalmente, a sobreposição com os idiomas que você já oferece.

A principal métrica é a **lacuna de localização**: a porcentagem de visitantes cujo idioma preferido não possui uma tradução disponível. Analise-a por país, origem de referência e página para identificar exatamente onde se concentra a demanda não atendida e qual novo idioma teria o maior impacto.

## Privacidade sem concessões

As análises da Glossia coletam somente os dados necessários e não armazenam informações identificáveis. O navegador envia o endereço da página, a origem de referência, os idiomas preferidos, o fuso horário e o tamanho da tela. O servidor identifica o visitante único por meio de um hash do endereço IP e do User-Agent, renovado diariamente, e depois descarta esses dados. Nenhum cookie é definido, nenhuma impressão digital é criada e nenhum visitante pode ser rastreado entre dias ou sites.

O resultado são análises que você pode disponibilizar sem um banner de consentimento, em conformidade com as expectativas de privacidade dos seus visitantes internacionais.

## Instale em segundos

Adicione uma linha ao seu site e a Glossia começará a coletar métricas:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Prefere npm? Instale `@glossia/web` e chame `init({ domain })`. Em ambos os casos, as visualizações de página, a navegação no lado do cliente e os eventos personalizados são enviados ao mesmo painel que classifica suas oportunidades de localização.