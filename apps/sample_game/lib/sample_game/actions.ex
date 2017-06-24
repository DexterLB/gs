defmodule SampleGame.Actions do
  use GsServer.ActionSpec

  action "register", [name, data] do
    nil = data

    {:ok, %{player_id: player(name)}}
  end

  action "move", [direction, data] do
    %{player_id: id} = data

    pos = GsGraph.child(id, "position")

    op = case direction do
      "up" -> {:incr, pos, "y", 1, {0, 20}}
      "down" -> {:incr, pos, "y", -1, {0, 20}}
      "left" -> {:incr, pos, "x", -1, {0, 20}}
      "right" -> {:incr, pos, "x", 1, {0, 20}}
    end

    :ok = GsGraph.update!([op])

    {:ok, data}
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

  defp field do
    case GsGraph.get_by_name("field") do
      nil ->
        new_field = GsGraph.make_node(%{"type" => "field"})
        :ok = GsGraph.update!([
          {:set_name, new_field.id, "field"}
        ])
        
        new_field.id
      old_field -> old_field
    end
  end

  defp player(name) do
    case GsGraph.get_by_name("player " <> name) do
      nil ->
        new_player = GsGraph.make_node(%{
          "type" => "player",
          "name" => name,
        })

        new_position = GsGraph.make_node(%{
          "type" => "position",
          "x" => 1,
          "y" => 1
        })

        :ok = GsGraph.update!([
          {:set_name, new_player.id, "player " <> name},
          {:adopt, field(), "is in", new_player.id},
          {:adopt, new_player.id, "position", new_position.id}
        ])

        new_player.id

      old_player -> old_player
    end
          
  end
end
