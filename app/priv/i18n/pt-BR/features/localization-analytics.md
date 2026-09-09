%{
  title: "Análises de localização",
  summary:
    "Veja quais idiomas e países seus visitantes realmente desejam, e onde há uma brecha de localização, antes de investir em uma nova localização.",
  order: 6,
  icon: "globo",
  hero_cta_text: "Começar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidade, não vaidade",
      description:
        "Os painéis são construídos em torno da brecha de localização: a parcela do tráfego que deseja um idioma que você ainda não oferece.",
      icon: "globo"
    },
    %{
      title: "Sem cookies por design",
      description:
        "Sem cookies, sem fingerprinting, sem banners de consentimento. Visitantes únicos origins de um hash rotacionado diariamente que não pode ser vinculado entre dias.",
      icon: "raio"
    },
    %{
      title: "Uma linha para instalar",
      description:
        "Adicione uma única tag script ao seu site e o Glossia mede por si mesmo. Publique via npm ou CDN.",
      icon: "código"
    }
  ]
}
---
## Decida sua próxima localidade com dados

A maior parte das equipes escolhe idiomas-alvo baseando-se no instinto. A análise de localização substitui isso por sinais. Adicione o SDK web e o Glossia mostra quais idiomas os navegadores de seus visitantes solicitam, os países de origem e, crucialmente, a sobreposição com os idiomas que você já suporta.

O indicador de destaque é o **lacuna de localização**: a porcentagem dos visitantes cujo idioma preferido não possui tradução suportada. Analise-a por país, por remetente e por página para ver exatamente onde a demanda não atendida se concentra e qual nova localidade moveria o ponteiro.

## Privacidade sem concessões

A análise do Glossia coleta nada que não precise e não armazena nada identificável. O navegador envia o URL da página, o remetente, idiomas preferidos, fuso horário e tamanho da tela. O servidor deriva o visitante único a partir de um hash rotativo diariamente do IP e do User-Agent, e então os descarta. Não são definidos cookies, nada é identificado por dispositivo e nenhum visitante pode ser rastreado ao longo de dias ou entre sites.

O resultado é uma análise que você pode lançar sem um banner de consentimento, alinhada com as expectativas de privacidade que seus visitantes internacionais já têm.

## Instale em segundos

Adicione uma linha ao seu site e o Glossia começará a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Prefere npm? Instale `@glossia/web` e chame `init({ domain })`. De qualquer forma, visualizações de página, navegação do lado do cliente e eventos personalizados fluem para o mesmo painel que classifica suas oportunidades de localização.