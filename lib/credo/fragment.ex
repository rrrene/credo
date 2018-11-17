defmodule Credo.Fragment do
  @moduledoc """
  Fragments are partial analysis results that are independent of the check's
  params and other file's results.
  Fragments are not invalidated if the user changes his preferences.
  """

  @credo_dir ".credo/"
  @fragment_dir Path.join(@credo_dir, "cache/fragments")

  alias Credo.SourceFile

  # TODO: cache individual fragments per check
  # TODO: write single cache file for better performance

  def save(source_file, meta, fragments) do
    filename = cache_filename(source_file)
    ff = file_fragment(source_file, meta, fragments)
    content = :erlang.term_to_binary(ff)

    File.mkdir_p!(@fragment_dir)
    File.write!(filename, content)
  end

  def load(source_file) do
    filename = cache_filename(source_file)

    if File.exists?(filename) do
      term = filename |> File.read!() |> :erlang.binary_to_term()
      source_file_name = source_file.filename

      case term do
        {:v1, ^source_file_name, meta, fragments} -> {:ok, meta, fragments}
        _ -> {:error, :incompatibleterm}
      end
    else
      {:error, :cachemiss}
    end
  end

  defp cache_filename(source_file) do
    filename = cache_key(source_file)

    Path.join(@fragment_dir, filename)
  end

  defp cache_key(source_file) do
    source = SourceFile.source(source_file)

    :crypto.hash(:sha256, source) |> Base.encode16()
  end

  defp file_fragment(source_file, meta, fragments) do
    {
      :v1,
      source_file.filename,
      meta,
      fragments
    }
  end
end
