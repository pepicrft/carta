defmodule Carta do
  @moduledoc """
  Generate OG images from HTML templates using a headless browser.

  Carta renders HTML content in a headless Chrome/Chromium browser and captures
  it as a JPEG image, ideal for generating Open Graph images for social media.

  A pool of warm Chrome instances is managed automatically via the application
  supervision tree, eliminating cold-start overhead on each render.

  ## Usage

      # Render inline HTML
      {:ok, jpeg_binary} = Carta.render("<h1>Hello, World!</h1>")

      # Render with options
      {:ok, jpeg_binary} = Carta.render(html, width: 1200, height: 630, quality: 90)

      # Render an EEx template with assigns
      {:ok, jpeg_binary} = Carta.render({:template, "templates/og.html.eex", title: "My Post"})

      # Render directly to a file
      :ok = Carta.render_to_file("<h1>Hello</h1>", "og-image.jpg")
      :ok = Carta.render_to_file({:template, "templates/og.html.eex", title: "My Post"}, "og.jpg")

  ## Configuration

      # config/config.exs
      config :carta,
        pool_size: 4,           # number of warm Chrome instances (default: 2)
        chrome_path: "/usr/bin/chromium"  # auto-detected if omitted

  ## Options

    * `:width` - Viewport width in pixels (default: `1200`)
    * `:height` - Viewport height in pixels (default: `630`)
    * `:quality` - JPEG quality, 1-100 (default: `90`)
  """

  alias Carta.Browser
  alias Carta.BrowserPool
  alias Carta.Template

  @type input :: String.t() | {:template, String.t(), keyword()}

  @default_opts [
    width: 1200,
    height: 630,
    quality: 90
  ]

  @doc """
  Renders HTML or a template to a JPEG binary.

  Accepts either an HTML string or a `{:template, path, assigns}` tuple.

  Returns `{:ok, jpeg_binary}` on success or `{:error, reason}` on failure.
  """
  @spec render(input(), keyword()) :: {:ok, binary()} | {:error, term()}
  def render(input, opts \\ [])

  def render({:template, template_path, assigns}, opts) do
    case Template.render(template_path, assigns) do
      {:ok, html} -> render(html, opts)
      {:error, _} = error -> error
    end
  end

  def render(html, opts) when is_binary(html) do
    opts = Keyword.merge(@default_opts, opts)

    BrowserPool.checkout(fn browser ->
      case Browser.capture(browser, html, opts) do
        {:ok, _binary} = ok -> {ok, :ok}
        {:error, _} = error -> {error, :remove}
      end
    end)
  end

  @doc """
  Renders HTML or a template to a JPEG file at the given path.

  Accepts either an HTML string or a `{:template, path, assigns}` tuple.

  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  @spec render_to_file(input(), String.t(), keyword()) :: :ok | {:error, term()}
  def render_to_file(input, output_path, opts \\ []) do
    case render(input, opts) do
      {:ok, jpeg_binary} -> File.write(output_path, jpeg_binary)
      {:error, _} = error -> error
    end
  end
end
