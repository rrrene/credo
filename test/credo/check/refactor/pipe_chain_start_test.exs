defmodule Credo.Check.Refactor.PipeChainStartTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.PipeChainStart

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S"""
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        "Fahrenheit 451" |> String.to_charlist |> IO.inspect

        "Fahrenheit 451" |> String.trim

        do_something() |> then_something_else() |> and_last_step()

        ':#{token}'
        |> :elixir_tokenizer.tokenize(1, [])

        something
        |> String.downcase
        |> String.trim

        :something
        |> is_atom
        |> &(&1)

        -1
        |> Kernel.+(1)
        |> Kernel.*(0)

        FooBar
        |> to_string

        map[:something]
        |> is_atom
        |> IO.inspect

        1..100
        |> IO.inspect

        ?@..@some_value
        |> IO.inspect


        bar = [3, 2, 1]
        |> tl
        |> Enum.join

        map.key
        |> Enum.map(&String.upcase/1)
        |> Enum.join

        %Bar{}
        |> something()
        |> IO.inspect

        %{} |> something()

        %{"foo" => :bar}
        |> something()
        |> IO.inspect

        %{foo: :bar}
        |> something()
        |> IO.inspect

        {}
        |> Module.something()

        {:ok, foobar, 42}
        |> Module.something()
        |> something_else

        ~r/\d+\s\z/
        |> Regex.run(string)

        ~w(foo bar baz)a
        |> Enum.map(&to_string/1)
        |> Enum.join

        ~s(qick brown fox)
        |> String.upcase
        |> IO.inspect

        @something
        |> Enum.map(&String.upcase/1)
        |> Enum.join

        @something
        |> Enum.map(&String.upcase/1)
        |> Enum.join

        "A #{baked_good}" |> String.upcase |> IO.inspect

        << thing::utf8 >> |> String.upcase |> IO.inspect

        quote do
          unquote(foo)
          |> bar
        end

        block =
          (options[:do] || contents[:do])
          |> prewalk_block(name)
          |> handler_builder(type)

        for i <- 1..4 do
          i
        end
        |> Enum.map(fn(i) -> i + 2 end)

        (i <- 1..4)
        |> for do
          i
        end
        |> Enum.map(fn(i) -> i + 2 end)

        fn a -> x end
        |> IO.inspect

        (&(Enum.map(&1, &2)))
        |> IO.inspect

        (&Math.square/1)
        |> IO.inspect
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /2" do
    ~S"""
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        jobs = Stream.repeatedly(fn ->
                 {:ok, job_created_by_pid} = Client.Job.create_dag(interpreter_connection_created_by_pid, context)
                 {:ok, %{^job_client_pid => job}} = Client.Job.with_job_assignment_state(
                   job_created_by_pid,
                   context,
                   %{},
                   "invited"
                 )

                 job
               end)
               |> Enum.take(2)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check,
      excluded_functions: ["Stream.repeatedly"]
    )
    |> refute_issues
  end

  test "it should NOT report a violation for an excluded function call" do
    """
    String.trim("users") |> String.upcase
    """
    |> to_source_file
    |> run_check(
      @described_check,
      excluded_functions: ~w(String.trim table put_in)
    )
    |> refute_issues
  end

  test "it should NOT report a violation for an excluded function call /2" do
    """
    table("users")
    |> insert(%{name: "Bob Jones"})
    |> DB.run
    """
    |> to_source_file
    |> run_check(
      @described_check,
      excluded_functions: ~w(String.trim table put_in)
    )
    |> refute_issues
  end

  test "it should NOT report a violation for an excluded function call /3" do
    """
    put_in(users["john"][:age], 28)
    |> some_other_fun()
    """
    |> to_source_file
    |> run_check(
      @described_check,
      excluded_functions: ~w(String.trim table put_in)
    )
    |> refute_issues
  end

  test "it should NOT report a violation for an excluded function call /4" do
    """
    :crypto.hash(:md5, "test") |> Base.encode16(case: :lower)
    """
    |> to_source_file
    |> run_check(@described_check, excluded_functions: ~w(:crypto.hash))
    |> refute_issues()
  end

  test "it should NOT report a violation for ++" do
    """
      def build(%Ecto.Query{} = query) do
        document_pred(query)
        ++ wheres_preds(query)
        |> Enum.map(&wrap/1)
        |> Enum.join("")
        |> wrap()
      end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for --" do
    """
      def test do
        [1,2,3]
        -- [2]
        |> Enum.max
      end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for string concatenation" do
    """
    defmodule Test do
      def test do
        "hello"
        <> "world"
        |> String.captialize
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for captures" do
    """
    defmodule Test do
      def test do
        foo = %{bar: %{}}
        update_in foo.bar, &(
          &1
          |> Map.put(:a, :b))
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for an excluded argument type" do
    """
    table(~r/regex/)
    |> DB.run
    """
    |> to_source_file
    |> run_check(@described_check, excluded_argument_types: [:regex])
    |> refute_issues()
  end

  test "it should NOT report a violation for an excluded argument type /2" do
    """
    table(~R/regex/)
    |> DB.run
    """
    |> to_source_file
    |> run_check(@described_check, excluded_argument_types: [:sigil_R])
    |> refute_issues()
  end

  test "it should NOT report a violation for an excluded argument type /3" do
    """
    Namespace.Module.table2("users", %{name: "Bob Jones"}, {123}, true, ~r/regex/)
    |> DB.run
    """
    |> to_source_file
    |> run_check(@described_check, excluded_argument_types: [:binary])
    |> refute_issues()
  end

  test "it should NOT report a violation for an excluded argument type /4" do
    """
    table(~f(special sigil))
    |> DB.run
    """
    |> to_source_file
    |> run_check(@described_check, excluded_argument_types: [:sigil_f])
    |> refute_issues()
  end

  test "it should NOT report a violation for an excluded argument type /5" do
    """
    table(fn -> :stuff end)
    |> DB.run
    """
    |> to_source_file
    |> run_check(@described_check, excluded_argument_types: [:fn])
    |> refute_issues()
  end

  test "it should NOT report a violation for an excluded argument type /6" do
    """
    max(0, interval - elapsed_time) |> schedule_events()
    """
    |> to_source_file
    |> run_check(@described_check, excluded_argument_types: [:number])
    |> refute_issues()
  end

  test "it should NOT report a violation for an excluded argument type /7" do
    """
    insert(:event) |> schedule_events()
    """
    |> to_source_file
    |> run_check(@described_check, excluded_argument_types: [:atom])
    |> refute_issues()
  end

  test "it should NOT report a violation for an excluded argument type /8" do
    """
    foo(nil) |> bar()
    """
    |> to_source_file
    |> run_check(@described_check, excluded_argument_types: [:atom])
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation for a function call" do
    """
    String.trim("nope") |> String.upcase
    String.trim("nope")
    |> String.downcase
    |> String.trim
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report a violation for a function call 2" do
    """
    fun([a, b, c])
    |> something1
    |> something2
    |> something3
    |> IO.inspect
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for a function call 3" do
    """
    fun.([a, b, c]) |> IO.inspect
    fun.([a, b, c]) |> Enum.join |> IO.inspect
    fun.([a, b, c])
    |> Enum.join
    |> IO.inspect
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end
end
