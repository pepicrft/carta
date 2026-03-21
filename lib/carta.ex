defmodule Carta do
  @moduledoc """
  Generate OG images from HTML templates using a headless browser.

  Carta renders HTML content in a headless Chrome/Chromium browser and captures
  it as a JPEG image, ideal for generating Open Graph images for social media.

  A pool of warm Chrome instances is managed automatically via the application
  supervision tree, eliminating cold-start overhead on each render.

  ## Usage

      # Render HTML string to JPEG binary
      {:ok, jpeg_binary} = Carta.render("<h1>Hello, World!</h1>")

      # Render with options
      {:ok, jpeg_binary} = Carta.render(html, width: 1200, height: 630, quality: 90)

      # Render an EEx template with assigns
      {:ok, jpeg_binary} = Carta.render_template("templates/og.html.eex", title: "My Post")

      # Render directly to a file
      :ok = Carta.render_to_file("<h1>Hello</h1>", "og-image.jpg")

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

  @default_opts [
    width: 1200,
    height: 630,
    quality: 90
  ]

  @doc """
  Renders an HTML string to a JPEG binary.

  Returns `{:ok, jpeg_binary}` on success or `{:error, reason}` on failure.
  """
  @spec render(String.t(), keyword()) :: {:ok, binary()} | {:error, term()}
  def render(html, opts \\ []) when is_binary(html) do
    opts = Keyword.merge(@default_opts, opts)

    BrowserPool.checkout(fn browser ->
      case Browser.capture(browser, html, opts) do
        {:ok, _binary} = ok -> {ok, :ok}
        {:error, _} = error -> {error, :remove}
      end
    end)
  end

  @doc """
  Renders an EEx template with the given assigns to a JPEG binary.

  The template file is read and evaluated with the provided assigns,
  then rendered in a headless browser.

  Returns `{:ok, jpeg_binary}` on success or `{:error, reason}` on failure.
  """
  @spec render_template(String.t(), keyword(), keyword()) :: {:ok, binary()} | {:error, term()}
  def render_template(template_path, assigns \\ [], opts \\ []) do
    case Template.render(template_path, assigns) do
      {:ok, html} -> render(html, opts)
      {:error, _} = error -> error
    end
  end

  @doc """
  Renders an HTML string to a JPEG file at the given path.

  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  @spec render_to_file(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def render_to_file(html, output_path, opts \\ []) do
    case render(html, opts) do
      {:ok, jpeg_binary} -> File.write(output_path, jpeg_binary)
      {:error, _} = error -> error
    end
  end
end
