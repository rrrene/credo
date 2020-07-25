defmodule Credo.Check.Design.DuplicatedCode do
  use Credo.Check,
    run_on_all: true,
    base_priority: :higher,
    tags: [:controversial],
    param_defaults: [
      mass_threshold: 40,
      nodes_threshold: 2,
      excluded_macros: []
    ],
    explanations: [
      check: """
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
      """,
      params: [
        mass_threshold:
          "The minimum mass which a part of code has to have to qualify for this check.",
        nodes_threshold: "The number of nodes that need to be found to raise an issue.",
        excluded_macros: "List of macros to be excluded for this check."
      ]
    ]

  alias Credo.SourceFile

  @doc false
  @impl true
  def run_on_all_source_files(exec, source_files, params) do
    mass_threshold = Params.get(params, :mass_threshold, __MODULE__)
    nodes_threshold = Params.get(params, :nodes_threshold, __MODULE__)

    source_files
    |> duplicate_nodes(mass_threshold)
    |> append_issues_via_issue_service(source_files, nodes_threshold, params, exec)

    :ok
  end

  defp append_issues_via_issue_service(found_hashes, source_files, nodes_threshold, params, exec)
       when is_map(found_hashes) do
    found_hashes
    |> Enum.map(
      &Task.async(fn ->
        do_append_issues_via_issue_service(
          &1,
          source_files,
          nodes_threshold,
          params,
          exec
        )
      end)
    )
    |> Enum.map(&Task.await(&1, :infinity))
  end

  defp do_append_issues_via_issue_service(
         {_hash, nodes},
         source_files,
         nodes_threshold,
         params,
         exec
       ) do
    filename_map = nodes |> Enum.map(&{&1.filename, true}) |> Enum.into(%{})

    source_files
    |> Enum.filter(fn source_file -> filename_map[source_file.filename] end)
    |> Enum.each(&new_issue_for_members(&1, nodes_threshold, nodes, params, exec))
  end

  defp new_issue_for_members(source_file, nodes_threshold, nodes, params, exec) do
    this_node = Enum.find(nodes, &(&1.filename == source_file.filename))
    other_nodes = List.delete(nodes, this_node)
    issue_meta = IssueMeta.for(source_file, params)
    issue = issue_for(issue_meta, this_node, other_nodes, nodes_threshold, params)

    if issue do
      Credo.Execution.ExecutionIssues.append(exec, source_file, issue)
    end
  end

  defp duplicate_nodes(source_files, mass_threshold) do
    chunked_nodes =
      source_files
      |> Enum.chunk_every(30)
      |> Enum.map(&Task.async(fn -> calculate_hashes_for_chunk(&1, mass_threshold) end))
      |> Enum.map(&Task.await(&1, :infinity))

    nodes =
      Enum.reduce(chunked_nodes, %{}, fn current_hashes, existing_hashes ->
        Map.merge(existing_hashes, current_hashes, fn _hash, node_items1, node_items2 ->
          node_items1 ++ node_items2
        end)
      end)

    nodes
    |> prune_hashes
    |> add_masses
  end

  defp calculate_hashes_for_chunk(source_files, mass_threshold) do
    Enum.reduce(source_files, %{}, fn source_file, acc ->
      ast = SourceFile.ast(source_file)

      calculate_hashes(ast, acc, source_file.filename, mass_threshold)
    end)
  end

  def add_masses(found_hashes) do
    Enum.into(found_hashes, %{}, &add_mass_to_subnode/1)
  end

  defp add_mass_to_subnode({hash, node_items}) do
    node_items =
      Enum.map(node_items, fn node_item ->
        %{node_item | mass: mass(node_item.node)}
      end)

    {hash, node_items}
  end

  @doc """
  Takes a map of hashes to nodes and prunes those nodes that are just
  subnodes of others in the same set.

  Returns the resulting map.
  """
  def prune_hashes(
        given_hashes,
        mass_threshold \\ param_defaults()[:mass_threshold]
      ) do
    # remove entries containing a single node
    hashes_with_multiple_nodes =
      given_hashes
      |> Enum.filter(fn {_hash, node_items} -> Enum.count(node_items) > 1 end)
      |> Enum.into(%{})

    hashes_to_prune =
      Enum.flat_map(
        hashes_with_multiple_nodes,
        &collect_subhashes(&1, mass_threshold)
      )

    delete_keys(hashes_to_prune, hashes_with_multiple_nodes)
  end

  defp delete_keys([], acc), do: acc

  defp delete_keys([head | tail], acc) do
    delete_keys(tail, Map.delete(acc, head))
  end

  defp collect_subhashes({_hash, node_items}, mass_threshold) do
    %{node: first_node, filename: filename} = Enum.at(node_items, 0)

    my_hash = first_node |> Credo.Code.remove_metadata() |> to_hash
    # don't count self
    subhashes =
      first_node
      |> calculate_hashes(%{}, filename, mass_threshold)
      |> Map.keys()
      |> List.delete(my_hash)

    subhashes
  end

  @doc """
  Calculates hash values for all sub nodes in a given +ast+.

  Returns a map with the hashes as keys and the nodes as values.
  """
  def calculate_hashes(
        ast,
        existing_hashes \\ %{},
        filename \\ "foo.ex",
        mass_threshold \\ param_defaults()[:mass_threshold]
      )
      when is_map(existing_hashes) do
    Credo.Code.prewalk(
      ast,
      &collect_hashes(&1, &2, filename, mass_threshold),
      existing_hashes
    )
  end

  defp collect_hashes(ast, existing_hashes, filename, mass_threshold) do
    if mass(ast) < mass_threshold do
      {ast, existing_hashes}
    else
      hash = ast |> Credo.Code.remove_metadata() |> to_hash
      node_item = %{node: ast, filename: filename, mass: nil}
      node_items = Map.get(existing_hashes, hash, [])

      updated_hashes = Map.put(existing_hashes, hash, node_items ++ [node_item])

      {ast, updated_hashes}
    end
  end

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
    |> Base.encode16()
  end

  @doc """
  Returns the mass (count of instructions) for an AST.
  """
  def mass(ast) do
    Credo.Code.prewalk(ast, &calc_mass/2, 0)
  end

  defp calc_mass(ast, acc) when is_tuple(ast) do
    {ast, acc + 1}
  end

  defp calc_mass(ast, acc) do
    {ast, acc}
  end

  defp issue_for(issue_meta, this_node, other_nodes, nodes_threshold, params) do
    if Enum.count(other_nodes) >= nodes_threshold - 1 do
      filenames =
        other_nodes
        |> Enum.map(fn other_node ->
          "#{other_node.filename}:#{line_no_for(other_node.node)}"
        end)
        |> Enum.join(", ")

      node_mass = this_node.mass
      line_no = line_no_for(this_node.node)
      excluded_macros = params[:excluded_macros] || []

      if create_issue?(this_node.node, excluded_macros) do
        format_issue(
          issue_meta,
          message: "Duplicate code found in #{filenames} (mass: #{node_mass}).",
          line_no: line_no,
          severity: Severity.compute(1 + Enum.count(other_nodes), 1)
        )
      end
    end
  end

  # ignore similar module attributes, no matter how complex
  def create_issue?({:@, _, _}, _), do: false

  def create_issue?([do: {atom, _, arguments}], excluded_macros)
      when is_atom(atom) and is_list(arguments) do
    !Enum.member?(excluded_macros, atom)
  end

  def create_issue?({atom, _, arguments}, excluded_macros)
      when is_atom(atom) and is_list(arguments) do
    !Enum.member?(excluded_macros, atom)
  end

  def create_issue?(_ast, _), do: true

  # TODO: Put in AST helper

  def line_no_for({:__block__, _meta, arguments}) do
    line_no_for(arguments)
  end

  def line_no_for({:do, arguments}) do
    line_no_for(arguments)
  end

  def line_no_for({atom, meta, _}) when is_atom(atom) do
    meta[:line]
  end

  def line_no_for(list) when is_list(list) do
    Enum.find_value(list, &line_no_for/1)
  end

  def line_no_for(nil), do: nil

  def line_no_for(block) do
    block
    |> Credo.Code.Block.do_block_for!()
    |> line_no_for
  end
end
