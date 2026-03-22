defmodule Carta do
  @moduledoc """
  Generate images from HTML templates using a headless browser.

  Carta renders HTML content in a headless Chrome/Chromium browser and captures
  it as a JPEG image. Useful for Open Graph images, social media cards, email
  banners, certificates, invoices, badges, and anything you can build with HTML and CSS.

  Browser pool management is handled by [Chrona](https://hex.pm/packages/chrona),
  which maintains a pool of warm Chrome instances to eliminate cold-start overhead.

  ## Usage

      # Render inline HTML
      {:ok, jpeg_binary} = Carta.render("<h1>Hello, World!</h1>")

      # Render with options
      {:ok, jpeg_binary} = Carta.render(html, width: 1200, height: 630, quality: 90)

      # Render an EEx template with assigns
      {:ok, jpeg_binary} = Carta.render({:template, "templates/og.html.eex", title: "My Post"})

  ## Caching

  Rendering is expensive, as it launches a browser session for each call.
  You should cache the result and only re-render when the inputs change.
  Use `cache_key/2` to derive a stable hash from the input and options,
  then use it as a key in your own cache (ETS, filesystem, CDN, etc.):

      key = Carta.cache_key({:template, "og.html.eex", title: "My Post"})

      case MyCache.get(key) do
        nil ->
          {:ok, jpg} = Carta.render({:template, "og.html.eex", title: "My Post"})
          MyCache.put(key, jpg)
          jpg

        cached ->
          cached
      end

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

    Chrona.checkout(Carta.BrowserPool, fn browser ->
      case Chrona.Browser.capture(browser, html, opts) do
        {:ok, _binary} = ok -> {ok, :ok}
        {:error, _} = error -> {error, :remove}
      end
    end)
  end

  @doc """
  Returns a stable cache key (hex-encoded hash) for the given input and options.

  The key is derived from the full input (HTML string or template tuple)
  and the render options, so it changes when any parameter changes.

      Carta.cache_key("<h1>Hello</h1>")
      Carta.cache_key({:template, "og.html.eex", title: "Post"}, width: 800)
  """
  @spec cache_key(input(), keyword()) :: String.t()
  def cache_key(input, opts \\ []) do
    opts = Keyword.merge(@default_opts, opts)
    :crypto.hash(:sha256, :erlang.term_to_binary({input, opts})) |> Base.hex_encode32(case: :lower, padding: false)
  end
end
