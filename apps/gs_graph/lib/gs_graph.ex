use Amnesia

defmodule GsGraph do
  @moduledoc """
  foo bar
  """

  alias GsGraph.Database.Node
  alias GsGraph.Writes

  @doc """
  """
  def make_node(data = %{}) do
    Node.new(data)
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
    Node.read!(id)
  end

  def parent(node) do
    node.parent
  end

  def pseudo_parents(node) do
    node.pseudo_parents
  end

  def children(node) do
    node.children
  end

  def pseudo_children(node) do
    node.pseudo_children
  end
  
  def data(%Node{data: node_data}) do
    node_data
  end

  def data(node_id) do
    node_id |> get |> data
  end

  def visualise_all() do
    all_node_ids() |> visualise()
  end

  def visualise(node_ids) do
    ["digraph gs {\n", visual_format_edges(node_ids), "}"]
  end

  defp bool_error(true), do: :ok
  defp bool_error(false), do: :error

  defp visual_format_edges(nodes) do
    nodes |> edges_between |> Enum.map(&visual_format_edge/1)
  end

  defp visual_format_edge({from, {type, label}, to}) do
    style = case type do
      :primary      -> "solid"
      :secondary    -> "dashed"
    end

    [~s(    #{from} -> #{to} [label="#{label}" style=#{style}];), "\n"]
  end

  defp edges_between(node_ids) do
    is_local = fn({from, _, to}) ->
      (node_ids |> MapSet.member?(from)) and (node_ids |> MapSet.member?(to))
    end

    node_ids
      |> get_nodes
      |> Enum.map(&edges_for/1) 
      |> List.flatten
      |> Enum.filter(is_local) 
      |> MapSet.new
  end

  defp edges_for(node) do
    [
      case node |> parent do
        {parent_id, label} -> [{node.id, {:primary, label}, parent_id}]
        _ -> []
      end,
      node |> children |> extract_edge_pairs |> Enum.map(fn({label, child}) ->
        {child, {:primary, label}, node.id}
      end),
      node |> pseudo_children |> extract_edge_pairs |> Enum.map(fn({label, pseudo_child}) ->
        {pseudo_child, {:secondary, label}, node.id}
      end),
      node |> pseudo_parents |> extract_edge_pairs |> Enum.map(fn({label, pseudo_parent}) ->
        {node.id, {:secondary, label}, pseudo_parent}
      end)
    ]
  end

  defp extract_edge_pairs(map) do
    map
      |> Enum.map(fn({label, edges}) -> 
        Enum.map(edges, fn(edge) -> 
          {label, edge} 
        end) 
      end)
      |> List.flatten
  end

  defp get_nodes(node_ids) do
    Amnesia.transaction do
      node_ids |> Enum.map(&Node.read/1)
    end
  end

  defp all_node_ids do
    Amnesia.transaction do
      Node.match([:id]) |> Amnesia.Selection.values
    end |> Enum.map(fn(node) -> node.id end) |> MapSet.new
  end
end
