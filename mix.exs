defmodule ElixirProbes.MixProject do
  use Mix.Project

  @name "ElixirProbes"
  @version "0.1.0"
  @source_url "https://github.com/carsdotcom/elixir_probes"

  def project do
    [
      app: :elixir_probes,
      deps: deps(),
      description: description(),
      elixir: "~> 1.14",
      name: @name,
      package: package(),
      source_url: @source_url,
      start_permanent: Mix.env() == :prod,
      version: @version
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
      {:plug, "~> 1.0"}
    ]
  end

  defp description do
    "Common probes for Elixir applications in Kubernetes deployments"
  end

  defp package do
    [
      name: "pacer",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
