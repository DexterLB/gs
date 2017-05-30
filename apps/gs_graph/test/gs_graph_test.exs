defmodule GSGraphTest do
  use ExUnit.Case
  doctest GSGraph

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "can add root object" do
    node = GSGraph.make_node(%{foo: 'bar'})

    GSGraph.update!([
      {:adopt, node, nil}
    ])

    got = GSGraph.get(node.id)
    assert got |> GSGraph.parent == nil
    assert got |> GSGraph.pseudo_parents == %{}
    assert got |> GSGraph.parents == %{}
    assert got |> GSGraph.pseudo_children == %{}
    assert got = %{foo: 'bar'}
  end
end
