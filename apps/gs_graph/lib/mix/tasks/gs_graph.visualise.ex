defmodule Mix.Tasks.GsGraph.Visualise do
  use Mix.Task

  def run(_) do
    {:ok, _started} = Application.ensure_all_started(:gs_graph)

    IO.puts GSGraph.visualise_all()
  end
end
