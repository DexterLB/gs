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
      ~s(    #{d.id} -> #{b.id} [label="hates" style=dashed];),
      ~s(    #{root.id} [shape=record label="<f0> #{root.id}\\n\\<#{root.ref}\\>|<f1> "];),
      ~s(    #{a.id} [shape=record label="<f0> #{a.id}\\n\\<#{a.ref}\\>|<f1> "];),
      ~s(    #{b.id} [shape=record label="<f0> #{b.id}\\n\\<#{b.ref}\\>|<f1> "];),
      ~s(    #{c.id} [shape=record label="<f0> #{c.id}\\n\\<#{c.ref}\\>|<f1> "];),
      ~s(    #{d.id} [shape=record label="<f0> #{d.id}\\n\\<#{d.ref}\\>|<f1> "];)
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

  test "visualise data" do
    root = GsGraph.make_node(%{})
    a = GsGraph.make_node(%{})

    assert GsGraph.update!([
      {:adopt, root.id, "blood", a.id},
      {:set_data, root.id, %{foo: "bar"}},
      {:set_data, a.id, %{foo: 42, bar: "qux"}}
    ]) == :ok

    expected_lines = [
      ~s(    #{a.id} -> #{root.id} [label="blood" style=solid];),
      ~s(    #{root.id} [shape=record label="<f0> #{root.id}\\n\\<#{root.ref}\\>|<f1> foo: \\\"bar\\\"\\n"];),
      ~s(    #{a.id} [shape=record label="<f0> #{a.id}\\n\\<#{a.ref}\\>|<f1> bar: \\\"qux\\\"\\nfoo: 42\\n"];),
    ]

    result = GsGraph.visualise(MapSet.new([a.id, root.id]))
      |> to_string
      |> String.split("\n")

    assert result |> List.first == "digraph gs {"
    assert result |> List.last  == "}"

    assert result 
      |> Enum.drop(1)
      |> Enum.drop(-1)
      |> MapSet.new == MapSet.new(expected_lines)
  end

  test "subscribe receives single data update" do
    node = GsGraph.make_node(%{foo: 42})

    assert GsGraph.subscribe(self(), [node.id]) == :ok

    assert_receive({:nodes_changed, [%GsGraph.Database.Node{data: %{foo: 42}}]})

    assert GsGraph.update!([{:set_data, node.id, %{foo: 56}}]) == :ok

    assert_receive({:nodes_changed, [%GsGraph.Database.Node{data: %{foo: 56}}]})
  end

  test "subscribe receives update for child" do
    a = GsGraph.make_node(%{})
    b = GsGraph.make_node(%{foo: "bar"})

    assert GsGraph.update!([
      {:adopt, a.id, "connection", b.id}
    ]) == :ok

    assert GsGraph.subscribe(self(), [a.id]) == :ok

    :timer.sleep(100)

    assert GsGraph.update!([{:set_data, b.id, %{foo: "baz"}}]) == :ok

    a_id = a.id
    b_id = b.id

    assert_receive({:nodes_changed, [
      %GsGraph.Database.Node{id: ^b_id, data: %{foo: "baz"}},
      %GsGraph.Database.Node{id: ^a_id}
    ]})
  end

  test "unsubscribe works" do
    node = GsGraph.make_node(%{foo: 42})

    assert GsGraph.subscribe(self(), [node.id]) == :ok

    assert_receive({:nodes_changed, [%GsGraph.Database.Node{data: %{foo: 42}}]})

    assert GsGraph.update!([{:set_data, node.id, %{foo: 56}}]) == :ok

    assert_receive({:nodes_changed, [%GsGraph.Database.Node{data: %{foo: 56}}]})
  end

  test "naming node works" do
    node = GsGraph.make_node(%{})

    assert GsGraph.update!([{:set_name, node.id, "a nice node"}]) == :ok

    assert GsGraph.get_by_name("a nice node") == node.id
  end

  test "getting non-existing name returns nil" do
    assert GsGraph.get_by_name("not a real thing") == nil
  end

  test "atomic limited increment works" do
    node = GsGraph.make_node(%{hp: 20})

    assert GsGraph.update!([{:incr, node.id, :hp, 3, {0, 100}}]) == :ok

    assert GsGraph.data(node.id) == %{hp: 23}
  end

  test "atomic limited increment limits upwards" do
    node = GsGraph.make_node(%{hp: 20})

    assert GsGraph.update!([{:incr, node.id, :hp, 300, {0, 100}}]) == :ok

    assert GsGraph.data(node.id) == %{hp: 100}
  end

  test "atomic limited increment limits downwards" do
    node = GsGraph.make_node(%{hp: 20})

    assert GsGraph.update!([{:incr, node.id, :hp, -500, {0, 100}}]) == :ok

    assert GsGraph.data(node.id) == %{hp: 0}
  end
end
