defmodule Credo.Check.Readability.LargeNumbers do
  use Credo.Check,
    id: "EX3006",
    base_priority: :high,
    tags: [:formatter],
    param_defaults: [
      only_greater_than: 9_999,
      trailing_digits: []
    ],
    explanations: [
      check: """
      Numbers can contain underscores for readability purposes.
      These do not affect the value of the number, but can help read large numbers
      more easily.

          141592654 # how large is this number?

          141_592_654 # ah, it's in the hundreds of millions!

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        only_greater_than: "The check only reports numbers greater than this.",
        trailing_digits: "The check allows for the given number of trailing digits (can be a number, range or list)"
      ]
    ]

  @doc false
  def run(%SourceFile{} = source_file, params) do
    ctx =
      source_file
      |> Context.build(params, __MODULE__)
      |> Context.handle_param(:trailing_digits, fn
        %Range{} = value -> Enum.to_list(value)
        value -> List.wrap(value)
      end)

    ctx = Credo.Code.Token.reduce(source_file, &find_candidates/4, ctx)
    ctx.issues
  end

  defp find_candidates(_prev, {{:number, _}, _, "0b" <> _, _}, _next, ctx) do
    ctx
  end

  defp find_candidates(_prev, {{:number, _}, _, "0o" <> _, _}, _next, ctx) do
    ctx
  end

  defp find_candidates(_prev, {{:number, _}, _, "0x" <> _, _}, _next, ctx) do
    ctx
  end

  defp find_candidates(
         _prev,
         {{:number, _}, {line_no, column, _, _}, source, %{value: number}},
         _next,
         %{params: %{only_greater_than: only_greater_than, trailing_digits: trailing_digits}} = ctx
       )
       when number > only_greater_than do
    underscored_versions = number_with_underscores(number, trailing_digits, source)

    if not Enum.member?(underscored_versions, source) do
      put_issue(ctx, issue_for(ctx, line_no, column, source, underscored_versions))
    else
      ctx
    end
  end

  defp find_candidates(_prev, _current, _next, ctx) do
    ctx
  end

  defp number_with_underscores(number, allowed_trailing_digits, _) when is_integer(number) do
    number
    |> to_string
    |> add_underscores_to_number_string(allowed_trailing_digits)
  end

  defp number_with_underscores(number, allowed_trailing_digits, source_fragment)
       when is_number(number) do
    case String.split(source_fragment, ".", parts: 2) do
      [num, decimal] ->
        add_underscores_to_number_string(num, allowed_trailing_digits)
        |> Enum.map(fn base -> Enum.join([base, decimal], ".") end)

      [num] ->
        add_underscores_to_number_string(num, allowed_trailing_digits)
    end
  end

  defp add_underscores_to_number_string(string, allowed_trailing_digits) do
    without_trailing_digits =
      string
      |> String.reverse()
      |> String.replace(~r/(\d{3})(?=\d)/, "\\1_")
      |> String.reverse()

    all_trailing_digit_versions =
      Enum.map(allowed_trailing_digits, fn trailing_digits ->
        if String.length(string) > trailing_digits do
          base =
            String.slice(string, 0..(-1 * trailing_digits - 1)//1)
            |> String.reverse()
            |> String.replace(~r/(\d{3})(?=\d)/, "\\1_")
            |> String.reverse()

          trailing = String.slice(string, (-1 * trailing_digits)..-1//1)

          "#{base}_#{trailing}"
        end
      end)

    ([without_trailing_digits] ++ all_trailing_digit_versions)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp issue_for(%{params: %{only_greater_than: only_greater_than}} = ctx, line_no, column, trigger, expected) do
    format_issue(
      ctx,
      message:
        "Numbers larger than #{only_greater_than} should be written with underscores: #{Enum.join(expected, " or ")}",
      line_no: line_no,
      column: column,
      trigger: trigger
    )
  end
end
