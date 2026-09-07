%{
  title: "Análise de localização",
  summary:
    "Veja quais idiomas e países seus visitantes realmente desejam e onde há uma lacuna de localização antes de investir em um novo local.",
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
      icon: "Raio"
    },
    %{
      title: "Uma linha para instalar",
      description:
        "Adicione uma única tag script ao seu site e o Glossia mede-se. Envie via npm ou CDN.",
      icon: "Código"
    }
  ]
}
---
## Defina seu próximo idioma com base nos dados

A maioria das equipes escolhe idiomas-alvo por intuição. A análise de localização substitui isso por sinal. Adicione o SDK web e o Glossia mostrará os idiomas que os navegadores de seus visitantes solicitam, os países de origem deles e, crucialmente, a sobreposição com os idiomas que você já suporta.

O indicador principal é a **lacuna de localização**: a porcentagem de seus visitantes cujo idioma preferido não tem tradução suportada. Analise-o por país, por referrer e por página para ver exatamente onde a demanda não atendida se concentra e qual novo idioma faz a diferença.

## Privacidade sem concessões

A análise de dados do Glossia não coleta nada de que não precisa e não armazena nada identificável. O navegador envia o URL da página, o referrer, os idiomas preferidos, o fuso horário e o tamanho da tela. O servidor deriva o visitante único de um hash rotado diariamente do IP e User-Agent, em seguida, descarta-os. Nenhum cookie é configurado, nada é identificado por impressão digital e nenhum visitante pode ser rastreado entre dias ou entre sites.

O resultado é uma análise que você pode publicar sem um banner de consentimento, alinhada às expectativas de privacidade que seus visitantes internacionais já têm.

## Instale em segundos

Adicione uma linha ao seu site e o Glossia começa a medir:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Prefere npm? Instale `@glossia/web` e chame `init({ domain })`. De qualquer forma, visualizações de página, navegação do lado do cliente e eventos personalizados fluem para o mesmo painel que classifica suas oportunidades de localização.