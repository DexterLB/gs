defmodule GsServer.TcpServer.Supervisor do
  use Supervisor

  @name GsServer.TcpServer.Supervisor

  def start_link do
    start_link(__MODULE__)
  end

  def start_link(name) do
    Supervisor.start_link(__MODULE__, :ok, name: name)
  end

  def start_subscriber(target) do
    Supervisor.start_child(@name, [target])
  end

  def init(:ok) do
    children = [
      supervisor(Task.Supervisor, [[name: GsServer.TcpServer.ClientSupervisor]]),
      worker(Task, [GsServer.TcpServer, :listen, []])
    ]

    supervise(children, strategy: :one_for_all)
  end
end
