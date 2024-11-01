defmodule ElixirProbes.Plug.LivenessPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ElixirProbes.Plug.LivenessPlug

  @path Application.compile_env(:elixir_probes, :liveness_path, "/probes/liveness")

  setup do
    {:ok, opts: []}
  end

  describe "init/1" do
    test "returns opts unchanged" do
      opts = [foo: :bar, baz: :qux]
      assert LivenessPlug.init(opts) == opts
    end
  end

  describe "call/2 on matching request path" do
    setup do
      {:ok, conn: conn(:get, @path)}
    end

    test "responds 200 OK", %{conn: conn, opts: opts} do
      conn = LivenessPlug.call(conn, opts)

      assert {200, _headers, _body} = sent_resp(conn)
    end

    test "sets a content-type header", %{conn: conn, opts: opts} do
      conn = LivenessPlug.call(conn, opts)

      assert {_status, headers, _body} = sent_resp(conn)
      assert {"content-type", "text/plain; charset=utf-8"} in headers
    end

    test "includes epoch time", %{conn: conn, opts: opts} do
      timestamp = :erlang.system_time(:second)
      conn = LivenessPlug.call(conn, opts)

      assert {_status, _headers, "alive: " <> response_timestamp_string} = sent_resp(conn)
      assert {response_timestamp, ""} = Integer.parse(response_timestamp_string)
      assert_in_delta timestamp, response_timestamp, 1
    end

    test "halts the connection", %{conn: conn, opts: opts} do
      assert %Plug.Conn{halted: true} = LivenessPlug.call(conn, opts)
    end
  end

  describe "call/2" do
    test "passes unmatched request paths through unchanged", %{opts: opts} do
      conn = conn(:get, "/")

      refute conn.halted
      assert LivenessPlug.call(conn, opts) == conn
    end

    test "passes unmatched method through unchanged", %{opts: opts} do
      conn = conn(:post, @path)

      refute conn.halted
      assert LivenessPlug.call(conn, opts) == conn
    end
  end

  describe "path/0" do
    test "returns the configured request path for probe" do
      assert LivenessPlug.path() == @path
    end
  end
end
