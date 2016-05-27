defmodule MaptuTest do
  use ExUnit.Case

  doctest Maptu

  test "struct/1, struct_rest/1 and strict_struct/1: no __struct__ key in the given map" do
    assert Maptu.struct(%{"foo" => "bar"}) == {:error, :missing_struct_key}
    assert Maptu.struct_rest(%{"foo" => "bar"}) == {:error, :missing_struct_key}
    assert Maptu.strict_struct(%{"foo" => "bar"}) == {:error, :missing_struct_key}
  end

  test "struct/1, struct_rest/1 and struct_struct/1: __struct__ doesn't start with 'Elixir.'" do
    assert Maptu.struct(%{"__struct__" => "Foo"}) ==
           {:error, {:bad_module_name, "Foo"}}
    assert Maptu.struct_rest(%{"__struct__" => "Foo"}) ==
           {:error, {:bad_module_name, "Foo"}}
    assert Maptu.strict_struct(%{"__struct__" => "Foo"}) ==
           {:error, {:bad_module_name, "Foo"}}
  end

  test "struct/1, struct_rest/1 and strict_struct/1: the module in __struct__ doesn't exist" do
    assert Maptu.struct(%{"__struct__" => "Elixir.NonExistent"}) ==
           {:error, {:non_existing_module, "NonExistent"}}
    assert Maptu.struct_rest(%{"__struct__" => "Elixir.NonExistent"}) ==
           {:error, {:non_existing_module, "NonExistent"}}
    assert Maptu.strict_struct(%{"__struct__" => "Elixir.NonExistent"}) ==
           {:error, {:non_existing_module, "NonExistent"}}
  end

  test "struct/1, struct_rest/1 and strict_struct/1: the module in __struct__ is not a struct" do
    assert Maptu.struct(%{"__struct__" => "Elixir.String"}) ==
           {:error, {:non_struct, String}}
    assert Maptu.struct_rest(%{"__struct__" => "Elixir.String"}) ==
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

  test "struct_rest/1: existing struct and all existing keys" do
    assert Maptu.struct_rest(%{"__struct__" => "Elixir.URI", "port" => 4000}) ==
           {:ok, %URI{port: 4000}, %{}}
  end

  test "struct_rest/1: existing struct and some non-existing atom fields" do
    assert Maptu.struct_rest(%{"__struct__" => "Elixir.URI", "port" => 4000, "nonexisting_atom" => "bar"}) ==
           {:ok, %URI{port: 4000}, %{"nonexisting_atom" => "bar"}}
  end

  test "struct_rest/1: existing struct and some non-existing keys" do
    assert Maptu.struct_rest(%{"__struct__" => "Elixir.URI", "port" => 4000, "foo" => "bar"}) ==
           {:ok, %URI{port: 4000}, %{"foo" => "bar"}}
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

  test "struct/2, struct_rest/2 and strict_struct/2: the given is not a struct" do
    assert Maptu.struct(String, %{}) == {:error, {:non_struct, String}}
    assert Maptu.struct_rest(String, %{}) == {:error, {:non_struct, String}}
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

  test "struct_rest/2: all existing keys" do
    assert Maptu.struct_rest(URI, %{"port" => 4000}) == {:ok, %URI{port: 4000}, %{}}
  end

  test "struct_rest/2: some non-existing atom fields" do
    assert Maptu.struct_rest(URI, %{"port" => 4000, "nonexisting_atom" => "bar"}) ==
           {:ok, %URI{port: 4000}, %{"nonexisting_atom" => "bar"}}
  end

  test "struct_rest/2: some non-existing keys" do
    assert Maptu.struct_rest(URI, %{"port" => 4000, "foo" => "bar"}) ==
           {:ok, %URI{port: 4000}, %{"foo" => "bar"}}
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


  # Tests for `!` functions


  test "struct!/1, struct_rest!/1 and strict_struct!/1: raise `no __struct__ key in the given map` on error" do
    error_msg = "the given map doesn't contain a \"__struct__\" key"
    assert_raise ArgumentError, error_msg,
      fn() ->  Maptu.struct!(%{"foo" => "bar"}) end
    assert_raise ArgumentError, error_msg,
      fn() ->  Maptu.rest!(%{"foo" => "bar"}) end
    assert_raise ArgumentError, error_msg,
      fn() ->  Maptu.strict_struct!(%{"foo" => "bar"}) end
  end

  test "struct!/1, rest!/1 and strict_struct!/1: raise `not an elixir module: Foo` on error" do
    error_msg = "not an elixir module: \"Foo\""
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.struct!(%{"__struct__" => "Foo"}) end
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.rest!(%{"__struct__" => "Foo"}) end
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.strict_struct!(%{"__struct__" => "Foo"}) end
  end

  test "struct!/1, rest!/1 and strict_struct!/1: raise `module doesn't exist: NonExistent` on error" do
    error_msg = ~S"module doesn't exist: \"NonExistent\""
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.struct!(%{"__struct__" => "Elixir.NonExistent"}) end
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.rest!(%{"__struct__" => "Elixir.NonExistent"}) end
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.strict_struct!(%{"__struct__" => "Elixir.NonExistent"}) end
  end

  test "struct!/1, rest!/1 and strict_struct!/1: raise `the module in __struct__ is not a struct` on error" do
    error_msg = "module is not a struct: String"
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.struct!(%{"__struct__" => "Elixir.String"}) end
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.rest!(%{"__struct__" => "Elixir.String"})  end
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.strict_struct!(%{"__struct__" => "Elixir.String"}) end
  end

  test "struct!/1: existing struct and all existing keys" do
    assert Maptu.struct!(%{"__struct__" => "Elixir.URI", "port" => 4000}) == %URI{port: 4000}
  end

  test "struct!/1: existing struct and some non-existing atom fields" do
    assert Maptu.struct!(%{"__struct__" => "Elixir.URI", "port" => 4000, "nonexisting_atom" => "bar"}) == %URI{port: 4000}
  end

  test "struct!/1: existing struct and some non-existing keys" do
    assert Maptu.struct!(%{"__struct__" => "Elixir.URI", "port" => 4000, "foo" => "bar"}) == %URI{port: 4000}
  end

  test "rest!/1: existing struct and all existing keys" do
    assert Maptu.rest!(%{"__struct__" => "Elixir.URI", "port" => 4000}) == %{}
  end

  test "rest!/1: existing struct and some non-existing atom fields" do
    assert Maptu.rest!(%{"__struct__" => "Elixir.URI", "port" => 4000, "nonexisting_atom" => "bar"}) ==  %{"nonexisting_atom" => "bar"}
  end

  test "rest!/1: existing struct and some non-existing keys" do
    assert Maptu.rest!(%{"__struct__" => "Elixir.URI", "port" => 4000, "foo" => "bar"}) ==  %{"foo" => "bar"}
  end

  test "strict_struct!/1: existing struct and all existing keys" do
    assert Maptu.strict_struct!(%{"__struct__" => "Elixir.URI", "port" => 4000}) == %URI{port: 4000}
  end

  test "strict_struct/1: raises `atom doesn't exist: nonexisting_atom` on error" do
    error_msg =  "atom doesn't exist: \"nonexisting_atom\""
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.strict_struct!(%{"__struct__" => "Elixir.URI", "port" => 4000, "nonexisting_atom" => "bar"}) end
  end

  test "strict_struct!/1: raises `unknown field :foo for struct URI` on error" do
    error_msg =  "unknown field :foo for struct URI"
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.strict_struct!(%{"__struct__" => "Elixir.URI", "port" => 4000, "foo" => "bar"}) end
  end

  test "struct!/2, rest!/2 and strict_struct!/2: raises `module is not a struct: String` on error" do
    error_msg = "module is not a struct: String"
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.struct!(String, %{}) end
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.rest!(String, %{}) end
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.strict_struct!(String, %{}) end
  end

  test "struct!/2: all existing keys" do
    assert Maptu.struct!(URI, %{"port" => 4000}) == %URI{port: 4000}
  end

  test "struct!/2: some non-existing atom fields" do
    assert Maptu.struct!(URI, %{"port" => 4000, "nonexisting_atom" => "bar"}) == %URI{port: 4000}
  end

  test "struct!/2: some non-existing keys" do
    assert Maptu.struct!(URI, %{"port" => 4000, "foo" => "bar"}) == %URI{port: 4000}
  end

  test "rest!/2: all remaining key-value pairs" do
    assert Maptu.rest!(URI, %{"port" => 4000}) == %{}
  end

  test "rest!/2: all remaining key-value pairs withn non-existing key" do
    assert Maptu.rest!(URI, %{"port" => 4000, "nonexisting_atom" => "bar"}) == %{"nonexisting_atom" => "bar"}
  end

  test "rest!/2: all remaining key-value pairs with foo key" do
    assert Maptu.rest!(URI, %{"port" => 4000, "foo" => "bar"}) == %{"foo" => "bar"}
  end

  test "strict_struct!/2: existing struct and all existing keys" do
    assert Maptu.strict_struct!(URI, %{"port" => 4000}) == %URI{port: 4000}
  end

  test "strict_struct!/2: raises `atom doesn't exist: nonexisting_atom` on error" do
    error_msg = "atom doesn't exist: \"nonexisting_atom\""
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.strict_struct!(URI, %{"port" => 4000, "nonexisting_atom" => "bar"}) end
  end

  test "strict_struct!/2: raises `unknown field :foo for struct URI` on error" do
    error_msg = "unknown field :foo for struct URI"
    assert_raise ArgumentError, error_msg,
      fn() -> Maptu.strict_struct!(URI, %{"port" => 4000, "foo" => "bar"}) end
  end



end
