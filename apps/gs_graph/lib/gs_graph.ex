use Amnesia
defmodule GsGraph do
  @moduledoc """
    This module provides an abstraction for operating with "nodes". Each
    node can have connections to other nodes, which can be weak (pseudo) and strong.

    Each connection has a label. Each node has a single parent (aka incoming
    strong connection), but can have many pseudo parents.

    Each node can have many children and pseudo children.

    The only purpose of strong connections is to maintain consistency:
    deleting a node will cascade to all its children with strong connections.

    Each node is identified by an unique id, and has an update ref. Whenever
    a node is updated in any way, its ref changes, propagating to parents.

    One can subscribe to a node to receive updates each time its ref is updated
    (which effectively means that updates will be received whenever any node
    downwards from the subscribed node is updated)
  """

  alias GsGraph.Database.Node
  alias GsGraph.Database.Name
  alias GsGraph.Writes
  alias GsGraph.RefKeeper

  @doc """
    Creates a node with the given data
  """
  def make_node(data = %{}) do
    Node.new(data)
  end

  @doc """
    Atomically performs a series of write operations
  """
  def update!(operations) do
    # TODO: loop over all writes, transforming IDs to their respective
    # nodes

    Amnesia.transaction do
      results = operations |> Enum.map(&Writes.run/1)
      errors = results |> Enum.filter(&is_error/1)

      case errors do
        [] -> results |> List.flatten |> nudge
        errors -> Amnesia.cancel({:error, errors})
      end

      :ok
    end
  end

  @doc """
    The given nodes will receive an update
  """
  def nudge(nodes) do
    nodes |> Enum.map(fn(node) -> node.id end) |> MapSet.new |> RefKeeper.nudge
  end

  def get(id) do
    Node.read!(id)
  end

  # this should be private (or at least discouraged from use)
  def parent(node) do
    node.parent
  end

  # this should be private (or at least discouraged from use)
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

  def child(node_id, label) do
    node = node_id |> get
    matching_children = case node |> children |> Map.get(label) do
      nil -> []
      ids -> ids |> MapSet.to_list
    end

    matching_pseudo_children = case node |> pseudo_children |> Map.get(label) do
      nil -> []
      ids -> ids |> MapSet.to_list
    end
      

    [child|_] = List.flatten([matching_children, matching_pseudo_children])

    child
  end

  def get_by_name(name) do
    case Name.read!(name) do
      nil -> nil
      rec -> rec.node_id
    end
  end

  @doc """
    The given pid will receive updates about the given nodes and their children
    until it dies
  """
  def subscribe(pid, node_ids) do
    case GsGraph.Subscriber.Supervisor.start_subscriber({pid, node_ids}) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  def visualise_all() do
    all_node_ids() |> visualise()
  end

  def visualise(node_ids) do
    nodes = get_nodes(node_ids)
    [
      "digraph gs {\n",
        visual_format_edges(nodes), 
        visual_format_nodes(nodes),
      "}"
    ]
  end

  defp visual_format_edges(nodes) do
    nodes |> edges_between |> Enum.map(&visual_format_edge/1)
  end

  defp visual_format_nodes(nodes) do
    nodes |> Enum.map(&visual_format_node/1)
  end

  defp visual_format_edge({from, {type, label}, to}) do
    style = case type do
      :primary      -> "solid"
      :secondary    -> "dashed"
    end

    [~s(    #{from} -> #{to} [label="#{label}" style=#{style}];), "\n"]
  end

  defp visual_format_node(node) do
    format_data = fn(data) ->
      data 
        |> Map.to_list 
        |> Enum.sort 
        |> Enum.map(
          fn({k, v}) -> 
            "#{k}: #{inspect(v)}\\n" |> String.replace("\"", "\\\"")
          end
        )
    end

    [
      ~s(    #{node.id} [shape=record label="), 
      ~s(<f0> #{node.id}\\n\\<#{node.ref}\\>|),
      ~s(<f1> ),
      format_data.(node.data),
      ~s("];),
      "\n"
    ]
  end

  defp edges_between(nodes) do
    node_ids = Enum.map(nodes, fn(node) -> node.id end) |> MapSet.new

    is_local = fn({from, _, to}) ->
      (node_ids |> MapSet.member?(from)) and (node_ids |> MapSet.member?(to))
    end

    nodes
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

  defp is_error({:error, _}), do: true
  defp is_error(_), do: false
end
