defmodule Credo.CLI.Command.Diff.Task.GetGitDiff do
  use Credo.Execution.Task

  alias Credo.CLI.Command.Diff.DiffCommand
  alias Credo.CLI.Output.Shell
  alias Credo.CLI.Output.UI

  def call(exec, _opts) do
    case Execution.get_assign(exec, "credo.diff.previous_exec") do
      %Execution{} -> exec
      _ -> run_credo_and_store_resulting_execution(exec)
    end
  end

  def error(exec, _opts) do
    exec
    |> Execution.get_halt_message()
    |> puts_error_message()

    exec
  end

  defp puts_error_message(halt_message) do
    UI.warn([:red, "** (diff) ", halt_message])
    UI.warn("")
  end

  defp run_credo_and_store_resulting_execution(exec) do
    case DiffCommand.previous_ref(exec) do
      {:git, git_ref} -> run_credo_on_git_ref(exec, git_ref)
      {:git_datetime, datetime} -> run_credo_on_datetime(exec, datetime)
      {:path, path} -> run_credo_on_path_ref(exec, path)
      {:error, error} -> Execution.halt(exec, error)
    end
  end

  defp run_credo_on_git_ref(exec, git_ref) do
    working_dir = Execution.working_dir(exec)
    previous_dirname = run_git_clone_and_checkout(working_dir, git_ref)

    run_credo_on_dir(exec, previous_dirname, git_ref)
  end

  defp run_credo_on_datetime(exec, datetime) do
    case get_git_ref_for_datetime(datetime) do
      nil ->
        Execution.halt(
          exec,
          "could not determine Git ref for datetime: #{datetime}"
        )

      git_ref ->
        working_dir = Execution.working_dir(exec)
        previous_dirname = run_git_clone_and_checkout(working_dir, git_ref)

        run_credo_on_dir(exec, previous_dirname, git_ref)
    end
  end

  defp get_git_ref_for_datetime(datetime) do
    case System.cmd("git", ["rev-list", "--reverse", "--after", datetime, "HEAD"]) do
      {output, 0} -> output |> String.split(~r/\n/) |> List.first()
      _ -> nil
    end
  end

  defp run_credo_on_path_ref(exec, path) do
    run_credo_on_dir(exec, path, path)
  end

  defp run_credo_on_dir(exec, dirname, previous_git_ref) do
    {previous_argv, _last_arg} =
      exec.argv
      |> Enum.slice(1..-1)
      |> Enum.reduce({[], nil}, fn
        _, {argv, "--from-git-ref"} -> {Enum.slice(argv, 1..-2), nil}
        _, {argv, "--from-dir"} -> {Enum.slice(argv, 1..-2), nil}
        _, {argv, "--since"} -> {Enum.slice(argv, 1..-2), nil}
        "--show-kept", {argv, _last_arg} -> {argv, nil}
        ^previous_git_ref, {argv, _last_arg} -> {argv, nil}
        arg, {argv, _last_arg} -> {argv ++ [arg], arg}
      end)

    run_credo(exec, previous_git_ref, dirname, previous_argv)
  end

  defp run_credo(exec, previous_git_ref, previous_dirname, previous_argv) do
    parent_pid = self()

    spawn(fn ->
      Shell.supress_output(fn ->
        argv = previous_argv ++ ["--working-dir", previous_dirname]

        previous_exec = Credo.run(argv)

        send(parent_pid, {:previous_exec, previous_exec})
      end)
    end)

    receive do
      {:previous_exec, previous_exec} ->
        store_resulting_execution(exec, previous_git_ref, previous_dirname, previous_exec)
    end
  end

  def store_resulting_execution(
        %Execution{debug: true} = exec,
        previous_git_ref,
        previous_dirname,
        previous_exec
      ) do
    exec =
      perform_store_resulting_execution(exec, previous_git_ref, previous_dirname, previous_exec)

    previous_dirname = Execution.get_assign(exec, "credo.diff.previous_dirname")
    require Logger
    Logger.debug("Git ref checked out to: #{previous_dirname}")

    exec
  end

  def store_resulting_execution(
        exec,
        previous_git_ref,
        previous_dirname,
        previous_exec
      ) do
    perform_store_resulting_execution(exec, previous_git_ref, previous_dirname, previous_exec)
  end

  defp perform_store_resulting_execution(exec, previous_git_ref, previous_dirname, previous_exec) do
    if previous_exec.halted do
      halt_execution(exec, previous_git_ref, previous_dirname, previous_exec)
    else
      exec
      |> Execution.put_assign("credo.diff.previous_git_ref", previous_git_ref)
      |> Execution.put_assign("credo.diff.previous_dirname", previous_dirname)
      |> Execution.put_assign("credo.diff.previous_exec", previous_exec)
    end
  end

  defp halt_execution(exec, previous_git_ref, previous_dirname, previous_exec) do
    message =
      case Execution.get_halt_message(previous_exec) do
        {:config_name_not_found, message} -> message
        halt_message -> inspect(halt_message)
      end

    Execution.halt(
      exec,
      [
        :bright,
        "Running Credo on `#{previous_git_ref}` (checked out to #{previous_dirname}) resulted in the following error:\n\n",
        :faint,
        message
      ]
    )
  end

  defp run_git_clone_and_checkout(path, git_ref) do
    now = DateTime.utc_now() |> to_string |> String.replace(~r/\D/, "")
    tmp_clone_dir = Path.join(System.tmp_dir!(), "credo-diff-#{now}")
    git_root_path = git_root_path(path)
    current_dir = Path.expand(".")
    tmp_working_dir = tmp_working_dir(tmp_clone_dir, git_root_path, current_dir)

    {_output, 0} =
      System.cmd("git", ["clone", git_root_path, tmp_clone_dir],
        cd: path,
        stderr_to_stdout: true
      )

    {_output, 0} =
      System.cmd("git", ["checkout", git_ref], cd: tmp_clone_dir, stderr_to_stdout: true)

    tmp_working_dir
  end

  defp git_root_path(path) do
    {output, 0} =
      System.cmd("git", ["rev-parse", "--show-toplevel"], cd: path, stderr_to_stdout: true)

    String.trim(output)
  end

  defp tmp_working_dir(tmp_clone_dir, git_root_is_current_dir, git_root_is_current_dir) do
    tmp_clone_dir
  end

  defp tmp_working_dir(tmp_clone_dir, git_root_path, current_dir) do
    subdir_to_run_credo_in = Path.relative_to(current_dir, git_root_path)

    Path.join(tmp_clone_dir, subdir_to_run_credo_in)
  end
end
