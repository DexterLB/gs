defmodule GsGraph.Subscriber.Supervisor do
  use Supervisor

  @name GsGraph.Subscriber.Supervisor

  def start_link(name) do
    Supervisor.start_link(__MODULE__, :ok, name: name)
  end

  def start_subscriber(target) do
    Supervisor.start_child(@name, [target])
  end

  def init(:ok) do
    children = [
      worker(GsGraph.Subscriber, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
