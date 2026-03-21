defmodule Carta.TemplateTest do
  use ExUnit.Case

  @moduletag :tmp_dir

  alias Carta.Template

  describe "render/2" do
    test "renders an EEx template with assigns", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "template.html.eex")
      File.write!(path, "<h1><%= @title %></h1>")

      assert {:ok, "<h1>Hello</h1>"} = Template.render(path, title: "Hello")
    end

    test "returns error for missing file" do
      assert {:error, {:template_not_found, _, :enoent}} = Template.render("/nonexistent.html.eex")
    end
  end
end
