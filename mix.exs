defmodule Plug.CacheControl.MixProject do
  use Mix.Project

  @source_url "https://github.com/krasenyp/plug_cache_control"
  @version "0.1.0"

  def project do
    [
      app: :plug_cache_control,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "A convenience for manipulating cache-control header values.",
      package: package(),

      # Docs
      name: "Plug.CacheControl",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.5"},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
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
      main: "Plug.CacheControl",
      source_ref: "v#{@version}"
    ]
  end
end
