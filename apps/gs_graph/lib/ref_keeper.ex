defmodule GsGraph.RefKeeper do
  alias __MODULE__
  @server __MODULE__

  alias GsGraph.Traversals


  def start_link(name) do
    pid = spawn_link(@server, :run, [])
    
    Process.register(pid, name)
  
    {:ok, pid}
  end

  def start_link do
    start_link(@server)
  end

  def nudge(server, node_ids) do
    send(server, {:nudge, node_ids})
  end

  def nudge(node_ids) do
    RefKeeper.nudge(@server, node_ids)
  end


  # ***** Loop *****

  def run() do
    receive do
      {:nudge, node_ids} -> 
        handle_nudge(node_ids)
        RefKeeper.run
      
      _ ->
        raise "unknown message" 
    end
  end

  # ***** Handlers *****

  defp handle_nudge(node_ids) do
    # can't decide whether it's better to block
    node_ids |> Traversals.nudge_step |> RefKeeper.nudge
  end
end
