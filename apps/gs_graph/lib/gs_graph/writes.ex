defmodule GsGraph.Writes do
  alias GsGraph.Database.Node

  @type update_operation ::
    {:adopt, Node.id, nil} |
    {:adopt, Node.id, Node.label, Node.id} |
    {:attach, Node.id, Node.label, Node.id} |
    {:detach, Node.id, Node.label, Node.id} |
    {:set_data, Node.id, Node.data}

  @type maybe_error :: {:error, any} | :ok

  @spec run(update_operation) :: maybe_error

  def run({:adopt, child_id, nil}) do
    child = Node.read(child_id)

    clear_from_parent(child)

    child       |> Node.clear_parent()

    :ok
  end

  def run({:adopt, new_parent_id, new_label, child_id}) do
    child = Node.read(child_id)

    clear_from_parent(child)

    new_parent = Node.read(new_parent_id)
    
    child       |> Node.set_parent(new_parent_id, new_label)
    new_parent  |> Node.add_child(child.id, new_label)    

    :ok
  end

  def run({:attach, pseudo_parent_id, label, pseudo_child_id}) do
    pseudo_child = Node.read(pseudo_child_id)
    pseudo_parent = Node.read(pseudo_parent_id)

    pseudo_child    |> Node.add_pseudo_parent(pseudo_parent_id, label)
    pseudo_parent   |> Node.add_pseudo_child(pseudo_child.id, label)

    :ok
  end

  def run({:detach, pseudo_parent_id, label, pseudo_child_id}) do
    pseudo_child = Node.read(pseudo_child_id)
    pseudo_parent = Node.read(pseudo_parent_id)
    
    pseudo_child |> Node.del_pseudo_parent(pseudo_parent_id, label)
    pseudo_parent |> Node.del_pseudo_child(pseudo_child.id, label)

    :ok
  end

  def run({:set_data, node_id, data = %{}}) do
    node_id |> Node.read |> Node.set_data(data)

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
