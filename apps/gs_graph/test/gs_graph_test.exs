defmodule GSGraphTest do
  use ExUnit.Case
  doctest GSGraph

  test "the truth" do
    assert 1 + 1 == 2   # obligatory test for good luck
  end

  test "can add root object" do
    node = GSGraph.make_node(%{name: 'bruce'})

    assert GSGraph.update!([
      {:adopt, node, nil}
    ]) == :ok

    got = GSGraph.get(node.id)
    assert got |> GSGraph.parent == nil
    assert got |> GSGraph.pseudo_parents == %{}
    assert got |> GSGraph.children == %{}
    assert got |> GSGraph.pseudo_children == %{}
    assert got |> GSGraph.data == %{name: 'bruce'}
  end

  test "getting non-existant node returns nil" do
    assert GSGraph.get(424242) == nil
  end

  test "direct parents exist" do
    father = GSGraph.make_node(%{})
    son = GSGraph.make_node(%{})

    assert GSGraph.update!([
      {:adopt, father, nil},
      {:adopt, son, {father.id, "blood"}}
    ]) == :ok

    new_son = GSGraph.get(son.id)
    new_father = GSGraph.get(father.id)
    assert GSGraph.parent(new_son) == {new_father.id, "blood"}
    assert GSGraph.children(new_father) == %{"blood" => MapSet.new [new_son.id]}
  end

  test "pseudo parents exist" do
    a = GSGraph.make_node(%{})
    b = GSGraph.make_node(%{})

    assert GSGraph.update!([
      {:attach, b, {a.id, "sees"}}
    ]) == :ok

    new_a = GSGraph.get(a.id)
    new_b = GSGraph.get(b.id)

    assert new_b |> GSGraph.pseudo_parents == %{"sees" => MapSet.new [a.id]}
    assert new_a |> GSGraph.pseudo_children == %{"sees" => MapSet.new [b.id]}

    assert new_b |> GSGraph.pseudo_children == %{}
    assert new_a |> GSGraph.pseudo_parents == %{}
  end
end
