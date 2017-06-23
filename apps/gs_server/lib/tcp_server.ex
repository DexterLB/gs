defmodule GsServer.TcpServer do
  def listen do
    {:ok, socket} = :gen_tcp.listen(
      Application.fetch_env!(:gs_server, :port),
      [:binary, packet: :line, active: false, reuseaddr: true]
    )

    accept(socket)
  end

  defp accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(
      GsServer.TcpServer.ClientSupervisor,
      fn -> serve_loop(client) end
    )

    :ok = :gen_tcp.controlling_process(client, pid)

    accept(socket)
  end

  defp serve(client) do
    {:ok, data} = :gen_tcp.recv(client, 0)
    :gen_tcp.send(client, "you sent: " <> data)
  end

  defp serve_loop(client) do
    serve(client)
    serve_loop(client)
  end
end
