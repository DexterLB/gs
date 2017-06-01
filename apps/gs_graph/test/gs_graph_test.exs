defmodule GSGraphTest do
  use ExUnit.Case
  doctest GSGraph

  test "the truth" do
    assert 1 + 1 == 2   # obligatory test for good luck
  end

  test "can add root object" do
    node = GSGraph.make_node(%{foo: 'bar'})

    assert GSGraph.update!([
      {:adopt, node, nil}
    ]) == :ok

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

  test "direct parents exist" do
    father = GSGraph.make_node(%{})
    son = GSGraph.make_node(%{})

    assert GSGraph.update!([
      {:adopt, father, nil},
      {:adopt, son, {father, "blood"}}
    ]) == :ok

    assert GSGraph.parent(son) == father.id
    assert GSGraph.children(father) == %{"blood": [son.id]}
  end
end
