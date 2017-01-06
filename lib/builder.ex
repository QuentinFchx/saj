defmodule Saj.Builder do
  def build(paths) do
    build(paths, 0)
  end

  def build([{path, value}], 0) when is_list(path) do
    IO.puts("FINI")
    IO.puts(inspect(value))
  end

  def build(paths, index, merge_array \\ false) do
    IO.puts("PATHS")
    IO.puts(inspect(paths))
    IO.puts(index)

    pair =
      paths
      |> Enum.drop(index)
      |> Enum.take(2)

    path1 = Enum.at(pair, 0)
    path2 = Enum.at(pair, 1)

    if is_nil(path2) do
      build(shrink(paths), 0, !merge_array)
    else
      case merge(path1, path2) do
        nil -> build(paths, index + 1)
        segment ->
          paths
          |> List.replace_at(index, segment)
          |> List.delete_at(index + 1)
          |> build(index + 1)
      end
    end
  end

  def merge({[0|segment1], value1}, {[0|segment2], value2}) when segment1 == segment2 do
    IO.puts("merge obj")
    {[0|segment1], Map.merge(value1, value2)}
  end

  def merge({[0|segment1], value1}, {[1|segment2], value2}) when segment1 == segment2 do
    IO.puts("merge array 1")
    {[0|segment1], [value1, value2]}
  end

  def merge({[0|segment1], value1}, {[n|segment2], value2}) when segment1 == segment2 and is_integer(n) do
    IO.puts("merge array n")
    {[0|segment1], value1 ++ [value2]}
  end

  def merge({segment1, value1}, {segment2, value2}) when segment1 == segment2 do
    IO.puts("merge obj")
    {segment1, Map.merge(value1, value2)}
  end

  def merge(_, _) do
    nil
  end

  def shrink({[key|sub_path], val} = segment) when is_binary(key) do
    IO.puts("shrink single")
    IO.puts(inspect(segment))

    {sub_path, Map.put(%{}, key, val)}
  end

  def shrink({[0|sub_path], val} = segment) do
    IO.puts("shrink single array")
    IO.puts(inspect(segment))

    {sub_path, [val]}
  end

  def shrink(segments) when is_list(segments) do
    IO.puts("shrink all")
    IO.puts(inspect(segments))

    longest_segment = Enum.max_by(segments, fn({path, _}) -> length(path) end)
    longest_segment_index = Enum.find_index(segments, fn(segment) -> segment == longest_segment end)
    List.replace_at(segments, longest_segment_index, shrink(longest_segment))
  end

  def test do
    accu = [{["baz", 0], 1}, {[0, "qux", 0], 3}, {[1, "qux", 0], 4}, {["baz", 1], 2}, {["qux", 1], 5}]
    build(accu)
  end
end
