defmodule Carta.TemplateTest do
  use ExUnit.Case, async: true

  alias Carta.Template

  @moduletag :tmp_dir

  describe "render/2" do
    test "renders an EEx template with a single assign", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "template.html.eex")
      File.write!(path, "<h1><%= @title %></h1>")

      assert {:ok, "<h1>Hello</h1>"} = Template.render(path, title: "Hello")
    end

    test "renders a template with multiple assigns", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "template.html.eex")
      File.write!(path, "<h1><%= @title %></h1><p><%= @author %></p>")

      assert {:ok, html} = Template.render(path, title: "My Post", author: "Jane")
      assert html == "<h1>My Post</h1><p>Jane</p>"
    end

    test "renders a template with no assigns", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "static.html.eex")
      File.write!(path, "<h1>Static Content</h1>")

      assert {:ok, "<h1>Static Content</h1>"} = Template.render(path)
    end

    test "renders a template with EEx control flow", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "control.html.eex")

      File.write!(path, """
      <%= for tag <- @tags do %><span><%= tag %></span><% end %>\
      """)

      assert {:ok, html} = Template.render(path, tags: ["elixir", "otp"])
      assert html =~ "<span>elixir</span>"
      assert html =~ "<span>otp</span>"
    end

    test "preserves HTML special characters in assigns", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "special.html.eex")
      File.write!(path, "<p><%= @text %></p>")

      assert {:ok, "<p>a < b & c > d</p>"} = Template.render(path, text: "a < b & c > d")
    end

    test "returns error for missing file" do
      assert {:error, {:template_not_found, _, :enoent}} = Template.render("/nonexistent.html.eex")
    end
  end
end
