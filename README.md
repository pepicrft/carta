# 🖼️ Carta

[![Hex.pm](https://img.shields.io/hexpm/v/carta.svg)](https://hex.pm/packages/carta)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/carta)
[![CI](https://github.com/pepicrft/carta/actions/workflows/carta.yml/badge.svg)](https://github.com/pepicrft/carta/actions/workflows/carta.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Generate images from HTML using a headless browser.

Carta renders HTML content in a headless browser and captures it as a JPEG image. It is backend-agnostic: any [Browse](https://hex.pm/packages/browse)-compatible browser works (e.g. [BrowseChrome](https://hex.pm/packages/browse_chrome), [BrowseServo](https://hex.pm/packages/browse_servo)).

**Use cases:** 🌐 Open Graph images · 📱 Social media cards · 📧 Email banners · 📜 Certificates · 🧾 Invoices · 🏷️ Badges · and anything you can build with HTML and CSS.

## 📦 Installation

Add `carta` and a browser backend to your dependencies:

```elixir
def deps do
  [
    {:carta, "~> 0.2.0"},
    {:browse_chrome, "~> 0.2"}
  ]
end
```

## 🔧 Setup

Start a browser pool in your application's supervision tree:

```elixir
# config/config.exs
config :browse_chrome,
  default_pool: MyApp.BrowserPool,
  pools: [
    {MyApp.BrowserPool, pool_size: 4}
  ]

# lib/my_app/application.ex
children = BrowseChrome.children()
```

## 🚀 Usage

```elixir
html = """
<html>
  <style>
    body { background: linear-gradient(135deg, #667eea, #764ba2); display: flex;
           align-items: center; justify-content: center; width: 1200px; height: 630px; }
    h1 { color: white; font-size: 48px; font-family: sans-serif; }
  </style>
  <body>
    <h1>Hello, Carta!</h1>
  </body>
</html>
"""

{:ok, jpeg_binary} = Carta.render(MyApp.BrowserPool, html)
```

Since it's a full browser, everything works: Google Fonts via `<link>`, flexbox, grid, images, SVG, etc. 🎨

### ⚙️ Options

| Option | Default | Description |
|--------|---------|-------------|
| `:width` | `1200` | Viewport width in pixels |
| `:height` | `630` | Viewport height in pixels |
| `:quality` | `90` | JPEG quality (1-100) |

### 💾 Caching

Rendering is expensive. Use `Carta.cache_key/2` to derive a stable hash from the input and options, then cache the result in your own store:

```elixir
key = Carta.cache_key(html)

case MyCache.get(key) do
  nil ->
    {:ok, jpg} = Carta.render(MyApp.BrowserPool, html)
    MyCache.put(key, jpg)
    jpg

  cached ->
    cached
end
```

## 🤔 Why not Wallaby?

[Wallaby](https://hex.pm/packages/wallaby) is a browser testing framework built on WebDriver. Carta takes a different approach:

- **Wallaby** requires a separate WebDriver binary (ChromeDriver, geckodriver) on top of the browser itself. Carta's backends talk to browsers directly via CDP or native bindings, with no extra binary needed.
- **Wallaby** is designed for integration testing with assertions, form interactions, and session management. Carta is designed for programmatic rendering in production.
- **Wallaby** has no built-in pool of warm browser instances. Carta (via Browse) uses NimblePool for warm instances, eliminating cold-start overhead on every render.
- **Carta is backend-agnostic.** Swap between Chrome (via BrowseChrome) and Servo (via BrowseServo) without changing your rendering code. Wallaby is tied to WebDriver.

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
