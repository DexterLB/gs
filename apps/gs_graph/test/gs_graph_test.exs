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
    assert got |> GSGraph.children == %{}
    assert got |> GSGraph.pseudo_children == %{}
    assert got |> GSGraph.data == %{foo: 'bar'}
  end

  test "getting non-existant node returns nil" do
    assert GSGraph.get(424242) == nil
  end
end
