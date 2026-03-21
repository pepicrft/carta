defmodule Carta.Browser do
  @moduledoc """
  Manages headless Chrome/Chromium process lifecycle.

  Handles starting and stopping Chrome instances, and provides
  screenshot capture using a CDP WebSocket connection.
  """

  alias Carta.CDP

  @doc """
  Starts a headless Chrome instance and returns its handle and CDP WebSocket URL.

  The `chrome_path` can be `nil` to auto-detect.
  """
  @spec start(String.t() | nil) :: {:ok, term(), String.t()} | {:error, term()}
  def start(chrome_path \\ nil) do
    chrome_path = chrome_path || find_chrome()

    if is_nil(chrome_path) do
      {:error, :chrome_not_found}
    else
      port = find_available_port()
      user_data_dir = Path.join(System.tmp_dir!(), "carta_chrome_#{:erlang.unique_integer([:positive])}")

      args = [
        "--headless=new",
        "--disable-gpu",
        "--no-sandbox",
        "--disable-dev-shm-usage",
        "--hide-scrollbars",
        "--remote-debugging-port=#{port}",
        "--user-data-dir=#{user_data_dir}",
        "about:blank"
      ]

      pid =
        spawn(fn ->
          MuonTrap.cmd(chrome_path, args, stderr_to_stdout: true)
        end)

      case wait_for_devtools(port) do
        {:ok, ws_url} ->
          {:ok, {pid, user_data_dir}, ws_url}

        {:error, _} = error ->
          Process.exit(pid, :kill)
          File.rm_rf(user_data_dir)
          error
      end
    end
  end

  @doc """
  Stops a Chrome instance previously started with `start/1`.
  """
  @spec stop(term()) :: :ok
  def stop({pid, user_data_dir}) do
    Process.exit(pid, :kill)
    File.rm_rf(user_data_dir)
    :ok
  end

  @doc """
  Captures a screenshot using a CDP WebSocket URL from a pooled Chrome instance.

  Writes the HTML to a temp file, navigates, captures, and cleans up.
  """
  @spec capture(String.t(), String.t(), keyword()) :: {:ok, binary()} | {:error, term()}
  def capture(ws_url, html, opts) do
    width = Keyword.fetch!(opts, :width)
    height = Keyword.fetch!(opts, :height)
    quality = Keyword.fetch!(opts, :quality)

    tmp_dir = System.tmp_dir!()
    html_path = Path.join(tmp_dir, "carta_#{:erlang.unique_integer([:positive])}.html")

    try do
      File.write!(html_path, html)
      file_url = "file://#{html_path}"
      take_screenshot(ws_url, file_url, width, height, quality)
    after
      File.rm(html_path)
    end
  end

  defp take_screenshot(ws_url, file_url, width, height, quality) do
    with {:ok, cdp} <- CDP.connect(ws_url),
         :ok <- CDP.set_device_metrics(cdp, width, height),
         :ok <- CDP.navigate(cdp, file_url),
         {:ok, data} <- CDP.capture_screenshot(cdp, "jpeg", quality) do
      CDP.disconnect(cdp)
      {:ok, Base.decode64!(data)}
    end
  end

  defp find_chrome do
    paths =
      case :os.type() do
        {:unix, :darwin} ->
          [
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            "/Applications/Chromium.app/Contents/MacOS/Chromium",
            "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary"
          ]

        {:unix, _} ->
          [
            "google-chrome",
            "google-chrome-stable",
            "chromium",
            "chromium-browser"
          ]

        {:win32, _} ->
          [
            "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
            "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe"
          ]
      end

    Enum.find(paths, fn path ->
      case System.find_executable(path) do
        nil -> File.exists?(path)
        _ -> true
      end
    end)
  end

  defp find_available_port do
    {:ok, socket} = :gen_tcp.listen(0, reuseaddr: true)
    {:ok, port} = :inet.port(socket)
    :gen_tcp.close(socket)
    port
  end

  defp wait_for_devtools(port, attempts \\ 50) do
    wait_for_devtools(port, attempts, 0)
  end

  defp wait_for_devtools(_port, max_attempts, attempt) when attempt >= max_attempts do
    {:error, :devtools_timeout}
  end

  defp wait_for_devtools(port, max_attempts, attempt) do
    url = ~c"http://127.0.0.1:#{port}/json/version"

    case :httpc.request(:get, {url, []}, [timeout: 1000], []) do
      {:ok, {{_, 200, _}, _, body}} ->
        info = Jason.decode!(to_string(body))
        {:ok, info["webSocketDebuggerUrl"]}

      _ ->
        Process.sleep(100)
        wait_for_devtools(port, max_attempts, attempt + 1)
    end
  end
end
