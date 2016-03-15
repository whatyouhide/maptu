# Maptu

Maptu is a small Elixir library that provides functions to convert from
"encoded" maps to Elixir structs.

"Encoded" maps are maps/structs that have been encoded through some protocol
(like MessagePack or JSON) decoded back from that protocol. In the case of
structs, the information about the struct is lost, usually like this:

```elixir
%URI{port: 8080} |> encode() |> decode()
#=> %{"__struct__" => "Elixir.URI", "port" => 8080}
```

Maptu's job is to get that map with string keys back to an Elixir struct in a
safe way (to avoid memory leaks coming from mindlessly converting string keys to
atoms):

```elixir
%URI{port: 8080} |> encode() |> decode() |> Maptu.struct!()
#=> %URI{port: 8080}
```

## Credit

Most of the ideas in this library come from the awesome @lexmag :heart:

## Installation

Add `:maptu` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:maptu, ">= 0.0.0"}]
end
```

and be sure to add `:maptu` to your list of started applications:

```elixir
def application do
  [applications: [..., :maptu]]
end
```

[Documentation is available on Hex.][hex-docs]

## License

MIT © 2016 Andrea Leopardi, Aleksei Magusev ([license file](LICENSE.txt))


[hex-docs]: http://hexdocs.pm/maptu
