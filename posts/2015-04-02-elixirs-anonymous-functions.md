# Elixir's Anonymous Functions

Tonight in [`#elixir-lang`](irc://irc.freenode.org/#elixir-lang) someone asked about how pattern match against different versions of the function. This is possible in elixir, using multiple function heads. The one restriction is that they must have the same arity. Here's a simple example:

```elixir
test "the truth" do
  foo = fn
    bar when is_binary(bar) -> 1
    bar when is_number(bar) -> 2
  end
  assert foo.(1) == 2
  assert foo.("baz") == 1
end
```

This is an overly simplistic, contrived example but it gets the point across. I've not had occasion for using this in a real program yet, but I'm sure there are times when it's useful.
