defmodule GSGraph do
  @moduledoc """
  foo bar
  """

  alias GSGraph.Database

  @doc """
  """
  def make_node(data = %{}) do
    Database.Node.new(data)
  end

  def update!(operations) do
    nil
  end

  def get(id) do
    Database.Node.read!(id) |> hd
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
end
