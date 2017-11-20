defmodule Maptu do
  @moduledoc """
  Provides functions to convert from "dumped" maps to Elixir structs.

  This module provides functions to safely convert maps (with string keys) that
  represent structs (usually decoded from some kind of protocol, like
  MessagePack or JSON) to Elixir structs.

  ## Rationale

  Many Elixir libraries need to encode and decode maps as well as
  structs. Encoding is often straightforward (think of libraries like
  [poison][gh-poison] or [msgpax][gh-msgpax]): the map is encoded by converting
  keys to strings and encoding values recursively. This works natively with
  structs as well, since structs are just maps with an additional `:__struct__`
  key.

  The problem arises when such structs have to be decoded back to Elixir terms:
  decoding will often result in a map with string keys (as the information about
  keys being atoms were lost in the encoding), including a `"__struct__"` key.
  Trying to blindly convert all these string keys to atoms and building a struct
  by reading the `:__struct__` key is dangerous: converting dynamic input to
  atoms is one of the most frequent culprit of memory leaks in Erlang
  applications. This is where `Maptu` becomes useful: it provides functions that
  safely convert from this kind of maps to Elixir structs.

  ## Use case

  Let's pretend we're writing a JSON encoder/decoder for Elixir. We have
  generic encoder/decoder that work for all kinds of maps:

      def encode(map) when is_map(map) do
        # some binary is built here
      end

      def decode(bin) when is_binary(bin) do
        # decoding happens here
      end

  When we encode and then decode a struct, something like this is likely to happen:

      %URI{port: 8080} |> encode() |> decode()
      #=> %{"__struct__" => "Elixir.URI", "port" => 8080}

  To properly decode the struct back to a `%URI{}` struct, we would have to
  check the value of `"__struct__"` (check that it's an existing atom and then
  an existing module), then check each key-value pair in the map to see if it's
  a field of the `URI` struct and so on. `Maptu` does exactly this!

      %URI{port: 8080} |> encode() |> decode() |> Maptu.struct!()
      #=> %URI{port: 8080}

  This is just one use case `Maptu` is good at; read the documentation for the
  provided functions for more information on the capabilities of this library.

  [gh-poison]: https://github.com/devinus/poison
  [gh-msgpax]: https://github.com/lexmag/msgpax

  """

  import Kernel, except: [struct: 1, struct: 2]

  # TODO: maybe revisit naming of :non_* error reasons in v2.0 so that we drop the underscore.

  @type non_strict_error_reason ::
    :missing_struct_key
    | {:bad_module_name, binary}
    | {:non_existing_module, binary}
    | {:non_struct, module}

  @type strict_error_reason ::
    non_strict_error_reason
    | {:non_existing_atom, binary}
    | {:unknown_struct_field, module, atom}

  # We use a macro for this so we keep a nice stacktrace.
  defmacrop raise_on_error(code) do
    quote do
      case unquote(code) do
        {:ok, result}    -> result
        {:error, reason} -> raise ArgumentError, format_error(reason)
      end
    end
  end

  @doc """
  Converts a map to a struct, silently ignoring erroneous keys.

  `map` is a map with binary keys that represents a "dumped" struct; it must
  contain a `"__struct__"` key with a binary value that can be converted to a
  valid module name. If the value of `"__struct__"` is not a module name or it's
  a module that isn't a struct, then an error is returned.

  Keys in `map` that are not fields of the resulting struct are simply
  discarded.

  This function returns `{:ok, struct}` if the conversion is successful,
  `{:error, reason}` otherwise.

  ## Examples

      iex> Maptu.struct(%{"__struct__" => "Elixir.URI", "port" => 8080, "foo" => 1})
      {:ok, %URI{port: 8080}}

      iex> Maptu.struct(%{"__struct__" => "Elixir.GenServer"})
      {:error, {:non_struct, GenServer}}

  """
  @spec struct(map) :: {:ok, struct} | {:error, non_strict_error_reason}
  def struct(map) do
    with {:ok, {mod_name, fields}} <- extract_mod_name_and_fields(map),
         {:ok, mod}                <- module_to_atom(mod_name),
      do: struct(mod, fields)
  end

  @doc """
  Converts a map to a struct, failing on erroneous keys.

  This function behaves like `Maptu.struct/1`, except that it returns an error
  if one of the fields in `map` isn't a field of the resulting struct.

  This function returns `{:ok, struct}` if the conversion is successful,
  `{:error, reason}` otherwise.

  ## Examples

      iex> Maptu.strict_struct(%{"__struct__" => "Elixir.URI", "port" => 8080})
      {:ok, %URI{port: 8080}}

      iex> Maptu.strict_struct(%{"__struct__" => "Elixir.URI", "pid" => 1})
      {:error, {:unknown_struct_field, URI, :pid}}

  """
  @spec strict_struct(map) :: {:ok, struct} | {:error, strict_error_reason}
  def strict_struct(map) do
    with {:ok, {mod_name, fields}} <- extract_mod_name_and_fields(map),
         {:ok, mod}                <- module_to_atom(mod_name),
      do: strict_struct(mod, fields)
  end

  @doc """
  Behaves like `Maptu.struct/1` but raises in case of error.

  This function behaves like `Maptu.struct/1`, but it returns `struct` (instead
  of `{:ok, struct}`) if the conversion is valid, and raises an `ArgumentError`
  exception if it's not valid.

  ## Examples

      iex> Maptu.struct!(%{"__struct__" => "Elixir.URI", "port" => 8080})
      %URI{port: 8080}

      iex> Maptu.struct!(%{"__struct__" => "Elixir.GenServer"})
      ** (ArgumentError) module is not a struct: GenServer

  """
  @spec struct!(map) :: struct | no_return
  def struct!(map) do
    map |> struct() |> raise_on_error()
  end

  @doc """
  Behaves like `Maptu.strict_struct/1` but raises in case of error.

  This function behaves like `Maptu.strict_struct/1`, but it returns `struct`
  (instead of `{:ok, struct}`) if the conversion is valid, and raises an
  `ArgumentError` exception if it's not valid.

  ## Examples

      iex> Maptu.strict_struct!(%{"__struct__" => "Elixir.URI", "port" => 8080})
      %URI{port: 8080}

      iex> Maptu.strict_struct!(%{"__struct__" => "Elixir.URI", "pid" => 1})
      ** (ArgumentError) unknown field :pid for struct URI

  """
  @spec strict_struct!(map) :: struct | no_return
  def strict_struct!(map) do
    map |> strict_struct() |> raise_on_error()
  end

  @doc """
  Builds the `mod` struct with the given `fields`, silently ignoring erroneous
  keys.

  This function takes a struct `mod` (`mod` should be a module that defines a
  struct) and a map of fields with binary keys. It builds the `mod` struct by
  safely parsing the fields in `fields`.

  If a key in `fields` doesn't map to a field in the resulting struct, it's
  ignored.

  This function returns `{:ok, struct}` if the building is successful,
  `{:error, reason}` otherwise.

  ## Examples

      iex> Maptu.struct(URI, %{"port" => 8080, "nonexisting_field" => 1})
      {:ok, %URI{port: 8080}}
      iex> Maptu.struct(GenServer, %{})
      {:error, {:non_struct, GenServer}}

  """
  @spec struct(module, map) :: {:ok, struct} | {:error, non_strict_error_reason}
  def struct(mod, fields) when is_atom(mod) and is_map(fields) do
    with :ok <- ensure_struct(mod), do: fill_struct(mod, fields)
  end

  @doc """
  Builds the `mod` struct with the given `fields`, failing on erroneous keys.

  This function behaves like `Maptu.strict_struct/2`, except it returns an error
  when keys in `fields` don't map to fields in the resulting struct.

  This function returns `{:ok, struct}` if the building is successful,
  `{:error, reason}` otherwise.

  ## Examples

      iex> Maptu.strict_struct(URI, %{"port" => 8080})
      {:ok, %URI{port: 8080}}
      iex> Maptu.strict_struct(URI, %{"pid" => 1})
      {:error, {:unknown_struct_field, URI, :pid}}

  """
  @spec strict_struct(module, map) :: {:ok, struct} | {:error, strict_error_reason}
  def strict_struct(mod, fields) when is_atom(mod) and is_map(fields) do
    with :ok <- ensure_struct(mod), do: strict_fill_struct(mod, fields)
  end

  @doc """
  Behaves like `Maptu.struct/2` but raises in case of error.

  This function behaves like `Maptu.struct/2`, but it returns `struct` (instead
  of `{:ok, struct}`) if the conversion is valid, and raises an `ArgumentError`
  exception if it's not valid.

  ## Examples

      iex> Maptu.struct!(URI, %{"port" => 8080})
      %URI{port: 8080}

      iex> Maptu.struct!(GenServer, %{})
      ** (ArgumentError) module is not a struct: GenServer

  """
  @spec struct!(module, map) :: struct | no_return
  def struct!(mod, fields) do
    struct(mod, fields) |> raise_on_error()
  end

  @doc """
  Behaves like `Maptu.strict_struct/2` but raises in case of error.

  This function behaves like `Maptu.strict_struct/2`, but it returns `struct`
  (instead of `{:ok, struct}`) if the conversion is valid, and raises an
  `ArgumentError` exception if it's not valid.

  ## Examples

      iex> Maptu.strict_struct!(URI, %{"port" => 8080})
      %URI{port: 8080}

      iex> Maptu.strict_struct!(URI, %{"pid" => 1})
      ** (ArgumentError) unknown field :pid for struct URI

  """
  @spec strict_struct!(module, map) :: struct | no_return
  def strict_struct!(mod, fields) do
    strict_struct(mod, fields) |> raise_on_error()
  end

  defp extract_mod_name_and_fields(%{"__struct__" => "Elixir." <> _} = map),
    do: {:ok, Map.pop(map, "__struct__")}
  defp extract_mod_name_and_fields(%{"__struct__" => name}),
    do: {:error, {:bad_module_name, name}}
  defp extract_mod_name_and_fields(%{}),
    do: {:error, :missing_struct_key}

  defp module_to_atom("Elixir." <> name = mod_name) do
    case to_existing_atom_safe(mod_name) do
      {:ok, mod} -> {:ok, mod}
      :error     -> {:error, {:non_existing_module, name}}
    end
  end

  defp ensure_struct(mod) when is_atom(mod) do
    if Code.ensure_compiled?(mod) && function_exported?(mod, :__struct__, 0) do
      :ok
    else
      {:error, {:non_struct, mod}}
    end
  end

  defp fill_struct(mod, fields) do
    result = Enum.reduce fields, mod.__struct__(), fn({field, value}, acc) ->
      case to_existing_atom_safe(field) do
        {:ok, field} ->
          if Map.has_key?(acc, field), do: Map.put(acc, field, value), else: acc
        :error ->
          acc
      end
    end
    {:ok, result}
  end

  defp strict_fill_struct(mod, fields) do
    try do
      result = Enum.reduce fields, mod.__struct__(), fn({field, value}, acc) ->
        case to_existing_atom_safe(field) do
          {:ok, field} ->
            if Map.has_key?(acc, field) do
              Map.put(acc, field, value)
            else
              throw({:unknown_struct_field, mod, field})
            end
          :error ->
            throw({:non_existing_atom, field})
        end
      end
      {:ok, result}
    catch
      :throw, reason ->
        {:error, reason}
    end
  end

  defp to_existing_atom_safe(bin) when is_binary(bin) do
    try do
      String.to_existing_atom(bin)
    rescue
      ArgumentError -> :error
    else
      atom -> {:ok, atom}
    end
  end

  defp format_error(:missing_struct_key),
    do: "the given map doesn't contain a \"__struct__\" key"
  defp format_error({:bad_module_name, name}) when is_binary(name),
    do: "not an elixir module: #{inspect name}"
  defp format_error({:non_struct, mod}) when is_atom(mod),
    do: "module is not a struct: #{inspect mod}"
  defp format_error({:non_existing_atom, bin}) when is_binary(bin),
    do: "atom doesn't exist: #{inspect bin}"
  defp format_error({:unknown_struct_field, struct, field})
  when is_atom(struct) and is_atom(field),
    do: "unknown field #{inspect field} for struct #{inspect struct}"
end
