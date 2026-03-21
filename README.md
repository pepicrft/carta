# Carta

Generate OG images from HTML templates using a headless browser.

Carta renders HTML content in a headless Chrome/Chromium browser and captures it as a JPEG image, ideal for generating Open Graph images for social media.

## Installation

Add `carta` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:carta, "~> 0.1.0"}
  ]
end
```

### Prerequisites

Carta requires Chrome or Chromium to be installed on the system. It will auto-detect common installation paths, or you can specify the path explicitly via the `:chrome_path` option.

## Usage

### Render HTML to JPEG

```elixir
html = """
<html>
  <body style="width: 1200px; height: 630px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
    <h1 style="color: white; font-size: 48px;">My Blog Post</h1>
  </body>
</html>
"""

{:ok, jpeg_binary} = Carta.render(html)
```

### Render an EEx template

```elixir
{:ok, jpeg_binary} = Carta.render_template("templates/og.html.eex",
  title: "My Blog Post",
  author: "Jane Doe"
)
```

### Save directly to a file

```elixir
:ok = Carta.render_to_file(html, "priv/static/og-images/post-1.jpg")
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `:width` | `1200` | Viewport width in pixels |
| `:height` | `630` | Viewport height in pixels |
| `:quality` | `90` | JPEG quality (1-100) |
| `:chrome_path` | auto-detected | Path to Chrome/Chromium binary |

## License

MIT License - see [LICENSE](LICENSE) for details.
