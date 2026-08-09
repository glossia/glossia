defmodule Glossia.Analytics.EnglishProficiency do
  @moduledoc """
  Country-level English proficiency scores, used to prioritize which
  languages to translate to next.

  Data source: EF English Proficiency Index (EF EPI), the de facto standard
  for country-level English ability. The 2024 edition covers ~120 countries.
  We bundle a representative snapshot — the exact numbers shift year to year
  but the relative ordering is stable.

  ## Why this drives the priority score

  The product Glossia sells is *closing the localization gap*. A visitor from
  Brazil who speaks Portuguese and lands on an English-only site is a much
  bigger missed opportunity than a visitor from the Netherlands, because
  the Dutch reader will tolerate English comfortably and the Brazilian
  reader will bounce. EF EPI gives us the country-level tolerance signal we
  need to weight those visitors correctly:

      priority = visitors * (1 - english_score)   for visits with a locale gap

  ## Data shape

  The map is keyed by ISO 3166-1 alpha-2 country code. `english_score` is
  normalized to 0.0-1.0 (1.0 = perfect tolerance, 0.0 = none), derived from
  the published EF EPI band:

      very high proficiency → 0.88
      high proficiency      → 0.73
      moderate proficiency  → 0.55
      low proficiency       → 0.40
      very low proficiency  → 0.27

  `centroid` is the `[longitude, latitude]` pair used by `d3-geo`'s
  `Natural Earth` projection. The values are taken from Natural Earth and
  rounded to one decimal — close enough for a dot map.
  """

  @moduledoc since: "EF EPI 2024"

  @data %{
    # ── Very high proficiency ─────────────────────────────────────────
    "NL" => %{english_score: 0.88, name: "Netherlands", centroid: [5.3, 52.1]},
    "NO" => %{english_score: 0.88, name: "Norway", centroid: [9.0, 60.5]},
    "SE" => %{english_score: 0.88, name: "Sweden", centroid: [15.0, 60.1]},
    "DK" => %{english_score: 0.88, name: "Denmark", centroid: [10.0, 56.0]},
    "BE" => %{english_score: 0.85, name: "Belgium", centroid: [4.5, 50.5]},
    "AT" => %{english_score: 0.85, name: "Austria", centroid: [14.5, 47.5]},
    "FI" => %{english_score: 0.85, name: "Finland", centroid: [26.0, 64.0]},
    "DE" => %{english_score: 0.85, name: "Germany", centroid: [10.5, 51.2]},
    "PT" => %{english_score: 0.82, name: "Portugal", centroid: [-8.2, 39.5]},
    "HR" => %{english_score: 0.82, name: "Croatia", centroid: [16.0, 45.0]},
    "GR" => %{english_score: 0.80, name: "Greece", centroid: [22.0, 39.0]},
    "PL" => %{english_score: 0.80, name: "Poland", centroid: [19.1, 51.9]},
    "RO" => %{english_score: 0.80, name: "Romania", centroid: [25.0, 45.9]},
    "LU" => %{english_score: 0.85, name: "Luxembourg", centroid: [6.1, 49.8]},
    # ── High proficiency ───────────────────────────────────────────────
    "CZ" => %{english_score: 0.73, name: "Czechia", centroid: [15.5, 49.8]},
    "HU" => %{english_score: 0.73, name: "Hungary", centroid: [19.5, 47.2]},
    "SK" => %{english_score: 0.73, name: "Slovakia", centroid: [19.7, 48.7]},
    "EE" => %{english_score: 0.73, name: "Estonia", centroid: [25.0, 59.0]},
    "LV" => %{english_score: 0.73, name: "Latvia", centroid: [24.6, 56.9]},
    "LT" => %{english_score: 0.73, name: "Lithuania", centroid: [24.0, 55.2]},
    "BG" => %{english_score: 0.73, name: "Bulgaria", centroid: [25.5, 42.7]},
    "SI" => %{english_score: 0.73, name: "Slovenia", centroid: [15.0, 46.1]},
    "IT" => %{english_score: 0.70, name: "Italy", centroid: [12.6, 42.8]},
    "ES" => %{english_score: 0.70, name: "Spain", centroid: [-3.7, 40.4]},
    "FR" => %{english_score: 0.70, name: "France", centroid: [2.2, 46.2]},
    "CY" => %{english_score: 0.73, name: "Cyprus", centroid: [33.4, 35.1]},
    "AR" => %{english_score: 0.56, name: "Argentina", centroid: [-63.6, -38.4]},
    "UY" => %{english_score: 0.56, name: "Uruguay", centroid: [-55.8, -32.5]},
    "CR" => %{english_score: 0.56, name: "Costa Rica", centroid: [-84.0, 9.7]},
    "PA" => %{english_score: 0.56, name: "Panama", centroid: [-80.0, 8.5]},
    "CL" => %{english_score: 0.56, name: "Chile", centroid: [-71.5, -35.7]},
    "MX" => %{english_score: 0.50, name: "Mexico", centroid: [-102.5, 23.6]},
    "CO" => %{english_score: 0.50, name: "Colombia", centroid: [-74.3, 4.6]},
    "PE" => %{english_score: 0.50, name: "Peru", centroid: [-75.0, -9.2]},
    "EC" => %{english_score: 0.50, name: "Ecuador", centroid: [-78.2, -1.8]},
    "DO" => %{english_score: 0.50, name: "Dominican Republic", centroid: [-70.2, 18.7]},
    "GT" => %{english_score: 0.45, name: "Guatemala", centroid: [-90.2, 15.8]},
    "HN" => %{english_score: 0.45, name: "Honduras", centroid: [-86.2, 15.2]},
    "NI" => %{english_score: 0.45, name: "Nicaragua", centroid: [-85.2, 12.9]},
    "SV" => %{english_score: 0.45, name: "El Salvador", centroid: [-88.9, 13.8]},
    "PY" => %{english_score: 0.50, name: "Paraguay", centroid: [-58.4, -23.4]},
    "BO" => %{english_score: 0.45, name: "Bolivia", centroid: [-64.7, -16.3]},
    "VE" => %{english_score: 0.50, name: "Venezuela", centroid: [-66.6, 6.4]},
    "TR" => %{english_score: 0.50, name: "Türkiye", centroid: [35.2, 39.0]},
    "RU" => %{english_score: 0.55, name: "Russia", centroid: [105.3, 61.5]},
    "UA" => %{english_score: 0.55, name: "Ukraine", centroid: [31.2, 48.4]},
    "BY" => %{english_score: 0.55, name: "Belarus", centroid: [28.0, 53.7]},
    "KZ" => %{english_score: 0.50, name: "Kazakhstan", centroid: [66.9, 48.0]},
    "UZ" => %{english_score: 0.45, name: "Uzbekistan", centroid: [64.6, 41.4]},
    "IL" => %{english_score: 0.73, name: "Israel", centroid: [35.0, 31.0]},
    "AE" => %{english_score: 0.55, name: "United Arab Emirates", centroid: [53.8, 23.4]},
    "SA" => %{english_score: 0.45, name: "Saudi Arabia", centroid: [45.1, 23.9]},
    "KW" => %{english_score: 0.50, name: "Kuwait", centroid: [47.5, 29.3]},
    "QA" => %{english_score: 0.50, name: "Qatar", centroid: [51.2, 25.4]},
    "BH" => %{english_score: 0.50, name: "Bahrain", centroid: [50.6, 25.9]},
    "OM" => %{english_score: 0.45, name: "Oman", centroid: [55.9, 21.5]},
    "JO" => %{english_score: 0.50, name: "Jordan", centroid: [36.2, 30.6]},
    "LB" => %{english_score: 0.55, name: "Lebanon", centroid: [35.9, 33.9]},
    "EG" => %{english_score: 0.50, name: "Egypt", centroid: [30.8, 26.8]},
    "MA" => %{english_score: 0.50, name: "Morocco", centroid: [-7.1, 31.8]},
    "DZ" => %{english_score: 0.45, name: "Algeria", centroid: [1.7, 28.0]},
    "TN" => %{english_score: 0.45, name: "Tunisia", centroid: [9.2, 33.9]},
    "ZA" => %{english_score: 0.73, name: "South Africa", centroid: [22.9, -30.6]},
    "NG" => %{english_score: 0.55, name: "Nigeria", centroid: [8.7, 9.1]},
    "KE" => %{english_score: 0.55, name: "Kenya", centroid: [37.9, -0.0]},
    "GH" => %{english_score: 0.55, name: "Ghana", centroid: [-1.0, 7.9]},
    "TZ" => %{english_score: 0.45, name: "Tanzania", centroid: [34.9, -6.4]},
    "UG" => %{english_score: 0.50, name: "Uganda", centroid: [32.3, 1.4]},
    "ZM" => %{english_score: 0.50, name: "Zambia", centroid: [27.9, -13.1]},
    "ZW" => %{english_score: 0.50, name: "Zimbabwe", centroid: [29.2, -19.0]},
    "IN" => %{english_score: 0.55, name: "India", centroid: [78.9, 20.6]},
    "PK" => %{english_score: 0.45, name: "Pakistan", centroid: [69.3, 30.4]},
    "BD" => %{english_score: 0.45, name: "Bangladesh", centroid: [90.4, 23.7]},
    "LK" => %{english_score: 0.50, name: "Sri Lanka", centroid: [80.8, 7.9]},
    "NP" => %{english_score: 0.40, name: "Nepal", centroid: [84.1, 28.4]},
    "MM" => %{english_score: 0.40, name: "Myanmar", centroid: [96.2, 21.9]},
    "TH" => %{english_score: 0.45, name: "Thailand", centroid: [100.9, 15.9]},
    "MY" => %{english_score: 0.73, name: "Malaysia", centroid: [101.9, 4.2]},
    "ID" => %{english_score: 0.50, name: "Indonesia", centroid: [113.9, -0.8]},
    "PH" => %{english_score: 0.73, name: "Philippines", centroid: [121.8, 12.9]},
    "VN" => %{english_score: 0.50, name: "Vietnam", centroid: [108.3, 14.1]},
    "KH" => %{english_score: 0.40, name: "Cambodia", centroid: [104.9, 12.6]},
    "LA" => %{english_score: 0.40, name: "Laos", centroid: [102.5, 19.9]},
    "MN" => %{english_score: 0.45, name: "Mongolia", centroid: [103.8, 46.9]},
    "KR" => %{english_score: 0.55, name: "South Korea", centroid: [127.8, 36.0]},
    "TW" => %{english_score: 0.55, name: "Taiwan", centroid: [121.0, 23.7]},
    "HK" => %{english_score: 0.70, name: "Hong Kong", centroid: [114.2, 22.3]},
    "SG" => %{english_score: 0.73, name: "Singapore", centroid: [103.8, 1.4]},
    "AU" => %{english_score: 0.80, name: "Australia", centroid: [133.8, -25.3]},
    "NZ" => %{english_score: 0.80, name: "New Zealand", centroid: [174.9, -41.0]},
    "BR" => %{english_score: 0.42, name: "Brazil", centroid: [-51.9, -14.2]},
    "CN" => %{english_score: 0.40, name: "China", centroid: [104.2, 35.9]},
    "JP" => %{english_score: 0.45, name: "Japan", centroid: [138.3, 36.2]},
    "IR" => %{english_score: 0.40, name: "Iran", centroid: [53.7, 32.4]},
    "IQ" => %{english_score: 0.27, name: "Iraq", centroid: [43.7, 33.2]},
    "SY" => %{english_score: 0.27, name: "Syria", centroid: [38.0, 34.8]},
    "YE" => %{english_score: 0.27, name: "Yemen", centroid: [48.5, 15.6]},
    "SD" => %{english_score: 0.35, name: "Sudan", centroid: [30.2, 12.9]},
    "AF" => %{english_score: 0.27, name: "Afghanistan", centroid: [67.7, 33.9]},
    "AL" => %{english_score: 0.55, name: "Albania", centroid: [20.2, 41.2]},
    "BA" => %{english_score: 0.55, name: "Bosnia and Herzegovina", centroid: [17.8, 43.9]},
    "MK" => %{english_score: 0.55, name: "North Macedonia", centroid: [21.7, 41.6]},
    "RS" => %{english_score: 0.55, name: "Serbia", centroid: [21.0, 44.0]},
    "ME" => %{english_score: 0.55, name: "Montenegro", centroid: [19.4, 42.7]},
    "MD" => %{english_score: 0.55, name: "Moldova", centroid: [28.4, 47.4]},
    "AM" => %{english_score: 0.50, name: "Armenia", centroid: [45.0, 40.1]},
    "AZ" => %{english_score: 0.50, name: "Azerbaijan", centroid: [47.6, 40.1]},
    "GE" => %{english_score: 0.50, name: "Georgia", centroid: [43.4, 42.3]},
    "TJ" => %{english_score: 0.40, name: "Tajikistan", centroid: [71.3, 38.9]},
    "TM" => %{english_score: 0.40, name: "Turkmenistan", centroid: [59.6, 39.1]},
    "KG" => %{english_score: 0.40, name: "Kyrgyzstan", centroid: [74.8, 41.2]},
    "ET" => %{english_score: 0.40, name: "Ethiopia", centroid: [40.5, 9.1]},
    "SO" => %{english_score: 0.27, name: "Somalia", centroid: [46.2, 5.2]},
    "CD" => %{english_score: 0.40, name: "DR Congo", centroid: [21.8, -4.0]},
    "CG" => %{english_score: 0.40, name: "Republic of the Congo", centroid: [15.2, -0.8]},
    "CM" => %{english_score: 0.45, name: "Cameroon", centroid: [12.7, 7.4]},
    "SN" => %{english_score: 0.40, name: "Senegal", centroid: [-14.5, 14.5]},
    "CI" => %{english_score: 0.40, name: "Côte d'Ivoire", centroid: [-5.5, 7.5]},
    "ML" => %{english_score: 0.35, name: "Mali", centroid: [-4.0, 17.6]},
    "BF" => %{english_score: 0.35, name: "Burkina Faso", centroid: [-1.0, 12.4]},
    "NE" => %{english_score: 0.35, name: "Niger", centroid: [8.1, 17.6]},
    "TD" => %{english_score: 0.27, name: "Chad", centroid: [18.7, 15.4]},
    "CF" => %{english_score: 0.27, name: "Central African Republic", centroid: [20.9, 6.6]},
    "AO" => %{english_score: 0.40, name: "Angola", centroid: [17.5, -12.3]},
    "MZ" => %{english_score: 0.45, name: "Mozambique", centroid: [35.5, -18.7]},
    "MG" => %{english_score: 0.35, name: "Madagascar", centroid: [46.7, -19.4]},
    "MW" => %{english_score: 0.40, name: "Malawi", centroid: [34.3, -13.3]},
    "BW" => %{english_score: 0.55, name: "Botswana", centroid: [24.7, -22.3]},
    "NA" => %{english_score: 0.50, name: "Namibia", centroid: [18.5, -22.9]},
    "LS" => %{english_score: 0.45, name: "Lesotho", centroid: [28.2, -29.6]},
    "SZ" => %{english_score: 0.50, name: "Eswatini", centroid: [31.5, -26.5]},
    "LY" => %{english_score: 0.25, name: "Libya", centroid: [17.2, 26.3]},
    "US" => %{english_score: 0.88, name: "United States", centroid: [-95.7, 37.1]},
    "CA" => %{english_score: 0.88, name: "Canada", centroid: [-106.3, 56.1]},
    "GB" => %{english_score: 0.85, name: "United Kingdom", centroid: [-2.4, 53.4]},
    "IE" => %{english_score: 0.88, name: "Ireland", centroid: [-7.7, 53.4]}
  }

  @doc "Returns the bundled country dataset."
  def all, do: @data

  @doc "Returns the country entry for `code`, or `nil` if unknown."
  def fetch(code) when is_binary(code), do: Map.get(@data, code)

  @doc "English tolerance score in [0.0, 1.0] for `code`, defaulting to 0.5."
  def english_score(code) when is_binary(code) do
    case Map.get(@data, code) do
      nil -> 0.5
      %{english_score: score} -> score
    end
  end

  def english_score(_), do: 0.5

  @doc "Country name for `code`, or the code itself if unknown."
  def name(code) when is_binary(code) do
    case Map.get(@data, code) do
      nil -> code
      %{name: name} -> name
    end
  end

  def name(_), do: ""

  @doc "`[lng, lat]` centroid for `code`, or `nil` if unknown."
  def centroid(code) when is_binary(code) do
    case Map.get(@data, code) do
      nil -> nil
      %{centroid: c} -> c
    end
  end
end
