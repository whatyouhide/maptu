defmodule MaptuTest do
  use ExUnit.Case

  doctest Maptu

  defmodule Dummy do
    import Maptu

    @enforce_keys [:foo, :bar]
    @keys @enforce_keys ++ [:qwe]

    defstruct @keys

    defmaptu(:new, @keys)
  end

  test "defmaptu/2" do
    assert Dummy.new(%{"foo" => 1}) == :error
    assert Dummy.new(%{"foo" => 1, "bar" => 1, "qwe" => 1}) == :ok
  end

  test "struct/1 and strict_struct/1: no __struct__ key in the given map" do
    assert Maptu.struct(%{"foo" => "bar"}) == {:error, :missing_struct_key}
    assert Maptu.strict_struct(%{"foo" => "bar"}) == {:error, :missing_struct_key}
  end

  test "struct/1 and struct_struct/1: __struct__ doesn't start with 'Elixir.'" do
    assert Maptu.struct(%{"__struct__" => "Foo"}) ==
           {:error, {:bad_module_name, "Foo"}}
    assert Maptu.strict_struct(%{"__struct__" => "Foo"}) ==
           {:error, {:bad_module_name, "Foo"}}
  end

  test "struct/1 and strict_struct/1: the module in __struct__ doesn't exist" do
    assert Maptu.struct(%{"__struct__" => "Elixir.NonExistent"}) ==
           {:error, {:non_existing_module, "NonExistent"}}
    assert Maptu.strict_struct(%{"__struct__" => "Elixir.NonExistent"}) ==
           {:error, {:non_existing_module, "NonExistent"}}
  end

  test "struct/1 and strict_struct/1: the module in __struct__ is not a struct" do
    assert Maptu.struct(%{"__struct__" => "Elixir.String"}) ==
           {:error, {:non_struct, String}}
    assert Maptu.strict_struct(%{"__struct__" => "Elixir.String"}) ==
           {:error, {:non_struct, String}}
  end

  test "struct/1: existing struct and all existing keys" do
    assert Maptu.struct(%{"__struct__" => "Elixir.URI", "port" => 4000}) ==
           {:ok, %URI{port: 4000}}
  end

  test "struct/1: existing struct and some non-existing atom fields" do
    assert Maptu.struct(%{"__struct__" => "Elixir.URI", "port" => 4000, "nonexisting_atom" => "bar"}) ==
           {:ok, %URI{port: 4000}}
  end

  test "struct/1: existing struct and some non-existing keys" do
    assert Maptu.struct(%{"__struct__" => "Elixir.URI", "port" => 4000, "foo" => "bar"}) ==
           {:ok, %URI{port: 4000}}
  end

  test "strict_struct/1: existing struct and all existing keys" do
    assert Maptu.struct(%{"__struct__" => "Elixir.URI", "port" => 4000}) ==
           {:ok, %URI{port: 4000}}
  end

  test "strict_struct/1: existing struct and some non-existing atom fields" do
    map = %{"__struct__" => "Elixir.URI", "port" => 4000, "nonexisting_atom" => "bar"}
    assert Maptu.strict_struct(map) == {:error, {:non_existing_atom, "nonexisting_atom"}}
  end

  test "strict_struct/1: existing struct and some non-existing keys" do
    map = %{"__struct__" => "Elixir.URI", "port" => 4000, "foo" => "bar"}
    assert Maptu.strict_struct(map) == {:error, {:unknown_struct_field, URI, :foo}}
  end

  test "struct/2 and strict_struct/2: the given is not a struct" do
    assert Maptu.struct(String, %{}) == {:error, {:non_struct, String}}
    assert Maptu.strict_struct(String, %{}) == {:error, {:non_struct, String}}
  end

  test "struct/2: all existing keys" do
    assert Maptu.struct(URI, %{"port" => 4000}) == {:ok, %URI{port: 4000}}
  end

  test "struct/2: some non-existing atom fields" do
    assert Maptu.struct(URI, %{"port" => 4000, "nonexisting_atom" => "bar"}) ==
           {:ok, %URI{port: 4000}}
  end

  test "struct/2: some non-existing keys" do
    assert Maptu.struct(URI, %{"port" => 4000, "foo" => "bar"}) ==
           {:ok, %URI{port: 4000}}
  end

  test "strict_struct/2: existing struct and all existing keys" do
    assert Maptu.struct(URI, %{"port" => 4000}) == {:ok, %URI{port: 4000}}
  end

  test "strict_struct/2: existing struct and some non-existing atom fields" do
    map = %{"port" => 4000, "nonexisting_atom" => "bar"}
    assert Maptu.strict_struct(URI, map) ==
           {:error, {:non_existing_atom, "nonexisting_atom"}}
  end

  test "strict_struct/2: existing struct and some non-existing keys" do
    map = %{"port" => 4000, "foo" => "bar"}
    assert Maptu.strict_struct(URI, map) ==
           {:error, {:unknown_struct_field, URI, :foo}}
  end
end
