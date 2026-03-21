defmodule CartaTest do
  use ExUnit.Case

  describe "render/2" do
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

  describe "render_to_file/3" do
    test "writes JPEG to the specified path" do
      html = "<html><body><h1>File Test</h1></body></html>"
      output_path = Path.join(System.tmp_dir!(), "carta_test_#{:erlang.unique_integer([:positive])}.jpg")

      on_exit(fn -> File.rm(output_path) end)

      assert :ok = Carta.render_to_file(html, output_path)
      assert File.exists?(output_path)
      assert <<0xFF, 0xD8, 0xFF, _rest::binary>> = File.read!(output_path)
    end
  end

  describe "render_template/3" do
    test "renders an EEx template with assigns" do
      template_path = Path.join(System.tmp_dir!(), "carta_test_#{:erlang.unique_integer([:positive])}.html.eex")

      template = """
      <html>
        <body>
          <h1><%= @title %></h1>
          <p><%= @description %></p>
        </body>
      </html>
      """

      File.write!(template_path, template)
      on_exit(fn -> File.rm(template_path) end)

      assert {:ok, jpeg_binary} = Carta.render_template(template_path, [title: "My Post", description: "A great post"])
      assert <<0xFF, 0xD8, 0xFF, _rest::binary>> = jpeg_binary
    end

    test "returns error for missing template" do
      assert {:error, {:template_not_found, _, _}} = Carta.render_template("/nonexistent/template.html.eex")
    end
  end
end
