defmodule DefMemo do
  @moduledoc """
    Adapted from : (Gustavo Brunoro) https://gist.github.com/brunoro/6159378

    A simple DefMemo macro, the main point of note being that it can
    handle identical function signatures in differing modules.

    # See tests and test_helper for examples.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [ worker(DefMemo.ResultTable.GS, []) ]

    Supervisor.start_link(children,
                            [strategy: :one_for_one,
                            name: DefMemo.ResultTable.Supervisor])
  end

  alias DefMemo.ResultTable.GS,     as: ResultTable

  defdelegate start_link,           to: ResultTable

  @doc """
    Defines a function as being memoized. Note that DefMemo.start_link
    must be called before calling a method defined with defmacro.

    # Example:
      defmodule FibMemo do
        import DefMemo

        defmemo fibs(0), do: 0
        defmemo fibs(1), do: 1
        defmemo fibs(n), do: fibs(n - 1) + fibs(n - 2)
      end

    A second argument can be provided to normalize the arguments for
    the memoization result lookup.  The original function arguments are
    provided as a List to the normalization function.

    # Example:
      defmodule BadCaser do
        defp normalize_case([x]), do: String.downcase(x)
        defmemo slow_upper(s), normalize_case do: String.upcase(s)
      end

    This might realize time savings if `downcase` were significantly cheaper to
    execute than `upcase` or space savings if a wide variety of mixed-case, yet
    otherwise the same, strings were run through this code path.
  """
  defmacro defmemo(head = {:when, _, [ {f_name, _, f_vars} | _ ] }, do: body) do
    quote do
      def unquote(head) do
        sig = {__MODULE__, unquote(f_name)}
        args = unquote(f_vars)

        case ResultTable.get(sig, args) do
          { :hit, value }   -> value
          { :miss, nil }    -> ResultTable.put(sig, args, unquote(body))
        end
      end
    end
  end

  defmacro defmemo(head = {name, _, vars}, do: body) do
    quote do
      def unquote(head) do
        sig = {__MODULE__, unquote(name)}

        case ResultTable.get(sig, unquote(vars)) do
          { :hit, value } -> value
          { :miss, nil }  -> ResultTable.put(sig, unquote(vars), unquote(body))
        end
      end
    end
  end

  defmacro defmemo(head = {:when, _, [ {f_name, _, f_vars} | _ ] }, normalizer, do: body) do
    quote do
      def unquote(head) do
        sig = {__MODULE__, unquote(f_name)}
        args = unquote(f_vars) |> unquote(normalizer)

        case ResultTable.get(sig, args) do
          { :hit, value }   -> value
          { :miss, nil }    -> ResultTable.put(sig, args, unquote(body))
        end
      end
    end
  end

  defmacro defmemo(head = {name, _, vars}, normalizer, do: body) do
    quote do
      def unquote(head) do
        sig = {__MODULE__, unquote(name)}

        args = unquote(vars) |> unquote(normalizer)

        case ResultTable.get(sig, args) do
          { :hit, value } -> value
          { :miss, nil }  -> ResultTable.put(sig, args, unquote(body))
        end
      end
    end
  end

  defmacro deathmemo(_) do
    quote do
      raise "Ryuk wants an apple!"
    end
  end
end

