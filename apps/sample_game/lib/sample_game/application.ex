defmodule SampleGame.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(GsServer.TcpServer.Supervisor, [:foo])
    ]

    opts = [strategy: :one_for_one, name: SampleGame.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
