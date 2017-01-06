defmodule Saj.Query do
  def from_path(path) do
    %{
      path: path,
      status: :inactive,
      accumulator: []
    }
  end

  def handle_value(query, path, value) do
    if :lists.prefix(query[:path], path) do
      add_value(query, path, value)
    else
      case Map.get(query, :status) do
        :building -> finish(query)
        _ -> query
      end
    end
  end

  def add_value(query, path, value) do
    sanitized_path =
      path
      |> :ordsets.subtract(query[:path])
      |> :lists.reverse

    query
    |> Map.update!(:accumulator, fn(paths) -> paths ++ [{sanitized_path, value}] end)
    |> Map.put(:status, :building)
  end

  def finish(query) do
    IO.puts("DONE: " <> inspect(query))
    Map.put(query, :status, :done)
  end
end

defmodule Saj.Searcher do
  alias Saj.Query

  def init (queries \\ []) do
    queries
    |> Enum.map(fn(query) ->
      Query.from_path(query)
    end)
  end

  def handle_value(path, :null, queries), do: handle_value(path, nil, queries)
  def handle_value(path, value, queries) do
    queries
    |> Enum.map(fn(query) ->
      Query.handle_value(query, path, value)
    end)
    |> Enum.filter(fn(query) -> Map.get(query, :status) != :done end)
  end

  def finish(queries) do
    IO.puts("finito")
    IO.puts(inspect(queries))
  end
end

defmodule Saj.Search do
  alias Saj.Searcher

  def search(path, queries \\ []) do
    initial_state = :jsonfilter.filter("", Searcher, queries, [:stream])
    {:incomplete, f} =
      path
      |> File.open!
      |> IO.stream(255)
      |> Enum.reduce(initial_state, fn(chunk, state) ->
        {:incomplete, f} = state
        f.(chunk)
      end)
    f.(:end_stream)
    :ok
  end
end
