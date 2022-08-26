defmodule Checks.LoggerIncludesMetadata do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    param_defaults: [keys: []],
    exit_status: 1,
    explanations: [
      check: """
      Sometimes we want to enforce certain keys in the metadata of log messages for our application.
      This check warns you if your make calls to `Logger` without passing all of the required metadata keys.
      """,
      params: [keys: "Keys you wish to make required for metadata on Logger calls"]
    ]

  @allowed_logger_calls ~w(alert critical debug emergency error info notice warn warning)a

  @spec run(Credo.SourceFile.t(), list()) :: list(Credo.Issue.t())
  def run(source_file, params \\ []) do
    keys = Params.get(params, :keys, __MODULE__)
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, keys, issue_meta))
  end

  defp traverse(ast, issues, [], _issue_meta) do
    {ast, issues}
  end

  # metadata passed
  defp traverse(
         {{:., _, [{:__aliases__, [{:line, line_no}, _], [:Logger]}, logger_call]}, _,
          [_message | [metadata]]} = ast,
         issues,
         required_keys,
         issue_meta
       )
       when logger_call in @allowed_logger_calls do
    metadata_keys = Keyword.keys(metadata || [])

    case required_keys -- metadata_keys do
      [] ->
        {ast, issues}

      missing_keys ->
        {ast, [issue_for(missing_keys, issue_meta, line_no) | issues]}
    end
  end

  # no metadata passed to call
  defp traverse(
         {{:., _, [{:__aliases__, [{:line, line_no}, _], [:Logger]}, logger_call]}, _, [_message]} =
           ast,
         issues,
         required_keys,
         issue_meta
       )
       when logger_call in @allowed_logger_calls do
    {ast, [issue_for(required_keys, issue_meta, line_no) | issues]}
  end

  defp traverse(ast, issues, _keys, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(missing_keys, issue_meta, line_no) do
    format_issue(issue_meta,
      message: "`Logger` call missing metadata with #{inspect(missing_keys)} key(s)",
      line_no: line_no
    )
  end
end
