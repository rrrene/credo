defmodule Credo.Check.Refactor.VariableRebindingTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.VariableRebinding

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        a = 1
        b = 2
        seq = 1

        %{seq: ^seq} = %{seq: 1}
      end

      def recode(data = %struct{}, from, to) when is_binary(from) and is_binary(to) do
        from_size = byte_size(from)

        # `from` is pinned, `from_size` is used as a parameter
        <<^from::binary-size(from_size), subname::binary>> = something

        # `from_size` is used as a parameter
        <<other::binary-size(from_size), subname2::binary>> = something

        # `subname` is pinned
        <<from::binary-size(xxx), ^subname::binary>> = something
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "rebinding opt-in bang sigils is allowed" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        a! = 1
        a! = 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, allow_bang: true)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        a = 1
        a = 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report two violations" do
    """
    defmodule CredoSampleModule do
      def some_function() do
        var_1 = 1 + 3
        var_b = var_1 + 7
        var_1 = 34
        var_c = 2456
        var_b = 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(&(length(&1) == 2))
  end

  test "it should report violations when using destructuring tuples" do
    """
    defmodule CredoSampleModule do
      def some_function() do
        something = "ABABAB"
        {:ok, something} = Base.decode16(something)
        {a, a} = {2, 2} # this should _not_ trigger it
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report violations when using destructuring with nested assignments" do
    """
    defmodule CredoSampleModule do
      def some_function() do
        {a = b, a = b} = {1, 2}
        b = 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report violations when using destructuring lists" do
    """
    defmodule CredoSampleModule do
      def some_function() do
        [a, b] = [1, 2]
        b = 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report violations when using destructuring maps" do
    """
    defmodule CredoSampleModule do
      def some_function(opts) do
        %{a: foo, b: bar} = opts
        bar = 3
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "rebinding bang sigils is forbidden without the :allow_bang option" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        a! = 1
        a! = 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
