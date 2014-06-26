defmodule Extcd.Mixfile do
  use Mix.Project

  def project do
    [app: :extcd,
     version: "0.0.1",
     elixir: "~> 0.14.0",
     deps: deps]
  end

  def application do
    [applications: [:httpoison],
     mod: {Extcd, []}]
  end

  defp deps do
    [
      {:httpoison, github: "edgurgel/httpoison"},
      {:jazz, github: "meh/jazz"},
      {:lax, github: "d0rc/lax"}
    ]
  end
end
