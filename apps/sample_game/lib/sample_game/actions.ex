defmodule SampleGame.Actions do
  use GsServer.ActionSpec

  action "register", [name, data] do
    nil = data

    field = case GsGraph.get_by_name("field") do
      nil ->
        new_field = GsGraph.make_node(%{"type" => "field"})
        GsGraph.update!([
          {:set_name, new_field.id, "field"}
        ])
        
        new_field.id
      old_field -> old_field
    end

    player = case GsGraph.get_by_name("player " <> name) do
      nil ->
        new_player = GsGraph.make_node(%{
          "type" => "player",
          "name" => name
        })

        GsGraph.update!([
          {:adopt, field, "contains", new_player.id}
        ])

        new_player.id

      old_player -> old_player
    end
          
    {:ok, %{player_id: player}}
  end

  action "print", [text, data] do
    IO.puts ["it was requested that I print ", text]

    {:ok, data}
  end

  action "id", [data] do
    %{player_id: id} = data

    IO.inspect {:id, id}

    {:ok, data}
  end

  action "debug_visual", [data] do
    :ok = Mix.Tasks.GsGraph.Visualise.run(nil)

    {:ok, data}
  end
end
