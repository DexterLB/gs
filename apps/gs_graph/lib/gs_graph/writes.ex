defmodule GSGraph.Writes do
  alias GSGraph.Database.Node

  def run({:adopt, child, nil}) do
    clear_from_parent(child)

    child       |> Node.clear_parent()

    :ok
  end

  def run({:adopt, child, {new_parent_id, new_label}}) do
    clear_from_parent(child)

    new_parent = GSGraph.get(new_parent_id)
    
    child       |> Node.set_parent(new_parent_id, new_label)
    new_parent  |> Node.add_child(child.id, new_label)    

    :ok
  end

  defp clear_from_parent(child) do
    case child.parent do
      {parent_id, label} ->
        GSGraph.get(parent_id)
          |> Node.del_child(child.id, label)
      nil -> nil
    end
  end
end
