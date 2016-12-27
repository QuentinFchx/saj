# {
#   "foo": {
#     "bar": [{"baz":1},{"baz":2}]
#   }
# }
#
# foo
# foo.bar
# foo.bar[]
# foo.bar[1]
# foo.bar[0].baz
# foo.bar[].baz

defmodule Saj.Searcher do
  use GenServer

  def start(queries) do
    {:ok, searcher} = GenServer.start(__MODULE__, [])
    searcher
  end

  def handle_event(searcher, atom, value) do
    GenServer.cast(searcher, {:event, %{atom: atom, value: value}})
  end

  def get_stack(searcher) do
    GenServer.call(searcher, {:stack})
  end

  def get_path(searcher) do
    GenServer.call(searcher, {:path})
  end

  def handle_cast({:event, event}, stack) do
    %{atom: atom, value: value} = event

    stack = case atom do
      :document ->
        case value do
          :start -> [:root]
          :end -> []
        end
      :object ->
        case value do
          :start -> ["." | stack]
          :end -> tl(stack)
        end
      :key -> [value | stack]
      _ -> stack
    end

    {:noreply, stack}
  end

  defp path_from_stack(stack) do
    stack
    |> Enum.reverse
    |> Enum.join
  end
end

defmodule Saj.Search do
  alias Saj.Searcher
  alias Saj.Parser

  def search(path, queries \\ []) do
    searcher = Searcher.start(queries)

    Parser.parse(path, fn(atom, value) ->
      Searcher.handle_event(searcher, atom, value)
    end)
  end
end
