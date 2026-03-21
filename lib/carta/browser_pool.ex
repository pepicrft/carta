defmodule Carta.BrowserPool do
  @moduledoc """
  A NimblePool that manages a pool of warm headless Chrome instances.

  Each pool resource is a running Chrome process with its CDP WebSocket URL,
  ready to accept navigation and screenshot commands without cold-start overhead.
  """

  @behaviour NimblePool

  alias Carta.Browser

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker
    }
  end

  def start_link(opts) do
    {pool_size, worker_opts} = Keyword.pop!(opts, :pool_size)
    NimblePool.start_link(worker: {__MODULE__, worker_opts}, pool_size: pool_size, name: __MODULE__)
  end

  @doc """
  Checks out a warm Chrome instance, runs the given function with its
  CDP WebSocket URL, and checks it back in.

  The function receives the WebSocket URL and must return `{result, instruction}`
  where instruction is `:ok` to return the resource to the pool or `:remove`
  to discard it.
  """
  def checkout(fun, timeout \\ 10_000) do
    NimblePool.checkout!(__MODULE__, :checkout, fn _from, ws_url ->
      fun.(ws_url)
    end, timeout)
  end

  # NimblePool Callbacks

  @impl NimblePool
  def init_worker(opts) do
    chrome_path = Keyword.get(opts, :chrome_path)

    case Browser.start(chrome_path) do
      {:ok, handle, ws_url} ->
        {:ok, ws_url, %{handle: handle, opts: opts}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl NimblePool
  def handle_checkout(:checkout, _from, ws_url, pool_state) do
    {:ok, ws_url, ws_url, pool_state}
  end

  @impl NimblePool
  def handle_checkin(:ok, _from, ws_url, pool_state) do
    {:ok, ws_url, pool_state}
  end

  def handle_checkin(:remove, _from, _ws_url, pool_state) do
    {:remove, :closed, pool_state}
  end

  @impl NimblePool
  def terminate_worker(_reason, _ws_url, %{handle: handle} = pool_state) do
    Browser.stop(handle)
    {:ok, pool_state}
  end
end
