defmodule Mix.Tasks.Version do
  @shortdoc "Manage the project version in mix.exs"
  @moduledoc """
  Manage the project version in mix.exs.

  ## Usage

      mix version current          # Print the current version
      mix version bump 1.2.3 minor # Bump the given version (prints 1.3.0)
      mix version set 2.0.0        # Update @version in mix.exs
  """

  use Mix.Task

  @version_regex ~r/@version "(\d+)\.(\d+)\.(\d+)"/

  @impl Mix.Task
  def run(["current"]) do
    mix_exs()
    |> current_version!()
    |> IO.puts()
  end

  def run(["bump", version, part]) do
    version
    |> parse_version!()
    |> bump(part)
    |> format_version()
    |> IO.puts()
  end

  def run(["set", version]) do
    path = "mix.exs"
    contents = File.read!(path)
    current = current_version!(contents)

    if current == version do
      IO.puts(version)
    else
      updated = Regex.replace(@version_regex, contents, ~s(@version "#{version}"), global: false)

      if contents == updated do
        Mix.raise("Unable to update #{path} to #{version}")
      end

      File.write!(path, updated)
      IO.puts(version)
    end
  end

  def run(_args) do
    Mix.raise("usage: mix version [current|bump <version> <major|minor|patch>|set <version>]")
  end

  defp mix_exs do
    File.read!("mix.exs")
  end

  defp current_version!(contents) do
    case Regex.run(@version_regex, contents, capture: :all_but_first) do
      [major, minor, patch] -> Enum.join([major, minor, patch], ".")
      _ -> Mix.raise("Unable to find @version in mix.exs")
    end
  end

  defp parse_version!(version) do
    case String.split(version, ".", parts: 3) do
      [major, minor, patch] ->
        {String.to_integer(major), String.to_integer(minor), String.to_integer(patch)}

      _ ->
        Mix.raise("Invalid version: #{version}")
    end
  end

  defp bump({major, _minor, _patch}, "major"), do: {major + 1, 0, 0}
  defp bump({major, minor, _patch}, "minor"), do: {major, minor + 1, 0}
  defp bump({major, minor, patch}, "patch"), do: {major, minor, patch + 1}
  defp bump(_version, part), do: Mix.raise("Unknown bump type: #{part}")

  defp format_version({major, minor, patch}), do: "#{major}.#{minor}.#{patch}"
end
