defmodule GsGraph.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(GsGraph.RefKeeper, [GsGraph.RefKeeper]),
      worker(GsGraph.Subscriber.Supervisor, [GsGraph.Subscriber.Supervisor]),
    ]

    supervise(children, strategy: :one_for_one)
  end
end
