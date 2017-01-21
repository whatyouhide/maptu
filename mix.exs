defmodule Maptu.Mixfile do
  use Mix.Project

  @version "1.0.0"

  @repo_url "https://github.com/whatyouhide/maptu"

  @description ~s(Tiny library to convert from "encoded" maps to Elixir structs.)

  def project do
    [app: :maptu,
     version: @version,
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),

     # Hex
     package: [maintainers: ["Andrea Leopardi", "Aleksei Magusev"],
               licenses: ["MIT"],
               links: %{"GitHub" => @repo_url}],
     description: @description,

     # Docs
     name: "Maptu",
     docs: [main: "Maptu",
            source_ref: "v#{@version}",
            source_url: @repo_url]]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [{:earmark, ">= 0.0.0", only: :docs},
     {:ex_doc, ">= 0.0.0", only: :docs}]
  end
end
