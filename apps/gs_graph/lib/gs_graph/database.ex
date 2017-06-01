use Amnesia

defdatabase GSGraph.Database do
  deftable Node, [{ :id, autoincrement }, :data], type: :set do
    def new() do
      new(nil)
    end

    def new(data) do
      %Node{data: data} |> Node.write!
    end

    @type t :: %Node{id: integer, data: %{}}
  end
end
