defmodule Credo.BuildInfo do
  @moduledoc false

  # This is called at compile-time and should not be used at runtime!

  @doc false
  def version(mix_version) do
    version(mix_version, git_info())
  end

  defp version(mix_version, nil) do
    mix_version
  end

  defp version(mix_version, git_info) do
    version =
      if git_info.tag == "v#{mix_version}" do
        mix_version
      else
        branch = git_info.branch || "nobranch"
        commit = git_info.commit || "nocommit"

        "#{mix_version}-ref.#{branch}.#{commit}"
      end

    if git_info.dirty? do
      "#{version}+uncommittedchanges"
    else
      version
    end
  end

  defp git_info do
    if in_git_work_tree?() do
      %{
        commit: git_commit(),
        branch: git_branch(),
        tag: git_tag(),
        dirty?: git_dirty?()
      }
    end
  end

  defp in_git_work_tree? do
    try do
      {_, exit_status} =
        System.cmd("git", ["rev-parse", "--is-inside-work-tree"], stderr_to_stdout: true)

      exit_status == 0
    rescue
      _ -> false
    end
  end

  defp git_branch do
    case System.cmd("git", ["branch"]) do
      {output, 0} -> git_branch(output)
      {_, _} -> nil
    end
  end

  defp git_branch(output) do
    line_with_active_branch =
      output
      |> String.split("\n")
      |> Enum.find(fn
        "* " <> _ -> true
        _ -> false
      end)

    case line_with_active_branch do
      "* (HEAD detached at origin/" <> remote_branch_name ->
        String.replace(remote_branch_name, ~r/\)$/, "")

      "* (HEAD detached at " <> branch_name ->
        String.replace(branch_name, ~r/\)$/, "")

      "* " <> branch_name ->
        branch_name

      _ ->
        nil
    end
  end

  defp git_commit do
    case System.cmd("git", ["rev-parse", "--short", "HEAD"]) do
      {output, 0} -> String.trim(output)
      {_, _} -> nil
    end
  end

  defp git_tag do
    case System.cmd("git", ["tag", "--points-at", "HEAD"]) do
      {output, 0} -> String.trim(output)
      {_, _} -> nil
    end
  end

  defp git_dirty? do
    case System.cmd("git", ["status", "--short"]) do
      {output, 0} -> output |> String.trim() |> git_dirty?()
      {_, _} -> nil
    end
  end

  defp git_dirty?(""), do: false
  # Hex puts a `.fetch` file in the working dir when downloading deps via git
  defp git_dirty?("?? .fetch"), do: false
  defp git_dirty?(_), do: true
end
