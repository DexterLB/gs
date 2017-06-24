defmodule GsServer.TcpServer do
  def listen(action_spec) do
    {:ok, socket} = :gen_tcp.listen(
      Application.fetch_env!(:gs_server, :port),
      [
        :binary, 
        packet: :line, active: false, reuseaddr: true,
        ip: Application.fetch_env!(:gs_server, :ip)
      ]
    )

    accept(socket, action_spec)
  end

  defp accept(socket, action_spec) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(
      GsServer.TcpServer.ClientSupervisor,
      fn ->
        {:ok, pid} = GenServer.start_link(GsServer.Session, {client, action_spec})
        serve_loop(client, pid) 
      end
    )

    :ok = :gen_tcp.controlling_process(client, pid)

    accept(socket, action_spec)
  end

  defp serve(client, session_pid) do
    {:ok, data} = :gen_tcp.recv(client, 0)
    GenServer.cast(session_pid, {:receive, data})
  end

  defp serve_loop(client, session_pid) do
    serve(client, session_pid)
    serve_loop(client, session_pid)
  end
end
