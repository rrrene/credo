defmodule Credo.Check.Refactor.UtcNowTruncate do
  use Credo.Check,
    id: "EX4032",
    base_priority: :high,
    explanations: [
      check: """
      `DateTime.utc_now/1` is more efficient than `DateTime.utc_now/0 |> DateTime.truncate/1`.

      For example, the code here ...

          DateTime.utc_now() |> DateTime.truncate(:second)
          NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      ... can be refactored to look like this:

          DateTime.utc_now(:second)
          NaiveDateTime.utc_now(:second)

      The reason for this is not just performance, because no separate function
      call is required, but also brevity of the resulting code.
      """
    ]

  @doc false
  def run(source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # DateTime.truncate(DateTime.utc_now(), _)
  # DateTime.truncate(DateTime.utc_now(_), _)
  # DateTime.truncate(DateTime.utc_now(_, _), _)
  defp walk(
         {{:., meta, [{:__aliases__, _, [:DateTime]}, :truncate]}, _,
          [
            {{:., _, [{:__aliases__, _, [:DateTime]}, :utc_now]}, _, _},
            _
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "DateTime"))}
  end

  # DateTime.utc_now() |> DateTime.truncate(_)
  # DateTime.utc_now(_) |> DateTime.truncate(_)
  # DateTime.utc_now(_, _) |> DateTime.truncate(_)
  defp walk(
         {:|>, _,
          [
            {{:., _, [{:__aliases__, _, [:DateTime]}, :utc_now]}, _, _},
            {{:., meta, [{:__aliases__, _, [:DateTime]}, :truncate]}, _, [_]}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "DateTime"))}
  end

  # DateTime.truncate(_ |> DateTime.utc_now(), _)
  # DateTime.truncate(_ |> DateTime.utc_now(_), _)
  defp walk(
         {{:., meta, [{:__aliases__, _, [:DateTime]}, :truncate]}, _,
          [
            {:|>, _,
             [
               _,
               {{:., _, [{:__aliases__, _, [:DateTime]}, :utc_now]}, _, _}
             ]},
            _
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "DateTime"))}
  end

  # _ |> DateTime.utc_now() |> DateTime.truncate(_)
  # _ |> DateTime.utc_now(_) |> DateTime.truncate(_)
  defp walk(
         {:|>, _,
          [
            {:|>, _,
             [
               _,
               {{:., _, [{:__aliases__, _, [:DateTime]}, :utc_now]}, _, _}
             ]},
            {{:., meta, [{:__aliases__, _, [:DateTime]}, :truncate]}, _, [_]}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "DateTime"))}
  end

  # NaiveDateTime.truncate(NaiveDateTime.utc_now(), _)
  # NaiveDateTime.truncate(NaiveDateTime.utc_now(_), _)
  # NaiveDateTime.truncate(NaiveDateTime.utc_now(_, _), _)
  defp walk(
         {{:., meta, [{:__aliases__, _, [:NaiveDateTime]}, :truncate]}, _,
          [
            {{:., _, [{:__aliases__, _, [:NaiveDateTime]}, :utc_now]}, _, _},
            _
          ]} =
           ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "NaiveDateTime"))}
  end

  # NaiveDateTime.utc_now() |> NaiveDateTime.truncate(_)
  # NaiveDateTime.utc_now(_) |> NaiveDateTime.truncate(_)
  # NaiveDateTime.utc_now(_, _) |> NaiveDateTime.truncate(_)
  defp walk(
         {:|>, _,
          [
            {{:., _, [{:__aliases__, _, [:NaiveDateTime]}, :utc_now]}, _, _},
            {{:., meta, [{:__aliases__, _, [:NaiveDateTime]}, :truncate]}, _, [_]}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "NaiveDateTime"))}
  end

  # NaiveDateTime.truncate(_ |> NaiveDateTime.utc_now(), _)
  # NaiveDateTime.truncate(_ |> NaiveDateTime.utc_now(_), _)
  defp walk(
         {{:., meta, [{:__aliases__, _, [:NaiveDateTime]}, :truncate]}, _,
          [
            {:|>, _,
             [
               _,
               {{:., _, [{:__aliases__, _, [:NaiveDateTime]}, :utc_now]}, _, _}
             ]},
            _
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "NaiveDateTime"))}
  end

  # _ |> NaiveDateTime.utc_now() |> NaiveDateTime.truncate(_)
  # _ |> NaiveDateTime.utc_now(_) |> NaiveDateTime.truncate(_)
  defp walk(
         {:|>, _,
          [
            {:|>, _,
             [
               _,
               {{:., _, [{:__aliases__, _, [:NaiveDateTime]}, :utc_now]}, _, _}
             ]},
            {{:., meta, [{:__aliases__, _, [:NaiveDateTime]}, :truncate]}, _, [_]}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "NaiveDateTime"))}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta, mod_name) do
    format_issue(
      ctx,
      message:
        "Pass time unit to `#{mod_name}.utc_now` instead of composing with `#{mod_name}.truncate/2`.",
      trigger: "#{mod_name}.truncate",
      line_no: meta[:line]
    )
  end
end
