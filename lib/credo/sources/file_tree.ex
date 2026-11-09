defmodule Credo.Sources.FileTree do
  @moduledoc false

  # A read-only, in-memory facade for the filesystem.
  #
  # `Credo.Sources` uses this to evaluate the `files` param of individual checks against
  # the source files that were already loaded, rather than hitting the disk for every check.
  # Matching is still done by `:filelib.wildcard/2` (exactly like `Path.wildcard/1` does it),
  # so glob semantics are identical to if you had actually traversed the filesystem.

  require Record

  # We need to keep our records in this format for the sake of the :filelib callbacks
  Record.defrecordp(:file_info, Record.extract(:file_info, from_lib: "kernel/include/file.hrl"))

  # `:filelib` requires a module with `read_file_info/1`, `read_link_info/1` and `list_dir/1` callbacks.
  # It *only* accepts an atom module (there's no way to pass state). But, it always invokes the callbacks
  # *synchronously* in the calling process. Thus, it's safe for us to stash the tree in the process dictionary
  # for the duration of `wildcard/2`: it's process-local, so concurrent callers can't see each other's trees.
  @process_dict_key {__MODULE__, :tree}

  defstruct files: MapSet.new(), dirs: %{}

  @doc """
  Builds a file tree from the given list of absolute (expanded) file paths.
  """
  def new(paths) do
    %__MODULE__{files: MapSet.new(paths), dirs: Enum.reduce(paths, %{}, &add_to_parents(&2, &1))}
  end

  defp add_to_parents(dirs, path) do
    parent = Path.dirname(path)

    if parent == path do
      dirs
    else
      name = Path.basename(path)

      case dirs do
        %{^parent => children} ->
          # parent is already known, so are all of its ancestors
          Map.put(dirs, parent, MapSet.put(children, name))

        _ ->
          dirs
          |> Map.put(parent, MapSet.new([name]))
          |> add_to_parents(parent)
      end
    end
  end

  def regular?(%__MODULE__{files: files}, path), do: MapSet.member?(files, path)

  def dir?(%__MODULE__{dirs: dirs}, path), do: Map.has_key?(dirs, path)

  @doc """
  Like `Path.wildcard/1`, but traversing `tree` instead of the actual filesystem.

  Unlike `Path.wildcard/1`, `glob` must be an absolute path, since the tree only knows
  about absolute paths (a relative glob would otherwise silently match nothing).
  """
  def wildcard(%__MODULE__{} = tree, glob) do
    if Path.type(glob) != :absolute do
      raise ArgumentError, "expected an absolute glob, got: #{inspect(glob)}"
    end

    Process.put(@process_dict_key, tree)

    try do
      glob
      |> String.to_charlist()
      |> :filelib.wildcard(__MODULE__)
      |> Enum.map(&IO.chardata_to_string/1)
    after
      Process.delete(@process_dict_key)
    end
  end

  # callbacks for `:filelib`

  @doc false
  def read_file_info(name) do
    tree = Process.get(@process_dict_key)
    path = IO.chardata_to_string(name)

    cond do
      dir?(tree, path) -> {:ok, file_info(type: :directory)}
      regular?(tree, path) -> {:ok, file_info(type: :regular)}
      true -> {:error, :enoent}
    end
  end

  @doc false
  def read_link_info(name), do: read_file_info(name)

  @doc false
  def list_dir(name) do
    tree = Process.get(@process_dict_key)
    path = IO.chardata_to_string(name)

    case tree.dirs do
      %{^path => children} ->
        # like `Path.wildcard/1`, ignore entries starting with a dot
        {:ok, for(child <- children, not String.starts_with?(child, "."), do: String.to_charlist(child))}

      _ ->
        {:error, :enoent}
    end
  end
end
