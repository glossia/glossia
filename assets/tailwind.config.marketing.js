/** @type {import('tailwindcss').Config} */
const defaultTheme = require("tailwindcss/defaultTheme");
const colors = require("tailwindcss/colors");
const plugin = require("tailwindcss/plugin");

module.exports = {
  content: [
    "../js/**/*.js",
    "../lib/glossia_web/components/shared_components.ex",
    "../lib/glossia_web/components/marketing_components*",
    "../lib/glossia_web/components/marketing_layouts/*",
    "../lib/glossia_web/controllers/marketing_html/*",
    "../lib/glossia_web/controllers/error_html/*",
  ],
  theme: {
    fontSize: {
      xs: [
        "0.75rem",
        {
          lineHeight: "1rem",
        },
      ],
      sm: [
        "0.875rem",
        {
          lineHeight: "1.5rem",
        },
      ],
      base: [
        "1rem",
        {
          lineHeight: "1.75rem",
        },
      ],
      lg: [
        "1.125rem",
        {
          lineHeight: "2rem",
        },
      ],
      xl: [
        "1.25rem",
        {
          lineHeight: "2rem",
        },
      ],
      "2xl": [
        "1.5rem",
        {
          lineHeight: "2rem",
        },
      ],
      "3xl": [
        "2rem",
        {
          lineHeight: "2.5rem",
        },
      ],
      "4xl": [
        "2.5rem",
        {
          lineHeight: "3.5rem",
        },
      ],
      "5xl": [
        "3rem",
        {
          lineHeight: "3.5rem",
        },
      ],
      "6xl": [
        "3.75rem",
        {
          lineHeight: "1",
        },
      ],
      "7xl": [
        "4.5rem",
        {
          lineHeight: "1.1",
        },
      ],
      "8xl": [
        "6rem",
        {
          lineHeight: "1",
        },
      ],
      "9xl": [
        "8rem",
        {
          lineHeight: "1",
        },
      ],
      "10xl": [
        "8.5rem",
        {
          lineHeight: "1",
        },
      ],
      "11xl": [
        "9rem",
        {
          lineHeight: "1",
        },
      ],
      "12xl": [
        "9.5rem",
        {
          lineHeight: "1",
        },
      ],
      "13xl": [
        "10rem",
        {
          lineHeight: "1",
        },
      ],
      "14xl": [
        "11rem",
        {
          lineHeight: "1",
        },
      ],
      "15xl": [
        "12rem",
        {
          lineHeight: "1",
        },
      ],
      "16xl": [
        "13rem",
        {
          lineHeight: "1",
        },
      ],
      "17xl": [
        "14rem",
        {
          lineHeight: "1",
        },
      ],
      "18xl": [
        "15rem",
        {
          lineHeight: "1",
        },
      ],
    },
    extend: {
      backgroundImage: (theme) => ({
        screens: "url('/path-to/image.png')",
      }),
      boxShadow: {
        small: "3px 3px",
        DEFAULT: "5px 5px",
        large: "10px 10px",
      },

      colors: {
        black: "#141520",
        white: "#f5f5f5",
        orange: {
          50: "#FEF0EC",
          100: "#FDE4DE",
          200: "#FAC6B7",
          300: "#F8AB96",
          400: "#F58D70",
          500: "#F3734E",
          600: "#EF4010",
          700: "#B5310C",
          800: "#772008",
          900: "#3E1104",
        },
        green: {
          50: "#F8FBFC",
          100: "#F2F7F8",
          200: "#E1EDEF",
          300: "#D3E5E8",
          400: "#C6DDE2",
          500: "#B7D4DA",
          600: "#82B5BF",
          700: "#51919E",
          800: "#366068",
          900: "#1C3236",
        },
        lila: {
          50: "#FBFAFF",
          100: "#F7F5FF",
          200: "#EAE6FE",
          300: "#E2DCFE",
          400: "#D6CEFD",
          500: "#C8BEFD",
          600: "#B4A6FC",
          700: "#A08DFB",
          800: "#836BFA",
          900: "#5534F9",
        },
        yellow: {
          50: "#FFFDFA",
          100: "#FFFAF5",
          200: "#FFF5EB",
          300: "#FEEEDC",
          400: "#FEE9D2",
          500: "#FEE3C6",
          600: "#FDC991",
          700: "#FCA446",
          800: "#EC7C04",
          900: "#AA5903",
        },
        red: {
          50: "#FEFBFB",
          100: "#FDF7F8",
          200: "#FBEAED",
          300: "#F8DDE2",
          400: "#F6D0D7",
          500: "#F3C4CD",
          600: "#EEAAB7",
          700: "#E88D9D",
          800: "#DE5E75",
          900: "#BF2743",
        },
      },
      fontFamily: {
        sans: ["Source Sans Pro", ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require("@tailwindcss/typography"),
    require("@tailwindcss/forms"),
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),
  ],
};
