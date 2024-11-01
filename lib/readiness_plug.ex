defmodule ElixirProbes.Plug.ReadinessPlug do
  @moduledoc """
  Provides a `Plug`-based readiness probe for Kubernetes, responding quickly with
  a 200 OK.

  This plug determines if the application is ready to receive requests and
  returns a 200 response if so. This endpoint will be called quite often and
  so it's preferable if it runs quickly and emits no logs. We allow each app in
  the umbrella to determine what it wants to exercise to determine readiness via
  the `checks` option. Checks are a map of zero-arity boolean functions that are
  all expected to return true if the app is ready. The name of the first one that
  returns a non-truthy value will be returned in the body of a 503 response.

  As we may not assume that this route is only available behind the load
  balancer, we should take care not to expose internal implementation details or
  personal information in the response body.

  References:
  - [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
  - [Kubernetes Liveness and Readiness Probes: How to Avoid Shooting Yourself in the Foot](https://blog.colinbreck.com/kubernetes-liveness-and-readiness-probes-how-to-avoid-shooting-yourself-in-the-foot/)
  - [Health checks for Plug and Phoenix](https://blog.jola.dev/health-checks-for-plug-and-phoenix)

  # Examples

  ```elixir
    plug ElixirProbes.Plug.ReadinessPlug,
      checks: %{
        my_check: &Module.my_check/0,
        my_other_check: &Module.my_other_check/0
      }
  ```

  The matched path can be configured at compile-time using `Mix.Config`:

  ```elixir
  config :elixir_probes,
    readiness_path: "/ready"
  ```
  """
  @behaviour Plug

  import Plug.Conn

  @path Application.compile_env(:elixir_probes, :readiness_path, "/probes/readiness")

  def init(opts), do: opts

  def call(%Plug.Conn{method: "GET", request_path: @path} = conn, opts) do
    case ready?(opts[:checks]) do
      :ok ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, "ready: #{:erlang.system_time(:second)}")
        |> halt()

      {:error, message} ->
        conn
        |> send_resp(503, message)
        |> halt()
    end
  end

  def call(conn, _opts), do: conn

  @doc "Returns the configured `request_path` for this Plug"
  @spec path :: String.t()
  def path, do: @path

  defp ready?(checks) do
    case Enum.find(checks, fn {_name, fun} -> fun.() != true end) do
      nil -> :ok
      {name, _fun} -> {:error, "readiness check failed: #{name}"}
    end
  end
end
