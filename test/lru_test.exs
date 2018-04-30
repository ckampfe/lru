defmodule LRUTest do
  use ExUnit.Case
  use ExUnitProperties
  import StreamData
  doctest LRU

  # test "greets the world" do
  #   assert Lru.hello() == :world
  # end

  property "foo" do
    keys_gen = StreamData.atom(:alphanumeric) |> list_of() |> nonempty()
    value_gen = StreamData.term()

    ops_generator =
      bind(keys_gen, fn keys_in_cache ->
        bind(
          keys_gen |> filter(fn i -> i not in keys_in_cache end) |> nonempty(),
          fn keys_not_in_cache ->
            one_of([
              tuple({constant(:get), member_of(Enum.into(keys_in_cache, keys_not_in_cache))}),
              tuple({constant(:put), member_of(keys_in_cache), value_gen})
            ])
            |> list_of()
            |> nonempty()
          end
        )
      end)

    check all cache_size <- positive_integer(),
              opset <- ops_generator do
      cache = LRU.new(cache_size)

      gets =
        Enum.filter(opset, fn
          {:get, _} -> true
          _ -> false
        end)

      puts =
        Enum.filter(opset, fn
          {:put, _, _} -> true
          _ -> false
        end)

      unique_puts =
        puts
        |> Enum.map(fn {:put, k, _} ->
          {:put, k}
        end)
        |> MapSet.new()

      unique_puts_count = Enum.count(unique_puts)

      cache =
        Enum.reduce(opset, cache, fn
          {:get, key}, acc ->
            {new_cache, _value} = LRU.get(acc, key)
            new_cache

          {:put, key, value}, acc ->
            LRU.put(acc, key, value)
        end)

      assert LRU.count(cache) <= cache_size
      assert LRU.count(cache) <= unique_puts_count
    end
  end
end
