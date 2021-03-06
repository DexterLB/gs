use Amnesia

# time for some metaprogramming magic.

defdatabase GsGraph.Database do
  deftable Node, [
        { :id, autoincrement },
        :data,
        {:ref, 0},
        {:children, %{}},
        :parent,
        {:pseudo_parents, %{}},
        {:pseudo_children, %{}}
      ], type: :set do


    @type id            :: integer
    @type data          :: %{} | nil
    @type label         :: String.t
    @type transitions   :: %{label: MapSet.t(id)}
    @type transition    :: {label, id} | nil


    @type t :: %Node{
      id: id,
      data: data,
      ref: integer,
      children: transitions,
      parent: transition,
      pseudo_parents: transitions,
      pseudo_children: transitions
    }

    @spec new() :: t | no_return

    def new() do
      new(nil)
    end

    @spec new(data) :: t

    def new(data) do
      %Node{data: data} |> Node.write!
    end

    @spec clear_parent(t) :: t

    def clear_parent(node) do
      %Node{
        node |
          parent: nil
      } |> Node.write()
    end

    @spec set_parent(t, id, label) :: t

    def set_parent(node, parent_id, label) do
      %Node{
        node |
          parent: {parent_id, label}
      } |> Node.write()
    end

    @spec add_child(t, id, label) :: t

    def add_child(node, child_id, label) do
      %Node{
        node |
          children: append_child(node.children, child_id, label)
      } |> Node.write()
    end

    @spec del_child(t, id, label) :: t

    def del_child(node, child_id, label) do
      %Node{
        node |
          children: pop_child(node.children, child_id, label)
      } |> Node.write()
    end

    @spec add_pseudo_parent(t, id, label) :: t

    def add_pseudo_parent(node, pseudo_parent_id, label) do
      %Node {
        node |
          pseudo_parents: append_child(node.pseudo_parents, pseudo_parent_id, label)
      } |> Node.write()
    end

    @spec add_pseudo_child(t, id, label) :: t

    def add_pseudo_child(node, pseudo_child_id, label) do
      %Node {
        node |
          pseudo_children: append_child(node.pseudo_children, pseudo_child_id, label)
      } |> Node.write()
    end

    @spec del_pseudo_child(t, id, label) :: t

    def del_pseudo_child(node, child_id, label) do
      %Node {
        node |
          pseudo_children: pop_child(node.pseudo_children, child_id, label)
      } |> Node.write()
    end

    @spec del_pseudo_parent(t, id, label) :: t

    def del_pseudo_parent(node, parent_id, label) do
      %Node {
        node |
          pseudo_parents: pop_child(node.pseudo_parents, parent_id, label)
      } |> Node.write()
    end

    @spec set_data(t, data) :: t

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

  deftable Name, [:name, :node_id], type: :set do
    @type t :: %Name{name: String.t, node_id: Node.id}
  end
end
