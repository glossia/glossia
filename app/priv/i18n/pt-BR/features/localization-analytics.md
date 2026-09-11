%{
  title: "Análises de localização",
  summary:
    "Veja quais idiomas e países seus visitantes realmente desejam e onde você possui uma lacuna de localização, antes de investir em um novo local.",
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
        "Sem cookies, sem fingerprinting, sem banners de consentimento. Visitantes únicos vêm de um hash rotacionado diariamente que não pode ser vinculado entre dias.",
      icon: "Rápido"
    },
    %{
      title: "Só uma linha para instalar",
      description:
        "Adicione uma tag script ao seu site e o Glossia mede por conta própria. Distribua via npm ou CDN.",
      icon: "Código"
    }
  ]
}
---
## Decida a próxima localização com dados

A maioria das equipes escolhe as línguas-alvo baseada em intuição. A análise de localização substitui isso por sinais. Adicione o SDK web e o Glossia mostrará as línguas que os navegadores dos seus visitantes solicitam, os países de onde eles vêm e, crucialmente, a sobreposição com as línguas que você já oferece suporte.

A métrica principal é a **lacuna de localização**: a porcentagem dos seus visitantes cuja linguagem preferida não tem tradução suportada. Examine-a por país, por referência e por página para ver exatamente onde a demanda não atendida se concentra e qual nova localização moverá a agulha.

## Privacidade sem concessões

A análise do Glossia não coleta nada que não precise e não armazena nada identificável. O navegador envia a URL da página, a referência, os idiomas preferidos, o fuso horário e o tamanho da tela. O servidor gera o visitante único a partir de um hash rotativo diário do IP e do User-Agent, e então os descarta. Nenhum cookie é definido, nenhum dado é submetido a fingerprinting e nenhum visitante pode ser rastreado de dia para dia ou entre sites.

O resultado é uma análise que você pode lançar sem um banner de consentimento, alinhada com as expectativas de privacidade que seus visitantes internacionais já possuem.

## Instale em segundos

Adicione uma linha ao seu site e o Glossia começa a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Prefere npm? Instale `@glossia/web` e chame `init({ domain })`. De qualquer forma, visualizações de página, navegação do lado do cliente e eventos personalizados fluem para o mesmo painel de controle que classifica suas oportunidades de localização.