defmodule GsGraphTest do
  use ExUnit.Case
  doctest GsGraph

  test "the truth" do
    assert 1 + 1 == 2   # obligatory test for good luck
  end

  test "can add root object" do
    node = GsGraph.make_node(%{name: 'bruce'})

    assert GsGraph.update!([
      {:adopt, node.id, nil}
    ]) == :ok

    got = GsGraph.get(node.id)

    assert got |> GsGraph.parent == nil
    assert got |> GsGraph.pseudo_parents == %{}
    assert got |> GsGraph.children == %{}
    assert got |> GsGraph.pseudo_children == %{}
    assert got |> GsGraph.data == %{name: 'bruce'}
  end

  test "getting non-existant node returns nil" do
    assert GsGraph.get(424242) == nil
  end

  test "direct parents exist" do
    father = GsGraph.make_node(%{})
    son = GsGraph.make_node(%{})

    assert GsGraph.update!([
      {:adopt, father.id, nil},
      {:adopt, father.id, "blood", son.id}
    ]) == :ok

    new_son = GsGraph.get(son.id)
    new_father = GsGraph.get(father.id)
    assert GsGraph.parent(new_son) == {new_father.id, "blood"}
    assert GsGraph.children(new_father) == %{"blood" => MapSet.new [new_son.id]}
  end

  test "pseudo parents exist" do
    a = GsGraph.make_node(%{})
    b = GsGraph.make_node(%{})

    assert GsGraph.update!([
      {:attach, a.id, "sees", b.id}
    ]) == :ok

    new_a = GsGraph.get(a.id)
    new_b = GsGraph.get(b.id)

    assert new_b |> GsGraph.pseudo_parents == %{"sees" => MapSet.new [a.id]}
    assert new_a |> GsGraph.pseudo_children == %{"sees" => MapSet.new [b.id]}

    assert new_b |> GsGraph.pseudo_children == %{}
    assert new_a |> GsGraph.pseudo_parents == %{}
  end

  test "detach works" do
    a = GsGraph.make_node(%{})
    b = GsGraph.make_node(%{})

    assert GsGraph.update!([
      {:attach, a.id, "sees", b.id}
    ]) == :ok

    assert GsGraph.update!([
      {:detach, a.id, "sees", b.id}
    ]) == :ok

    new_a = GsGraph.get(a.id)
    new_b = GsGraph.get(b.id)

    assert new_b |> GsGraph.pseudo_parents == %{}
    assert new_a |> GsGraph.pseudo_children == %{}

    assert new_b |> GsGraph.pseudo_children == %{}
    assert new_a |> GsGraph.pseudo_parents == %{}
  end

  test "multiple connections" do
    root = GsGraph.make_node(%{})
    a = GsGraph.make_node(%{})
    b = GsGraph.make_node(%{})
    c = GsGraph.make_node(%{})
    d = GsGraph.make_node(%{})

    assert GsGraph.update!([
      {:adopt, a.id, "incest", b.id},
      {:adopt, c.id, "incest", d.id},
      {:adopt, root.id, "blood", a.id},
      {:adopt, root.id, "incest", c.id},
      {:attach, c.id, "likes", b.id},
      {:attach, c.id, "has sex with", b.id},
      {:attach, b.id, "hates", d.id}
    ]) == :ok

    new_root = GsGraph.get(root.id)
    new_a = GsGraph.get(a.id)
    new_b = GsGraph.get(b.id)
    new_c = GsGraph.get(c.id)
    new_d = GsGraph.get(d.id)

    assert new_root |> GsGraph.children == %{
      "blood" => MapSet.new([a.id]),
      "incest" => MapSet.new([c.id])
    }
    assert new_root |> GsGraph.parent == nil
    assert new_root |> GsGraph.pseudo_children == %{}
    assert new_root |> GsGraph.pseudo_parents == %{
    }

    assert new_a |> GsGraph.children == %{
      "incest" => MapSet.new [b.id]
    }
    assert new_a |> GsGraph.parent == {root.id, "blood"}
    assert new_a |> GsGraph.pseudo_children == %{}
    assert new_a |> GsGraph.pseudo_parents == %{}


    assert new_b |> GsGraph.children == %{}
    assert new_b |> GsGraph.parent == {a.id, "incest"}
    assert new_b |> GsGraph.pseudo_children == %{
      "hates" => MapSet.new [d.id]
    }
    assert new_b |> GsGraph.pseudo_parents == %{
      "likes" => MapSet.new([c.id]),
      "has sex with" => MapSet.new([c.id])
    }

    assert new_c |> GsGraph.children == %{
      "incest" => MapSet.new [d.id]
    }
    assert new_c |> GsGraph.parent == {root.id, "incest"}
    assert new_c |> GsGraph.pseudo_children == %{
      "likes" => MapSet.new([b.id]),
      "has sex with" => MapSet.new([b.id]),
    }
    assert new_c |> GsGraph.pseudo_parents == %{}

    assert new_d |> GsGraph.children == %{}
    assert new_d |> GsGraph.parent == {c.id, "incest"}
    assert new_d |> GsGraph.pseudo_children == %{}
    assert new_d |> GsGraph.pseudo_parents == %{
      "hates" => MapSet.new [b.id]
    }
  end

  test "retains data" do
    foo = GsGraph.make_node(%{foo: "bar"})

    assert foo.id |> GsGraph.data == %{foo: "bar"}
  end

  test "data can be updated" do
    foo = GsGraph.make_node(%{foo: "bar"})

    assert GsGraph.update!([
      {:set_data, foo.id, %{baz: "qux"}}
    ]) == :ok

    assert foo.id |> GsGraph.data == %{baz: "qux"}
  end

  test "visualise the graph" do
    root = GsGraph.make_node(%{})
    a = GsGraph.make_node(%{})
    b = GsGraph.make_node(%{})
    c = GsGraph.make_node(%{})
    d = GsGraph.make_node(%{})

    assert GsGraph.update!([
      {:adopt, a.id, "incest", b.id},
      {:adopt, c.id, "incest", d.id},
      {:adopt, root.id, "blood", a.id},
      {:adopt, root.id, "incest", c.id},
      {:attach, c.id, "likes", b.id},
      {:attach, c.id, "has sex with", b.id},
      {:attach, b.id, "hates", d.id}
    ]) == :ok

    expected_lines = [
      ~s(    #{b.id} -> #{a.id} [label="incest" style=solid];),
      ~s(    #{d.id} -> #{c.id} [label="incest" style=solid];),
      ~s(    #{a.id} -> #{root.id} [label="blood" style=solid];),
      ~s(    #{c.id} -> #{root.id} [label="incest" style=solid];),
      ~s(    #{b.id} -> #{c.id} [label="likes" style=dashed];),
      ~s(    #{b.id} -> #{c.id} [label="has sex with" style=dashed];),
      ~s(    #{d.id} -> #{b.id} [label="hates" style=dashed];)
    ]

    result = GsGraph.visualise(MapSet.new([a.id, b.id, c.id, d.id, root.id]))
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
