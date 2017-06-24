defmodule GsServer.Session do
  use GenServer

  def init({client, action_spec}) do
    {:ok, {client, action_spec, nil}}
  end

  def handle_cast({:receive, data}, state) do
    new_state = data |> Poison.decode! |> handle_json(state)
    {:noreply, new_state}
  end

  defp handle_json(data, state) do
    %{"action" => action_name, "args" => args} = data

    action(action_name, args, state)
  end

  defp action("kill", whom, state = {client, action_spec, _node_id}) do
    write(client, ["you killed ", whom, " with ", inspect(action_spec)])

    state
  end

  defp write(client, data) do
    :gen_tcp.send(client, data)
  end
end
