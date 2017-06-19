use Amnesia

defdatabase GsGraph.Database do
  deftable Node, [
        { :id, autoincrement },
        :data, 
        {:children, %{}},
        :parent,
        {:pseudo_parents, %{}},
        {:pseudo_children, %{}}
      ], type: :set do

    @type t :: %Node{id: integer, data: %{}}

    def new() do
      new(nil)
    end

    def new(data) do
      %Node{data: data} |> Node.write!
    end

    def clear_parent(node) do
      %Node{
        node |
          parent: nil
      } |> Node.write()
    end

    def set_parent(node, parent_id, label) do
      %Node{
        node |
          parent: {parent_id, label}
      } |> Node.write()
    end

    def add_child(node, child_id, label) do
      %Node{
        node |
          children: append_child(node.children, child_id, label)
      } |> Node.write()
    end

    def del_child(node, child_id, label) do
      %Node{
        node |
          children: pop_child(node.children, child_id, label)
      } |> Node.write()
    end

    def add_pseudo_parent(node, pseudo_parent_id, label) do
      %Node {
        node |
          pseudo_parents: append_child(node.pseudo_parents, pseudo_parent_id, label)
      } |> Node.write()
    end

    def add_pseudo_child(node, pseudo_child_id, label) do
      %Node {
        node |
          pseudo_children: append_child(node.pseudo_children, pseudo_child_id, label)
      } |> Node.write()
    end

    def del_pseudo_child(node, child_id, label) do
      %Node {
        node |
          pseudo_children: pop_child(node.pseudo_children, child_id, label)
      } |> Node.write()
    end

    def del_pseudo_parent(node, parent_id, label) do
      %Node {
        node |
          pseudo_parents: pop_child(node.pseudo_parents, parent_id, label)
      } |> Node.write()
    end

    def set_data(node = %Node{}, data) do
        %Node{
        node |
            data: data
        } |> write
    end

    defp append_child(children, child_id, label) do
      children
        |> Map.put(
            label, 
            Map.get(children, label, %MapSet{}) |> MapSet.put(child_id)
          )
    end

    defp pop_child(children, child_id, label) do
      case Map.get(children, label, %MapSet{}) |> MapSet.delete(child_id) do
        %MapSet{} -> children |> Map.delete(label)
        label_set -> %{ children | label => label_set }
      end
    end
  end
end
