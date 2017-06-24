defmodule GsServer.Session do
  use GenServer

  def init({client, action_spec}) do
    {:ok, {client, action_spec, nil}}
  end

  def handle_cast({:receive, data}, state) do
    new_state = data |> Poison.decode! |> handle_json(state)
    {:noreply, new_state}
  end

  def handle_info({:nodes_changed, nodes}, state = {client, _, _}) do
    write(client, Poison.encode!(format_nodes(nodes)))
    {:noreply, state}
  end

  defp handle_json(data, state) do
    %{"action" => action_name, "args" => args} = data

    action(action_name, args, state)
  end

  defp action(name, args, {client, action_spec, data}) do
    {:ok, new_data} = apply(
      action_spec,
      :run_action, 
      [name, Map.put(args, "data", data)]
    )

    {client, action_spec, new_data}
  end

  defp write(client, data) do
    :gen_tcp.send(client, [data, "\n"])
  end

  defp format_nodes(nodes) do
    Enum.map(nodes, &format_node/1)
  end

  defp format_node(node) do
    %{
      "data" => node |> GsGraph.data,
      "children" => node |> GsGraph.children,
      "pseudo_children" => node |> GsGraph.pseudo_children,
      "ref" => node.ref,
      "id" => node.id
    }
  end
end
