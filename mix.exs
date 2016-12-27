defmodule Saj.Mixfile do
  use Mix.Project

  def project do
    [app: :saj,
     version: "0.1.0-alpha.1",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev},
     {:credo, "~> 0.3", only: [:dev, :test]}]
  end

  defp description do
    """
    SAJ (Simple API for JSON) is a SAX-inspired algorithm for parsing JSON documents
    """
  end

  defp package do
  [
    files: ["lib", "mix.exs", "README*", "LICENSE*"],
    maintainers: ["Quentin Focheux"],
    licenses: ["MIT"],
    links: %{"GitHub" => "https://github.com/QuentinFchx/saj/"}
  ]
end
end
