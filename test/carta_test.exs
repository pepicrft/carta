defmodule CartaTest do
  use ExUnit.Case, async: true

  describe "render/2 with inline HTML" do
    test "renders HTML to a JPEG binary" do
      html = """
      <html>
        <body style="width: 1200px; height: 630px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
          <h1 style="color: white; font-size: 48px; font-family: sans-serif;">Hello, Carta!</h1>
        </body>
      </html>
      """

      assert {:ok, jpeg_binary} = Carta.render(html)
      # JPEG files start with FF D8 FF
      assert <<0xFF, 0xD8, 0xFF, _rest::binary>> = jpeg_binary
    end

    test "respects custom dimensions" do
      html = "<html><body><h1>Test</h1></body></html>"

      assert {:ok, jpeg_binary} = Carta.render(html, width: 800, height: 400)
      assert <<0xFF, 0xD8, 0xFF, _rest::binary>> = jpeg_binary
    end
  end

  describe "render/2 with template" do
    @describetag :tmp_dir

    test "renders an EEx template with assigns", %{tmp_dir: tmp_dir} do
      template_path = Path.join(tmp_dir, "og.html.eex")

      File.write!(template_path, """
      <html>
        <body>
          <h1><%= @title %></h1>
          <p><%= @description %></p>
        </body>
      </html>
      """)

      assert {:ok, jpeg_binary} =
               Carta.render({:template, template_path, title: "My Post", description: "A great post"})

      assert <<0xFF, 0xD8, 0xFF, _rest::binary>> = jpeg_binary
    end

    test "returns error for missing template" do
      assert {:error, {:template_not_found, _, _}} = Carta.render({:template, "/nonexistent/template.html.eex", []})
    end
  end

  describe "cache_key/2" do
    test "returns a stable hash for the same input" do
      key1 = Carta.cache_key("<h1>Hello</h1>")
      key2 = Carta.cache_key("<h1>Hello</h1>")
      assert key1 == key2
    end

    test "returns different keys for different inputs" do
      key1 = Carta.cache_key("<h1>Hello</h1>")
      key2 = Carta.cache_key("<h1>World</h1>")
      assert key1 != key2
    end

    test "returns different keys for different options" do
      key1 = Carta.cache_key("<h1>Hello</h1>", width: 800)
      key2 = Carta.cache_key("<h1>Hello</h1>", width: 1200)
      assert key1 != key2
    end

    test "works with template tuples" do
      key = Carta.cache_key({:template, "og.html.eex", title: "Post"})
      assert is_binary(key)
    end
  end
end
