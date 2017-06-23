defmodule GsGraph.Subscriber do
  use GenServer

  alias GsGraph.Traversals

  def start_link(target = {pid, _}) when is_pid(pid) do
    GenServer.start_link(__MODULE__, {%{}, target})
  end

  def init(state = {_known, {pid, _}}) do
    Process.link(pid)

    send(self(), :check)

    {:ok, state}
  end

  def start_link(name, target = {pid, _}) when is_pid(pid) do
    GenServer.start_link(__MODULE__, {%{}, target}, name: name)
  end

  def handle_info(:check, {known, {pid, node_ids}}) do
    {new_known, changed_nodes} = Traversals.get_updates(node_ids, known)

    case changed_nodes do
      [] -> nil
      nodes -> send(pid, {:nodes_changed, nodes})
    end

    schedule_check()
    {:noreply, {new_known, {pid, node_ids}}}
  end

  defp schedule_check do
    Process.send_after(self(), :check, Application.fetch_env!(:gs_graph, :update_interval))
  end
end
