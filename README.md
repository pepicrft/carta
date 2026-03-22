# 🖼️ Carta

[![Hex.pm](https://img.shields.io/hexpm/v/carta.svg)](https://hex.pm/packages/carta)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/carta)
[![CI](https://github.com/pepicrft/carta/actions/workflows/carta.yml/badge.svg)](https://github.com/pepicrft/carta/actions/workflows/carta.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Generate images from HTML templates using a headless browser.

Carta renders HTML content in a headless Chrome/Chromium browser and captures it as a JPEG image. A pool of warm browser instances is managed automatically, so repeated renders avoid cold-start overhead.

**Use cases:** 🌐 Open Graph images · 📱 Social media cards · 📧 Email banners · 📜 Certificates · 🧾 Invoices · 🏷️ Badges · and anything you can build with HTML and CSS.

## 📦 Installation

Add `carta` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:carta, "~> 0.1.0"}
  ]
end
```

Carta requires Chrome or Chromium to be installed on the system. It will auto-detect common installation paths, or you can configure it explicitly:

```elixir
# config/config.exs
config :carta,
  pool_size: 4,                       # number of warm Chrome instances (default: 2)
  chrome_path: "/usr/bin/chromium"     # auto-detected if omitted
```

## 🚀 Usage

### Render inline HTML

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

{:ok, jpeg_binary} = Carta.render(html)
```

### Render an EEx template

```elixir
{:ok, jpeg_binary} = Carta.render({:template, "templates/card.html.eex",
  title: "My Blog Post",
  author: "Jane Doe"
})
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
key = Carta.cache_key({:template, "card.html.eex", title: "My Post"})

case MyCache.get(key) do
  nil ->
    {:ok, jpg} = Carta.render({:template, "card.html.eex", title: "My Post"})
    MyCache.put(key, jpg)
    jpg

  cached ->
    cached
end
```

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
