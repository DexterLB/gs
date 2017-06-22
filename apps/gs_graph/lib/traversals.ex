defmodule GsGraph.Traversals do
  use Amnesia

  alias __MODULE__
  alias GsGraph.Database.Node

  def nudge_nodes(node_ids) do
    Amnesia.transaction do
      nudge_nodes(node_ids, MapSet.new)
    end
  end

  defp nudge_nodes(node_ids, visited) do
    case MapSet.size(node_ids) do
      0 -> :ok
      _ ->
        unvisited = MapSet.difference(node_ids, visited)

        new_nodes = unvisited 
          |> Enum.map(&Traversals.nudge_node/1)
          |> List.foldr(MapSet.new, &MapSet.union/2)

        nudge_nodes(new_nodes, MapSet.union(visited, unvisited))
    end
  end

  defp nudge_node(node_id) do
    node = Node.read(node_id)

    %Node{
      node |
        ref: node.ref + 1
    } |> Node.write

    # this should happen with an atomic dirty operation, but it isn't
    # exposed in mnesia, and some metaprogramming magic will be needed
    
    pseudo_parent_ids = node.pseudo_parents 
      |> Map.values 
      |> List.foldr(MapSet.new, &MapSet.union/2)

    case node.parent do
      {id, _} -> pseudo_parent_ids |> MapSet.put(id)
      nil     -> pseudo_parent_ids
    end
  end
end
