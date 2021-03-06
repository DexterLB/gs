defmodule GsGraph.Writes do
  alias GsGraph.Database.Node
  alias GsGraph.Database.Name

  @type update_operation ::
    {:adopt, Node.id, nil} |
    {:adopt, Node.id, Node.label, Node.id} |
    {:attach, Node.id, Node.label, Node.id} |
    {:detach, Node.id, Node.label, Node.id} |
    {:set_data, Node.id, Node.data} |
    {:set_name, Node.id, String.t}

  @type error :: {:error, any}
  @type maybe_error :: error | :ok

  @spec run(update_operation) :: [Node.t] | error

  def run({:adopt, child_id, nil}) do
    child = Node.read(child_id)

    clear_from_parent(child)

    child       |> Node.clear_parent()

    [child]
  end

  def run({:adopt, new_parent_id, new_label, child_id}) do
    child = Node.read(child_id)

    clear_from_parent(child)

    new_parent = Node.read(new_parent_id)
    
    child       |> Node.set_parent(new_parent_id, new_label)
    new_parent  |> Node.add_child(child.id, new_label)    

    [child, new_parent]
  end

  def run({:attach, pseudo_parent_id, label, pseudo_child_id}) do
    pseudo_child = Node.read(pseudo_child_id)
    pseudo_parent = Node.read(pseudo_parent_id)

    pseudo_child    |> Node.add_pseudo_parent(pseudo_parent_id, label)
    pseudo_parent   |> Node.add_pseudo_child(pseudo_child.id, label)

    [pseudo_child, pseudo_parent]
  end

  def run({:detach, pseudo_parent_id, label, pseudo_child_id}) do
    pseudo_child = Node.read(pseudo_child_id)
    pseudo_parent = Node.read(pseudo_parent_id)
    
    pseudo_child |> Node.del_pseudo_parent(pseudo_parent_id, label)
    pseudo_parent |> Node.del_pseudo_child(pseudo_child.id, label)

    [pseudo_child, pseudo_parent]
  end

  def run({:set_data, node_id, data = %{}}) do
    node = node_id |> Node.read
    
    node |> Node.set_data(data)

    [node]
  end

  def run({:set_name, node_id, name}) do
    %Name{name: name, node_id: node_id} |> Name.write!

    []
  end

  def run({:incr, node_id, key, amount, {low, high}}) do
    node = Node.read(node_id)

    node |> Node.set_data(%{
      node.data |
        key => incr(Map.get(node.data, key), amount, {low, high})
    })

    [node]
  end

  defp clear_from_parent(child) do
    case child.parent do
      {parent_id, label} ->
        Node.read(parent_id)
          |> Node.del_child(child.id, label)
      nil -> nil
    end
  end

  defp incr(val, amount, {low, high}) do
    val + amount |> min(high) |> max(low)
  end
end
