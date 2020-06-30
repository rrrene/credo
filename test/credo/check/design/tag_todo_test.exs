defmodule Credo.Check.Design.TagTODOTest do
  use Credo.Test.Case

  @described_check Credo.Check.Design.TagTODO

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      # Attempts to soft delete a todo that
      # belongs to a user with the given user_id.
      #
      # Returns `{:ok, todo_id}` on success.
      def some_fun do
        assert x == x + 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected @doc values" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      @doc \"\"\"
      Attempts to soft delete a todo that
      belongs to a user with the given user_id.

      Returns `{:ok, todo_id}` on success.
      \"\"\"
      def some_fun do
        assert x == x + 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a couple of issues" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case
      @moduledoc \"\"\"
        this is an example # TODO: and this is an actual TODO
      \"\"\"

      def some_fun do
        x = ~s{also: # TODO: no comment here}
        assert 2 == x
        ?"

        "also: # TODO: no comment here as well"
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report an issue" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case # FIXME: this should not appear in the TODO test

      # TODO: this should not appear in the # TODO test

      def some_fun do
        assert x == x + 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report an issue for @doc tags" do
    """
    defmodule CredoSampleModule do
      @moduledoc \"\"\"
      FIXME: this should not appear in the test
      \"\"\"

      @doc "TODO: this should yield an issue"

      def some_fun do
        assert x == x + 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report an issue for @moduledoc tags" do
    """
    defmodule CredoSampleModule do
      @moduledoc \"\"\"
      TODO: this should not appear in the TODO test
      \"\"\"

      @doc "FIXME: this should yield an issue"

      def some_fun do
        assert x == x + 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report an issue for @shortdoc tags" do
    """
    defmodule CredoSampleModule do
      @shortdoc \"\"\"
      TODO: this should not appear in the TODO test
      \"\"\"

      @doc "FIXME: this should yield an issue"

      def some_fun do
        assert x == x + 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report an issue when not indented" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case # FIXME: this should not appear in the TODO test

    # TODO: this should appear

      def some_fun do
        assert x == x + 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report an issue when no spaces" do
    """
    defmodule CredoSampleModule do
      #TODO: this should appear
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report an issue with more spaces after #" do
    """
    defmodule CredoSampleModule do
      #       TODO: this should appear
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report an issue with more spaces after tag" do
    """
    defmodule CredoSampleModule do
      # TODO:         this should appear
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report an issue at the end of a line w/o space" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        Repo.preload(:comments)# TODO blah blah
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report an issue when lower case" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        # todo blah blah
        Repo.preload(:comments)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a couple of issues" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case # TODO: this is the first
      @moduledoc \"\"\"
        this is an example # TODO: and this is an actual TODO
      \"\"\"

      def some_fun do # TODO this is the second
        x = ~s{also: # TODO: no comment here}
        assert 2 == x
        ?" # TODO: this is the third

        "also: # TODO: no comment here as well"
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert 3 == Enum.count(issues)
    end)
  end
end
