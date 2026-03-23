defmodule Carta do
  @moduledoc """
  Generate images from HTML using a headless browser.

  Carta renders HTML content in a headless browser and captures it as a JPEG image.
  Useful for Open Graph images, social media cards, email banners, certificates,
  invoices, badges, and anything you can build with HTML and CSS.

  Carta is backend-agnostic. It uses [Browse](https://hex.pm/packages/browse) to
  interact with browsers, so any Browse-compatible backend works
  (e.g. [BrowseChrome](https://hex.pm/packages/browse_chrome),
  [BrowseServo](https://hex.pm/packages/browse_servo)).

  ## Setup

  1. Add `carta` and a browser backend to your dependencies:

      ```elixir
      def deps do
        [
          {:carta, "~> 0.2.0"},
          {:browse_chrome, "~> 0.2"}
        ]
      end
      ```

  2. Configure and start a browser pool in your supervision tree:

      ```elixir
      # config/config.exs
      config :browse_chrome,
        default_pool: MyApp.BrowserPool,
        pools: [
          {MyApp.BrowserPool, pool_size: 4, chrome_path: "/usr/bin/chromium"}
        ]

      # lib/my_app/application.ex
      children = BrowseChrome.children()
      ```

  3. Render HTML:

      ```elixir
      {:ok, jpeg} = Carta.render(MyApp.BrowserPool, "<h1>Hello!</h1>")
      ```

  ## Caching

  Rendering is expensive. Use `cache_key/2` to derive a stable hash from the
  input and options, then use it as a key in your own cache (ETS, filesystem, CDN, etc.):

      key = Carta.cache_key("<h1>Hello</h1>", width: 1200)

      case MyCache.get(key) do
        nil ->
          {:ok, jpg} = Carta.render(MyApp.BrowserPool, "<h1>Hello</h1>")
          MyCache.put(key, jpg)
          jpg

        cached ->
          cached
      end

  ## Options

    * `:width` - Viewport width in pixels (default: `1200`)
    * `:height` - Viewport height in pixels (default: `630`)
    * `:quality` - JPEG quality, 1-100 (default: `90`)
  """

  @default_opts [
    width: 1200,
    height: 630,
    quality: 90
  ]

  @doc """
  Renders an HTML string to a JPEG binary.

  The first argument is a Browse pool name. The pool must be started
  in your application's supervision tree (see module docs).

  ## Examples

      {:ok, jpeg} = Carta.render(MyApp.BrowserPool, "<h1>Hello!</h1>")

      {:ok, jpeg} = Carta.render(MyApp.BrowserPool, html, width: 800, height: 400)
  """
  @spec render(NimblePool.pool(), String.t(), keyword()) :: {:ok, binary()} | {:error, term()}
  def render(pool, html, opts \\ []) when is_binary(html) do
    opts = Keyword.merge(@default_opts, opts)
    width = Keyword.fetch!(opts, :width)
    height = Keyword.fetch!(opts, :height)
    quality = Keyword.fetch!(opts, :quality)

    Browse.checkout(pool, fn browser ->
      with {:ok, html_path} <- write_temp_html(html),
           :ok <- Browse.navigate(browser, "file://#{html_path}"),
           {:ok, jpeg} <-
             Browse.capture_screenshot(browser,
               format: "jpeg",
               quality: quality,
               width: width,
               height: height
             ) do
        {:ok, jpeg}
      end
    end)
  end

  @doc """
  Returns a stable cache key (hex-encoded hash) for the given HTML and options.

  The key changes when any parameter changes.

      Carta.cache_key("<h1>Hello</h1>")
      Carta.cache_key("<h1>Hello</h1>", width: 800)
  """
  @spec cache_key(String.t(), keyword()) :: String.t()
  def cache_key(html, opts \\ []) when is_binary(html) do
    opts = Keyword.merge(@default_opts, opts)

    :crypto.hash(:sha256, :erlang.term_to_binary({html, opts}))
    |> Base.hex_encode32(case: :lower, padding: false)
  end

  defp write_temp_html(html) do
    case Briefly.create(extname: ".html") do
      {:ok, path} ->
        File.write!(path, html)
        {:ok, path}

      error ->
        error
    end
  end
end
