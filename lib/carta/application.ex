defmodule Carta.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    pool_size = Application.get_env(:carta, :pool_size, 2)
    chrome_path = Application.get_env(:carta, :chrome_path)

    children = [
      {Chrona.BrowserPool, name: Carta.BrowserPool, pool_size: pool_size, chrome_path: chrome_path}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Carta.Supervisor)
  end
end
