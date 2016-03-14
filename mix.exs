defmodule Maptu.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :maptu,
     version: @version,
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:dialyze, ">= 0.0.0", only: :dev},
     {:earmark, ">= 0.0.0", only: :docs},
     {:ex_doc, ">= 0.0.0", only: :docs}]
  end
end
