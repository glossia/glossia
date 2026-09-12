%{
  title: "Análises de localização",
  summary:
    "Veja quais idiomas e países seus visitantes realmente desejam e onde há uma lacuna de localização antes de investir em uma nova localização.",
  order: 6,
  icon: "Globo",
  hero_cta_text: "Iniciar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Oportunidade, não vaidade",
      description:
        "Os painéis são construídos em torno da lacuna de localização: a proporção do tráfego que deseja um idioma que você ainda não oferece.",
      icon: "Globo"
    },
    %{
      title: "Sem cookies por design",
      description:
        "Sem cookies, sem rastreamento de impressão digital, sem banners de consentimento. Visitantes únicos vêm de um hash rotacionado diariamente que não pode ser vinculado entre dias.",
      icon: "Relâmpago"
    },
    %{
      title: "Uma linha para instalar",
      description:
        "Insira uma tag de script no seu site e o Glossia se mede. Distribua via npm ou CDN.",
      icon: "Código"
    }
  ]
}
---
## Decida o próximo idioma com dados

A maioria das equipes escolhe idiomas-alvo por intuição. Analytics de localização substitui isso por sinal. Adicione o SDK web e a Glossia mostrará os idiomas que os navegadores dos seus visitantes solicitam, os países de origem e, crucialmente, a sobreposição com os idiomas que você já suporta.

A métrica principal é a **brecha de localização**: a porcentagem dos seus visitantes cujo idioma preferido não tem tradução suportada. Analise a fundo por país, por referrer e por página para ver exatamente onde a demanda não atendida se concentra e qual novo idioma moveria a agulha.

## Privacidade sem concessões

A Glossia Analytics não coleta nada do que não precisa e não armazena nada identificável. O navegador envia a URL da página, o referrer, os idiomas preferidos, o fuso horário e o tamanho da tela. O servidor extrai o visitante único de um hash rotacionado diariamente do IP e do User-Agent, e depois os descarta. Nenhum cookie é definido, nada é fingerprinted, e nenhum visitante pode ser rastreado entre dias ou entre sites.

O resultado é um conjunto de análises que você pode implementar sem um banner de consentimento, alinhado às expectativas de privacidade que seus visitantes internacionais já têm.

## Instale em segundos

Adicione uma linha ao seu site e o Glossia começa a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Prefere npm? Instale `@glossia/web` e chame `init({ domain })`. De qualquer forma, visualizações de página, navegação do lado do cliente e eventos personalizados fluem para o mesmo painel que classifica suas oportunidades de localização.