defmodule ElixirProbes.Plug.LivenessPlug do
  @moduledoc """
  Provides a `Plug`-based liveness probe for Kubernetes, responding quickly with
  a 200 OK.

  This design lightly exercises the Cowboy/Plug stack and the viability of
  application-level supervision trees, and not much else. Application-specific
  behavior such as data-store connections should rarely be exercised here,
  preferring to be included in a readiness probe instead. As this endpoint will
  be called **once per Pod**, it is imperative that it responds as fast as
  possible, and preferable that it does not emit logs. We intentionally mount
  the Plug early in the Endpoint module rather than adding it to a Router,
  bypassing most of the defined Plugs and Plug pipelines.

  This Plug should typically only return a non-200 response when external
  intervention is required, such as restarting the BEAM. Ephemeral failure modes
  that will likely resolve on their own with time and patience should not
  trigger liveness-probe failures, as a sufficient number of them in a short
  time will cause Kubernetes to restart the container altogether.

  As we may not assume that this route is only available behind the load
  balancer, we should take care not to expose internal implementation details or
  personal information in the response body.

  References:
  - [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
  - [Kubernetes Liveness and Readiness Probes: How to Avoid Shooting Yourself in the Foot](https://blog.colinbreck.com/kubernetes-liveness-and-readiness-probes-how-to-avoid-shooting-yourself-in-the-foot/)
  - [Health checks for Plug and Phoenix](https://blog.jola.dev/health-checks-for-plug-and-phoenix)

  # Examples

  ```elixir
    plug ElixirProbes.Plug.LivenessPlug
  ```

  The matched path can be configured at compile-time using `Mix.Config`:

  ```elixir
  config :elixir_probes,
    liveness_path: "/livez"
  ```
  """
  @behaviour Plug

  import Plug.Conn

  @path Application.compile_env(:elixir_probes, :liveness_path, "/probes/liveness")

  def init(opts), do: opts

  def call(%Plug.Conn{method: "GET", request_path: @path} = conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "alive: #{:erlang.system_time(:second)}")
    |> halt()
  end

  def call(conn, _opts), do: conn

  @doc "Returns the configured `request_path` for this Plug"
  @spec path :: String.t()
  def path, do: @path
end
