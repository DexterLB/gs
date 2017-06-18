defmodule GSGraphTest do
  use ExUnit.Case
  doctest GSGraph

  test "the truth" do
    assert 1 + 1 == 2   # obligatory test for good luck
  end

  test "can add root object" do
    node = GSGraph.make_node(%{name: 'bruce'})

    assert GSGraph.update!([
      {:adopt, node.id, nil}
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
      {:adopt, father.id, nil},
      {:adopt, father.id, "blood", son.id}
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
      {:attach, a.id, "sees", b.id}
    ]) == :ok

    new_a = GSGraph.get(a.id)
    new_b = GSGraph.get(b.id)

    assert new_b |> GSGraph.pseudo_parents == %{"sees" => MapSet.new [a.id]}
    assert new_a |> GSGraph.pseudo_children == %{"sees" => MapSet.new [b.id]}

    assert new_b |> GSGraph.pseudo_children == %{}
    assert new_a |> GSGraph.pseudo_parents == %{}
  end

  test "detach works" do
    a = GSGraph.make_node(%{})
    b = GSGraph.make_node(%{})

    assert GSGraph.update!([
      {:attach, a.id, "sees", b.id}
    ]) == :ok

    assert GSGraph.update!([
      {:detach, a.id, "sees", b.id}
    ]) == :ok

    new_a = GSGraph.get(a.id)
    new_b = GSGraph.get(b.id)

    assert new_b |> GSGraph.pseudo_parents == %{}
    assert new_a |> GSGraph.pseudo_children == %{}

    assert new_b |> GSGraph.pseudo_children == %{}
    assert new_a |> GSGraph.pseudo_parents == %{}
  end

  test "multiple connections" do
    root = GSGraph.make_node(%{})
    a = GSGraph.make_node(%{})
    b = GSGraph.make_node(%{})
    c = GSGraph.make_node(%{})
    d = GSGraph.make_node(%{})

    assert GSGraph.update!([
      {:adopt, a.id, "incest", b.id},
      {:adopt, c.id, "incest", d.id},
      {:adopt, root.id, "blood", a.id},
      {:adopt, root.id, "incest", c.id},
      {:attach, c.id, "likes", b.id},
      {:attach, c.id, "has sex with", b.id},
      {:attach, c.id, "visits", root.id},
      {:attach, b.id, "hates", d.id}
    ]) == :ok

    new_root = GSGraph.get(root.id)
    new_a = GSGraph.get(a.id)
    new_b = GSGraph.get(b.id)
    new_c = GSGraph.get(c.id)
    new_d = GSGraph.get(d.id)

    assert new_root |> GSGraph.children == %{
      "blood" => MapSet.new([a.id]),
      "incest" => MapSet.new([c.id])
    }
    assert new_root |> GSGraph.parent == nil
    assert new_root |> GSGraph.pseudo_children == %{}
    assert new_root |> GSGraph.pseudo_parents == %{
      "visits" => MapSet.new [c.id]
    }

    assert new_a |> GSGraph.children == %{
      "incest" => MapSet.new [b.id]
    }
    assert new_a |> GSGraph.parent == {root.id, "blood"}
    assert new_a |> GSGraph.pseudo_children == %{}
    assert new_a |> GSGraph.pseudo_parents == %{}


    assert new_b |> GSGraph.children == %{}
    assert new_b |> GSGraph.parent == {a.id, "incest"}
    assert new_b |> GSGraph.pseudo_children == %{
      "hates" => MapSet.new [d.id]
    }
    assert new_b |> GSGraph.pseudo_parents == %{
      "likes" => MapSet.new([c.id]),
      "has sex with" => MapSet.new([c.id])
    }

    assert new_c |> GSGraph.children == %{
      "incest" => MapSet.new [d.id]
    }
    assert new_c |> GSGraph.parent == {root.id, "incest"}
    assert new_c |> GSGraph.pseudo_children == %{
      "likes" => MapSet.new([b.id]),
      "has sex with" => MapSet.new([b.id]),
      "visits" => MapSet.new([root.id])
    }
    assert new_c |> GSGraph.pseudo_parents == %{}

    assert new_d |> GSGraph.children == %{}
    assert new_d |> GSGraph.parent == {c.id, "incest"}
    assert new_d |> GSGraph.pseudo_children == %{}
    assert new_d |> GSGraph.pseudo_parents == %{
      "hates" => MapSet.new [b.id]
    }
  end

  test "retains data" do
    foo = GSGraph.make_node(%{foo: "bar"})

    assert foo.id |> GSGraph.data == %{foo: "bar"}
  end

  test "data can be updated" do
    foo = GSGraph.make_node(%{foo: "bar"})

    assert GSGraph.update!([
      {:set_data, foo.id, %{baz: "qux"}
    ]) == :ok

    assert foo.id |> GSGraph.data == %{baz: "qux"}
  end

  test "visualise the graph" do
    root = GSGraph.make_node(%{})
    a = GSGraph.make_node(%{})
    b = GSGraph.make_node(%{})
    c = GSGraph.make_node(%{})
    d = GSGraph.make_node(%{})

    assert GSGraph.update!([
      {:adopt, a.id, "incest", b.id},
      {:adopt, c.id, "incest", d.id},
      {:adopt, root.id, "blood", a.id},
      {:adopt, root.id, "incest", c.id},
      {:attach, c.id, "likes", b.id},
      {:attach, c.id, "has sex with", b.id},
      {:attach, c.id, "visits", root.id},
      {:attach, b.id, "hates", d.id}
    ]) == :ok

    expected_lines = [
      ~s(    #{b.id} -> #{a.id} [label="incest" style=solid];),
      ~s(    #{d.id} -> #{c.id} [label="incest" style=solid];),
      ~s(    #{a.id} -> #{root.id} [label="blood" style=solid];),
      ~s(    #{c.id} -> #{root.id} [label="incest" style=solid];),
      ~s(    #{b.id} -> #{c.id} [label="likes" style=dashed];),
      ~s(    #{b.id} -> #{c.id} [label="has sex with" style=dashed];),
      ~s(    #{root.id} -> #{c.id} [label="visits" style=dashed];),
      ~s(    #{d.id} -> #{b.id} [label="hates" style=dashed];)
    ]

    result = GSGraph.visualise(MapSet.new([a.id, b.id, c.id, d.id, root.id]))
      |> to_string
      |> String.split("\n")

    assert result |> List.first == "digraph gs {"
    assert result |> List.last  == "}"

    assert result 
      |> Enum.drop(1)
      |> Enum.drop(-1)
      |> MapSet.new == MapSet.new(expected_lines)
  end
end
