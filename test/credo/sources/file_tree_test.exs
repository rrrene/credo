defmodule Credo.Sources.FileTreeTest do
  use ExUnit.Case, async: true

  alias Credo.Sources.FileTree

  test "new/1 normalizes paths" do
    tree = FileTree.new(["/app/./lib/a.ex", "/app/lib/../lib/b.ex", "/app/lib/c.ex/"])

    assert MapSet.new(["/app/lib/a.ex", "/app/lib/b.ex", "/app/lib/c.ex"]) == FileTree.files(tree)
    assert ["/app/lib/a.ex", "/app/lib/b.ex", "/app/lib/c.ex"] == Enum.sort(FileTree.wildcard(tree, "/app/**/*.ex"))
  end

  test "new/1 rejects relative paths" do
    assert_raise ArgumentError, fn -> FileTree.new(["/app/lib/a.ex", "lib/b.ex"]) end
  end

  # `FileTree` relies on `:filelib.wildcard/2` invoking its callbacks synchronously in the
  # calling process, since it passes the tree to them via the process dictionary.
  # If `:filelib` ever starts running callbacks in another process (a pool, a server,
  # parallel traversal, ...), they will either find no tree (and crash) or another
  # caller's tree (and return the wrong files). This test exists to catch either case.
  test "wildcard/2 is safe to call from many processes concurrently" do
    task_count = System.schedulers_online() * 8
    iterations = 25

    results =
      1..task_count
      |> Task.async_stream(
        fn id ->
          {root, paths, tree} = tree_for(id)
          expected_all = Enum.sort(paths)
          expected_lib_ex = paths |> Enum.filter(&String.match?(&1, ~r"/lib/.*\.ex$")) |> Enum.sort()

          for _ <- 1..iterations do
            assert Enum.sort(FileTree.wildcard(tree, "/**/*.{ex,exs}")) == expected_all
            assert Enum.sort(FileTree.wildcard(tree, Path.join(root, "lib/**/*.ex"))) == expected_lib_ex
          end

          :ok
        end,
        max_concurrency: task_count,
        ordered: false,
        timeout: :infinity
      )
      |> Enum.to_list()

    assert results == List.duplicate({:ok, :ok}, task_count)
  end

  # Builds a tree rooted at a unique top-level dir, so any glob rooted at "/" can only
  # match files from the tree that was actually passed to `FileTree.wildcard/2`.
  defp tree_for(id) do
    root = "/project_#{id}"

    paths =
      for dir <- ["lib", "lib/a", "lib/a/b", "lib/a/b/c", "test", "test/support"],
          file <- ["one", "two", "three"],
          ext <- [".ex", ".exs"] do
        Path.join([root, dir, file <> "_#{id}" <> ext])
      end

    {root, paths, FileTree.new(paths)}
  end
end
