defmodule LRU do
  require Cbuf.Map, as: Buf
  defstruct impl: %{}, ages: nil, size: 0, count: 0

  @doc """
  Make a new LRU cache of a given size backed by a map-based circular buffer.

      iex> LRU.new(5)
      #LRU<%{}>
  """
  def new(size) when size > 0 do
    %__MODULE__{impl: %{}, ages: Buf.new(size), size: size, count: 0}
  end

  @doc """
  Get something

      iex> cache = LRU.new(3)
      iex> cache = cache |> LRU.put(:a, 1) |> LRU.put(:b, 2) |> LRU.put(:c, 3) |> LRU.put(:d, 4)
      iex> {_cache, value} = LRU.get(cache, :b)
      iex> value
      2

      iex> cache = LRU.new(3)
      iex> cache = cache |> LRU.put(:a, 1) |> LRU.put(:b, 2) |> LRU.put(:c, 3) |> LRU.put(:d, 4)
      iex> {cache, _value} = LRU.get(cache, :b)
      iex> cache |> LRU.put(:z, 99)
      #LRU<%{b: 2, d: 4, z: 99}>
  """
  def get(cache, key) do
    ages = cache.ages |> Buf.delete_value(key) |> Buf.insert(key)
    cache = %{cache | ages: ages}
    value = Map.get(cache.impl, key)

    {cache, value}
  end

  @doc """
  Put something

      iex> cache = LRU.new(3)
      iex> cache |> LRU.put(:a, 1) |> LRU.put(:b, 2) |> LRU.put(:c, 3) |> LRU.put(:d, 4)
      #LRU<%{b: 2, c: 3, d: 4}>
  """
  def put(cache, key, value) do
    if cache.count >= cache.size do
      key_to_delete = Buf.peek(cache.ages)

      new_impl =
        cache.impl
        |> Map.delete(key_to_delete)
        |> Map.put(key, value)

      %{cache | impl: new_impl, ages: Buf.insert(cache.ages, key)}
    else
      %{
        cache
        | impl: Map.put(cache.impl, key, value),
          ages: Buf.insert(cache.ages, key),
          count: cache.count + 1
      }
    end
  end

  @doc """
  Return the cache's map representation

      iex> cache = LRU.new(3)
      iex> cache = cache |> LRU.put(:a, 1) |> LRU.put(:b, 2) |> LRU.put(:c, 3) |> LRU.put(:d, 4)
      iex> LRU.to_map(cache)
      %{b: 2, c: 3, d: 4}
  """
  def to_map(cache) do
    cache.impl
  end

  @doc """
  Get the number of items in the cache.

      iex> LRU.new(5) |> LRU.put(:a, :b) |> LRU.count()
      1

      iex> LRU.new(5) |> LRU.count()
      0
  """
  def count(cache) do
    cache.count
  end

  @doc """
  Get the capacity of the cache.

      iex> LRU.new(5) |> LRU.put(:a, :b) |> LRU.size()
      5

      iex> LRU.new(5) |> LRU.size()
      5
  """
  def size(cache) do
    cache.size
  end

  @doc """
  Check if the cache has a key.

      iex> cache = LRU.new(3)
      iex> cache = cache |> LRU.put(:a, 1) |> LRU.put(:b, 2) |> LRU.put(:c, 3) |> LRU.put(:d, 4)
      iex> LRU.member?(cache, :b)
      true

      iex> cache = LRU.new(3)
      iex> LRU.member?(cache, :z)
      false
  """
  def member?(cache, key) do
    Map.has_key?(cache.impl, key)
  end

  defimpl Collectable, for: LRU do
    def into(original) do
      collector_fun = fn
        buf, {:cont, {key, val}} ->
          LRU.put(buf, key, val)

        buf, :done ->
          buf

        _buf, :halt ->
          :ok
      end

      {original, collector_fun}
    end
  end

  defimpl Enumerable, for: LRU do
    def count(cache), do: {:ok, LRU.count(cache)}
    def member?(cache, key), do: {:ok, LRU.member?(cache, key)}
    def reduce(cache, acc, fun), do: Enumerable.Map.reduce(LRU.to_map(cache), acc, fun)
    def slice(_buf), do: {:error, __MODULE__}
  end

  defimpl Inspect, for: LRU do
    import Inspect.Algebra

    def inspect(buf, opts) do
      concat(["#LRU<", to_doc(LRU.to_map(buf), opts), ">"])
    end
  end
end
