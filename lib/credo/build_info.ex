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
    if git_present?() do
      %{
        commit: git_commit(),
        branch: git_branch(),
        tag: git_tag(),
        dirty?: git_dirty?()
      }
    end
  end

  defp git_present? do
    {_, exit_status} = System.cmd("git", ["--help"])

    exit_status == 0
  end

  defp git_branch do
    case System.cmd("git", ["rev-parse", "--abbrev-ref", "HEAD"]) do
      {output, 0} -> String.trim(output)
      {_, _} -> nil
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
      {output, 0} -> String.trim(output) != ""
      {_, _} -> nil
    end
  end
end
