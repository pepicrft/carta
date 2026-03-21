defmodule Carta.TemplateTest do
  use ExUnit.Case

  alias Carta.Template

  describe "render/2" do
    test "renders an EEx template with assigns" do
      path = Path.join(System.tmp_dir!(), "carta_template_test_#{:erlang.unique_integer([:positive])}.html.eex")

      File.write!(path, "<h1><%= @title %></h1>")
      on_exit(fn -> File.rm(path) end)

      assert {:ok, "<h1>Hello</h1>"} = Template.render(path, title: "Hello")
    end

    test "returns error for missing file" do
      assert {:error, {:template_not_found, _, :enoent}} = Template.render("/nonexistent.html.eex")
    end
  end
end
