defmodule GsGraph.Traversals do
  use Amnesia

  alias GsGraph.Database.Node

  def get_updates(node_ids, known) do
    Amnesia.transaction do
      new_ref_search(node_ids, known, [])
    end
  end

  def nudge_nodes(node_ids) do
    Amnesia.transaction do
      nudge_nodes(node_ids, MapSet.new)
    end
  end

  defp new_ref_search([], known, found_nodes) do
    {known, List.flatten(found_nodes)}
  end

  defp new_ref_search(node_ids, known, found_nodes) do
    new_nodes = node_ids
      |> Enum.map(&Node.read/1)
      |> Enum.filter(fn(node) -> node != nil end)
      |> Enum.filter(
        fn(node) -> case Map.get(known, node.id) do
          nil -> true
          old_ref -> node.ref > old_ref
        end end
      )

    new_refs = new_nodes
      |> Enum.map(fn(node) -> {node.id, node.ref} end)
      |> Map.new
    
    children = new_nodes
      |> Enum.map(fn(node) -> [node.children, node.pseudo_children] end)
      |> List.flatten

    new_ref_search(children, Map.merge(known, new_refs), [new_nodes, found_nodes])
  end

  defp nudge_nodes(node_ids, visited) do
    case MapSet.size(node_ids) do
      0 -> :ok
      _ ->
        unvisited = MapSet.difference(node_ids, visited)

        new_nodes = unvisited 
          |> Enum.map(&nudge_node/1)
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
