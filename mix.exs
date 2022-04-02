defmodule PlugCacheControl.MixProject do
  use Mix.Project

  @source_url "https://github.com/krasenyp/plug_cache_control"
  @version "0.2.2"

  def project do
    [
      app: :plug_cache_control,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "A convenience for manipulating cache-control header values.",
      package: package(),

      # Docs
      name: "PlugCacheControl",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.12"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Krasen Penchev"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: ~w(.formatter.exs mix.exs README.md lib)
    ]
  end

  defp docs do
    [
      main: "PlugCacheControl",
      source_ref: "v#{@version}"
    ]
  end
end
