defmodule Credo.Check.Readability.RedundantBlankLinesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.RedundantBlankLines

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule ModuleWithoutRedundantBlankLines do
      def a do
        1
      end

      def b do
        foo = "
        a


        b
        "

        2
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report heredocs" do
    ~S'''
    defmodule ModuleWithoutRedundantBlankLines do
      def a do
        """
        This is a heredoc (multi-line string)


        ---




        White Space seems intentional here.
        """
      end

      def b do
        2
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when file doesn't have empty lines" do
    "defmodule ModuleWithoutEmptyLines do
  def foo do
    :bar
  end
end"
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    ~S'''
    defmodule ModuleWithRedundantBlankLines do
      def a do
        1
      end


      def b do
        1
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 6, trigger: Credo.Issue.no_trigger()})
  end

  test "it should report based on  max_blank_lines param" do
    file =
      ~S'''
      defmodule ModuleWithManyBlankLines do
        def a do
          1
        end




        def b do
          1
        end
      end
      '''
      |> to_source_file

    file
    |> run_check(@described_check, max_blank_lines: 4)
    |> refute_issues()

    file
    |> run_check(@described_check, max_blank_lines: 3)
    |> assert_issue()
  end
end
