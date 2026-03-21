defmodule Carta.Template do
  @moduledoc """
  Handles rendering of EEx templates into HTML strings.
  """

  @doc """
  Renders an EEx template file with the given assigns.

  Returns `{:ok, html}` on success or `{:error, reason}` on failure.
  """
  @spec render(String.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def render(template_path, assigns \\ []) do
    case File.read(template_path) do
      {:ok, template} ->
        html = EEx.eval_string(template, assigns: assigns)
        {:ok, html}

      {:error, reason} ->
        {:error, {:template_not_found, template_path, reason}}
    end
  rescue
    e -> {:error, {:template_error, Exception.message(e)}}
  end
end
