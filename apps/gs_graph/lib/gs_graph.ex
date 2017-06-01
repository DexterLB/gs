use Amnesia

defmodule GSGraph do
  @moduledoc """
  foo bar
  """

  alias GSGraph.Database
  alias GSGraph.Writes

  @doc """
  """
  def make_node(data = %{}) do
    Database.Node.new(data)
  end

  def update!(operations) do
    Amnesia.transaction do
      operations
        |> Enum.map(&Writes.run/1)
        |> Enum.all?(fn(result) -> result == :ok end)
        |> bool_error
    end
  end

  def get(id) do
    Database.Node.read!(id)
  end

  def parent(node) do
    nil
  end

  def pseudo_parents(node) do
    %{}
  end

  def children(node) do
    %{}
  end

  def pseudo_children(node) do
    %{}
  end
  
  def data(node) do
    node.data
  end

  defp bool_error(true), do: :ok
  defp bool_error(false), do: :error
end
