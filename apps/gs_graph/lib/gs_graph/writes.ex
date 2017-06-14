defmodule GSGraph.Writes do
  alias GSGraph.Database.Node

  def run({:adopt, child, nil}) do
    clear_from_parent(child)

    child       |> Node.clear_parent()

    :ok
  end

  def run({:adopt, child, {new_parent_id, new_label}}) do
    clear_from_parent(child)

    new_parent = Node.read(new_parent_id)
    
    child       |> Node.set_parent(new_parent_id, new_label)
    new_parent  |> Node.add_child(child.id, new_label)    

    :ok
  end

  def run({:attach, pseudo_child, {pseudo_parent_id, label}}) do
    pseudo_parent = Node.read(pseudo_parent_id)

    pseudo_child    |> Node.add_pseudo_parent(pseudo_parent_id, label)
    pseudo_parent   |> Node.add_pseudo_child(pseudo_child.id, label)

    :ok
  end

  def run({:detach, pseudo_child, {pseudo_parent_id, label}}) do
    pseudo_parent = Node.read(pseudo_parent_id)
    
    pseudo_child |> Node.del_pseudo_parent(pseudo_parent_id, label)
    pseudo_parent |> Node.del_pseudo_child(pseudo_child.id, label)

    :ok
  end

  defp clear_from_parent(child) do
    case child.parent do
      {parent_id, label} ->
        Node.read(parent_id)
          |> Node.del_child(child.id, label)
      nil -> nil
    end
  end
end
