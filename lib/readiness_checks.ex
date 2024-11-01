defmodule ElixirProbes.ReadinessChecks do
  @moduledoc """
  Provides a bag of functions that are given to the ReadinessPlug in order
  to validate that the app is ready to receive requests.
  """

  def database_alive?(repo) do
    match?(
      {:ok, _},
      repo.query("SELECT 42", [], timeout: 500)
    )
  end

  def elasticsearch_alive_and_indexed?(es_cluster) do
    es_cluster.ready?()
  end
end
