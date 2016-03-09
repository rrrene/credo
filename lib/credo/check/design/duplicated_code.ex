defmodule Credo.Check.Design.DuplicatedCode do
  @moduledoc """
  Code should not be copy-pasted in a codebase when there is room to abstract
  the copied functionality in a meaningful way.

  That said, you should by no means "ABSTRACT ALL THE THINGS!".

  Sometimes it can serve a purpose to have code be explicit in two places, even
  if it means the snippets are nearly identical. A good example for this are
  Database Adapters in a project like Ecto, where you might have nearly
  identical functions for things like `order_by` or `limit` in both the
  Postgres and MySQL adapters.

  In this case, introducing an `AbstractAdapter` just to avoid code duplication
  might cause more trouble down the line than having a bit of duplicated code.

  Like all `Software Design` issues, this is just advice and might not be
  applicable to your project/situation.
  """

  @explanation [
    check: @moduledoc,
    params: [
      mass_threshold: "The minimum mass which a part of code has to have to qualify for this check.",
      nodes_threshold: "The number of nodes that need to be found to raise an issue."
    ]
  ]
  @default_params [
    mass_threshold: 16,
    nodes_threshold: 2,
  ]

  alias Credo.SourceFile
  alias Credo.Issue

  use Credo.Check, run_on_all: true, base_priority: :higher

  def run(source_files, params \\ []) when is_list(source_files) do
    mass_threshold = params |> Params.get(:mass_threshold, @default_params)
    nodes_threshold = params |> Params.get(:nodes_threshold, @default_params)

    source_files
    |> duplicate_nodes(mass_threshold)
    |> add_issues_to_source_files(source_files, nodes_threshold, params)
  end

  defp add_issues_to_source_files(hashes, source_files, nodes_threshold, params) when is_map(hashes) do
    Enum.reduce(hashes, source_files, fn({_hash, nodes}, source_files) ->
      filenames = nodes |> Enum.map(&(&1.filename))
      Enum.reduce(source_files, [], fn(source_file, acc) ->
        if Enum.member?(filenames, source_file.filename) do
          this_node = Enum.find(nodes, &(&1.filename == source_file.filename))
          other_nodes = List.delete(nodes, this_node)

          issue_meta = IssueMeta.for(source_file, params)
          new_issue = issue_for(issue_meta, this_node, other_nodes, nodes_threshold)

          issues = source_file.issues ++ List.wrap(new_issue)
          source_file = %SourceFile{source_file | issues: issues}
        end
        acc ++ [source_file]
      end)
    end)
  end

  defp duplicate_nodes(source_files, mass_threshold) do
    source_files
    |> Enum.reduce(%{}, fn(source_file, acc) ->
        hashes(source_file.ast, acc, source_file.filename, mass_threshold)
      end)
    |> prune_hashes
    |> add_masses
  end

  def add_masses(hashes) do
    hashes
    |> Enum.map(&add_mass_to_subnode/1)
    |> Enum.into(%{})
  end

  defp add_mass_to_subnode({hash, node_items}) do
    node_items =
      node_items
      |> Enum.map(fn (struct) ->
          %{struct | mass: mass(struct.node)}
         end)

    {hash, node_items}
  end

  @doc """
  Takes a map of hashes to nodes and prunes those nodes that are just
  subnodes of others in the same set.

  Returns the resulting map.
  """
  def prune_hashes(hashes) do
    # remove entries containing a single node
    hashes =
      hashes
      |> Enum.filter(fn {_hash, node_items} -> Enum.count(node_items) > 1 end)
      |> Enum.into(%{})

    hashes_to_prune = Enum.flat_map(hashes, &collect_subhashes/1)
    hashes = delete_keys hashes_to_prune, hashes
    hashes
  end

  defp delete_keys([], acc), do: acc
  defp delete_keys([head | tail], acc) do
    delete_keys(tail, Map.delete(acc, head))
  end

  defp collect_subhashes({_hash, node_items}) do
    %{node: first_node, filename: filename} = Enum.at(node_items, 0)

    my_hash = first_node |> remove_metadata |> to_hash
    subhashes =
      first_node
      |> hashes(%{}, filename)
      |> Map.keys
      |> List.delete(my_hash) # don't count self

    subhashes
  end

  @doc """
  Calculates hash values for all sub nodes in a given +ast+.

  Returns a map with the hashes as keys and the nodes as values.
  """
  def hashes(ast, existing_hashes \\ %{}, filename \\ "foo.ex", mass_threshold \\ @default_params[:mass_threshold]) when is_map(existing_hashes) do
    Credo.Code.traverse(ast,
                &collect_hashes(&1, &2, filename, mass_threshold), existing_hashes)
  end

  defp collect_hashes(ast, acc, filename, mass_threshold) do
    if mass(ast) < mass_threshold do
      {ast, acc}
    else
      hash = ast |> remove_metadata |> to_hash
      node_item = %{node: ast, filename: filename, mass: nil}
      node_items = Map.get(acc, hash, [])
      acc = Map.put(acc, hash, node_items ++ [node_item])
      {ast, acc}
    end
  end

  @doc """
  Returns an AST without its metadata.
  """
  def remove_metadata(ast) when is_tuple(ast) do
    clean_node(ast)
  end
  def remove_metadata(ast) do
    ast
    |> List.wrap
    |> Enum.map(&clean_node/1)
  end

  defp clean_node({atom, _meta, list}) when is_list(list) do
    {atom, [], Enum.map(list, &clean_node/1)}
  end
  defp clean_node([do: tuple]) when is_tuple(tuple) do
    [do: clean_node(tuple)]
  end
  defp clean_node([do: tuple, else: tuple2]) when is_tuple(tuple) do
    [do: clean_node(tuple), else: clean_node(tuple2)]
  end
  defp clean_node({:do, tuple}) when is_tuple(tuple) do
    {:do, clean_node(tuple)}
  end
  defp clean_node({:else, tuple}) when is_tuple(tuple) do
    {:else, clean_node(tuple)}
  end
  defp clean_node({atom, _meta, arguments}) do
    {atom, [], arguments}
  end
  defp clean_node(v) when is_list(v), do: Enum.map(v, &clean_node/1)
  defp clean_node(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list
    |> Enum.map(&clean_node/1)
    |> List.to_tuple
  end
  defp clean_node(v) when is_atom(v)
                      or is_binary(v)
                      or is_boolean(v)
                      or is_float(v)
                      or is_integer(v)
                      or is_nil(v), do: v

  @doc """
  Returns a hash-value for a given +ast+.
  """
  def to_hash(ast) do
    string =
      ast
      |> Inspect.Algebra.to_doc(%Inspect.Opts{})
      |> Inspect.Algebra.format(80)
      |> Enum.join("")

    :sha256
    |> :crypto.hash(string)
    |> Base.encode16
  end

  @doc """
  Returns the mass (count of instructions) for an AST.
  """
  def mass(ast) do
    Credo.Code.traverse(ast, &calc_mass/2, 0)
  end

  defp calc_mass(ast, acc) when is_tuple(ast) do
    {ast, acc+1}
  end
  defp calc_mass(ast, acc) do
    {ast, acc}
  end

  defp issue_for(issue_meta, this_node, other_nodes, nodes_threshold) do
    if Enum.count(other_nodes) >= nodes_threshold - 1 do
      filenames =
        other_nodes
        |> Enum.map(fn(other_node) -> "#{other_node.filename}:#{line_no_for(other_node.node)}" end)
        |> Enum.join(", ")
      mass = this_node.mass
      line_no = line_no_for(this_node.node)

      format_issue issue_meta,
        message: "Duplicate code found in #{filenames} (mass: #{mass}).",
        line_no: line_no,
        severity: Severity.compute(1+Enum.count(other_nodes), 1)
    end
  end


  # TODO: Put in AST helper

  alias Credo.Check.CodeHelper

  def line_no_for({atom, meta, _}) when is_atom(atom) do
    meta[:line]
  end
  def line_no_for(nil), do: nil
  def line_no_for(block) do
    block
    |> CodeHelper.do_block_for!
    |> line_no_for
  end
end
