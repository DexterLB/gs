use Amnesia

defdatabase GSGraph.Database do
  deftable Node, [{ :id, autoincrement }, :data, :children, :parent], type: :set do
    @type t :: %Node{id: integer, data: %{}}

    def new() do
      new(nil)
    end

    def new(data) do
      %Node{data: data} |> Node.write!
    end
  end
end
