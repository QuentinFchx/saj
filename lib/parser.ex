defmodule Saj.ParserState do
  defstruct status: nil, buffer: "", stack: [], listener: nil
end

defmodule Saj.Parser do
  alias Saj.ParserState

  def parse(path, listener) do
    state = %ParserState{
      status: :start_document,
      listener: listener
    }

    path
    |> File.open!
    |> IO.stream(1)
    |> Enum.reduce(state, fn(char, state) -> consume_char(char, state) end)
  end

  # -----------------------------------------

  @lint {Credo.Check.Refactor.CyclomaticComplexity, false}
  defp consume_char(char, state) do
    if String.length(String.strip(char)) == 0 and not state.status in [:in_string, :in_number] do
      state
    else
      case state.status do
        :start_document -> start_document(char, state)
        :in_object -> in_object(char, state)
        :in_array -> in_array(char, state)
        :in_string -> in_string(char, state)
        :end_key -> end_key(char, state)
        :after_key -> after_key(char, state)
        :after_value -> after_value(char, state)
        :in_escape -> in_escape(char, state)
        :in_number -> in_number(char, state)
        :in_true -> in_true(char, state)
        :in_false -> in_false(char, state)
        :in_null -> in_null(char, state)
      end
    end
  end

  defp start_document(char, state) do
    state.listener.(:document, :start)

    case char do
      "{" -> start_object(state)
      "[" -> start_array(state)
    end
  end

  defp in_object(char, state) do
    case char do
      "}" -> end_object(state)
      "\"" -> start_key(state)
    end
  end

  defp in_array(char, state) do
    case char do
      "]" -> end_array(state)
      _ -> start_value(char, state)
    end
  end

  defp in_string(char, state) do
    case char do
      "\"" -> end_string(state)
      "\\" -> start_escape(state)
      _ -> Map.put(state, :buffer, state.buffer <> char)
    end
  end

  defp end_key(char, state) do
    case char do
      ":" -> struct(state, %{status: :after_key})
    end
  end

  defp after_key(char, state) do
    start_value(char, state)
  end

  defp after_value(char, state) do
    case hd(state.stack) do
      :object ->
        case char do
          "}" -> end_object(state)
          "," -> struct(state, %{status: :in_object})
        end
      :array ->
        case char do
          "]" -> end_array(state)
          "," -> struct(state, %{status: :in_array})
        end
    end
  end

  defp in_escape(char, state) do
    case char do
      "u" -> struct(state, %{status: :in_string})
      escaped when escaped in ["\"", "\\", "/", "f", "n", "r", "t"] ->
        struct(state, %{status: :in_string, buffer: state.buffer <> "\\" <> escaped})
    end
  end

  defp in_number(char, state) do
    case Integer.parse(char) do
      {int, _} -> struct(state, %{buffer: state.buffer <> char})
      _ -> case char do
        "." -> state
        e when e in ["e", "E"] -> state
        sign when sign in ["-", "+"] -> state
        _ -> consume_char(char, end_number(state))
      end
    end
  end

  defp in_true(char, state) do
    state = struct(state, %{
      buffer: state.buffer <> char
    })
    if String.length(state.buffer) >= 4, do: end_true(state), else: state
  end

  defp in_false(char, state) do
    state = struct(state, %{
      buffer: state.buffer <> char
    })
    if String.length(state.buffer) >= 5, do: end_false(state), else: state
  end

  defp in_null(char, state) do
    state = struct(state, %{
      buffer: state.buffer <> char
    })
    if String.length(state.buffer) >= 4, do: end_null(state), else: state
  end

  # -------------------------------------------------

  defp end_document(state) do
    state.listener.(:document, :end)

    struct(state, %{
      status: :done
    })
  end

  defp start_object(state) do
    state.listener.(:object, :start)

    struct(state, %{
      status: :in_object,
      stack: [:object | state.stack]
    })
  end

  defp end_object(state) do
    state.listener.(:object, :end)

    [popped | stack] = state.stack
    state = struct(state, %{
      status: :after_value,
      stack: stack
    })

    case length(stack) do
      0 -> end_document(state)
      _ -> state
    end
  end

  defp start_key(state) do
    struct(state, %{
      status: :in_string,
      stack: [:key | state.stack]
    })
  end

  defp start_array(state) do
    state.listener.(:array, :start)

    struct(state, %{
      status: :in_array,
      stack: [:array | state.stack]
    })
  end

  defp end_array(state) do
    state.listener.(:array, :end)

    [popped | stack] = state.stack
    struct(state, %{
      status: :after_value,
      stack: stack
    })
  end

  defp start_value(char, state) do
    case char do
      "[" -> start_array(state)
      "{" -> start_object(state)
      "\"" -> start_string(state)
      "t" -> start_true(state)
      "f" -> start_false(state)
      "n" -> start_null(state)
      _ -> case Integer.parse(char) do
        {int, _} -> start_number(char, state)
      end
    end
  end

  defp start_string(state) do
    struct(state, %{
      status: :in_string,
      stack: [:string | state.stack]
    })
  end

  defp end_string(state) do
    [popped | stack] = state.stack

    status = case popped do
      :key ->
        state.listener.(:key, state.buffer)
        :end_key
      :string ->
        state.listener.(:value, state.buffer)
        :after_value
    end

    struct(state, %{
      status: status,
      buffer: "",
      stack: stack
    })
  end

  defp start_escape(state) do
    struct(state, %{
      status: :in_escape
    })
  end

  defp start_number(char, state) do
    struct(state, %{
      status: :in_number,
      buffer: state.buffer <> char
    })
  end

  defp end_number(state) do
    state.listener.(:number, state.buffer)

    struct(state, %{
      status: :after_value,
      buffer: ""
    })
  end

  defp start_true(state) do
    struct(state, %{
      status: :in_true,
      buffer: "t"
    })
  end

  defp end_true(state) do
    state.listener.(:value, true)

    struct(state, %{
      status: :after_value,
      buffer: ""
    })
  end

  defp start_false(state) do
    struct(state, %{
      status: :in_false,
      buffer: "f"
    })
  end

  defp end_false(state) do
    state.listener.(:value, false)

    struct(state, %{
      status: :after_value,
      buffer: ""
    })
  end

  defp start_null(state) do
    struct(state, %{
      status: :in_null,
      buffer: "n"
    })
  end

  defp end_null(state) do
    state.listener.(:value, nil)

    struct(state, %{
      status: :after_value,
      buffer: ""
    })
  end
end
