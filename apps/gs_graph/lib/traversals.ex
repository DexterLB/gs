defmodule GsGraph.Traversals do
  use Amnesia

  alias __MODULE__
  alias GsGraph.Database.Node

  def nudge_step(node_ids) do
    node_ids |> Enum.map(&Traversals.nudge_node/1) |> List.flatten |> MapSet.new
  end

  def nudge_node(node_id) do
    IO.inspect node_id
    Amnesia.transaction do
      node = Node.read(node_id)

      %Node{
        node |
          ref: node.ref + 1
      } |> Node.write

      
      pseudo_parent_ids = node.pseudo_parents |> Enum.map(fn({id, _}) -> id end)

      case node.parent do
        {id, _} -> [id|pseudo_parent_ids]
        nil     -> pseudo_parent_ids
      end
    end
  end
end
