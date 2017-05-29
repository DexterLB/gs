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
    assert got.parent == nil
    assert got.pseudo_parents == %{}
    assert got.children == %{}
    assert got.pseudo_children == %{}
    assert got.data == %{foo: 'bar'}
  end
end
