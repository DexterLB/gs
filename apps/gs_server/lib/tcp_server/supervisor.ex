defmodule GsServer.TcpServer.Supervisor do
  use Supervisor

  @name GsServer.TcpServer.Supervisor

  def start_link(args) do
    start_link(__MODULE__, args)
  end

  def start_link(name, args) do
    Supervisor.start_link(__MODULE__, args, name: name)
  end

  def start_subscriber(target) do
    Supervisor.start_child(@name, [target])
  end

  def init(args) do
    IO.inspect(args)
    children = [
      supervisor(Task.Supervisor, [[name: GsServer.TcpServer.ClientSupervisor]]),
      worker(Task, [GsServer.TcpServer, :listen, []])
    ]

    supervise(children, strategy: :one_for_all)
  end
end
