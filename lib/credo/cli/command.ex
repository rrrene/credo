defmodule Credo.CLI.Command do
  @moduledoc """
  `Command` is used to describe commands which can be executed from the command line.

  The default command is `Credo.CLI.Command.Suggest.SuggestCommand`.

  A basic command that writes "Hello World" can be implemented like this:

      defmodule HelloWorldCommand do
        use Credo.CLI.Command

        alias Credo.CLI.Output.UI

        def call(_exec, _opts) do
          UI.puts([:yellow, "Hello ", :orange, "World"])
        end
      end

  """

  @typedoc false
  @type t :: module

  @doc """
  Is called when a Command is invoked.

      defmodule FooTask do
        use Credo.Execution.Task

        def call(exec) do
          IO.inspect(exec)
        end
      end

  The `call/1` functions receives an `exec` struct and must return a (modified) `Credo.Execution`.
  """
  @callback call(exec :: Credo.Execution.t()) :: Credo.Execution.t()

  @doc """
  Is called when a Command is initialized.

  The `init/1` functions receives an `exec` struct and must return a (modified) `Credo.Execution`.

  This can be used to initialize Execution pipelines for the current Command:

      defmodule FooTask do
        use Credo.Execution.Task

        def init(exec) do
          Execution.put_pipeline(exec, __MODULE__,
            run_my_thing: [
              {RunMySpecialThing, []}
            ],
            filter_results: [
              {FilterResults, []}
            ],
            print_results: [
              {PrintResultsAndSummary, []}
            ]
          )
        end
      end
  """
  @callback init(exec :: Credo.Execution.t()) :: Credo.Execution.t()

  @valid_use_opts [
    :short_description,
    :cli_switches
  ]

  @doc false
  defmacro __using__(opts \\ []) do
    Enum.each(opts, fn
      {key, _name} when key not in @valid_use_opts ->
        raise "Could not find key `#{key}` in #{inspect(@valid_use_opts)}"

      _ ->
        nil
    end)

    def_short_description =
      if opts[:short_description] do
        quote do
          @impl true
          def short_description, do: unquote(opts[:short_description])
        end
      end

    def_cli_switches =
      quote do
        @impl true
        def cli_switches do
          unquote(opts[:cli_switches])
          |> List.wrap()
          |> Enum.map(&Credo.CLI.Switch.ensure/1)
        end
      end

    quote do
      @before_compile Credo.CLI.Command
      @behaviour Credo.CLI.Command

      unquote(def_short_description)
      unquote(def_cli_switches)

      @deprecated "Use Credo.Execution.Task.run/2 instead"
      defp run_task(exec, task), do: Credo.Execution.Task.run(task, exec)

      @doc false
      @impl true
      def init(exec), do: exec

      @doc false
      @impl true
      def call(exec), do: exec

      defoverridable init: 1
      defoverridable call: 1
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    quote do
      unquote(deprecated_def_short_description(env))
    end
  end

  defp deprecated_def_short_description(env) do
    shortdoc = Module.get_attribute(env.module, :shortdoc)

    if is_nil(shortdoc) do
      if not Module.defines?(env.module, {:short_description, 0}) do
        quote do
          @impl true
          def short_description, do: nil
        end
      end
    else
      # deprecated - remove once we ditch @shortdoc
      if not Module.defines?(env.module, {:short_description, 0}) do
        quote do
          @impl true
          def short_description do
            @shortdoc
          end
        end
      end
    end
  end

  @doc "Runs the Command"
  @callback call(exec :: Credo.Execution.t(), opts :: list()) :: Credo.Execution.t()

  @doc "Returns a short, one-line description of what the command does"
  @callback short_description() :: String.t()

  @callback cli_switches() :: [Map.t()]
end
