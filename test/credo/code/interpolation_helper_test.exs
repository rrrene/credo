defmodule Credo.Code.InterpolationHelperTest do
  use Credo.TestHelper

  alias Credo.Code.InterpolationHelper

  @heredoc_interpolations_source ~S'''
  def fun() do
    a = """
    MyModule.#{fun(Module.value() + 1)}.SubModule.#{name}"
    MyModule.SubModule.#{name}(1 + 3)
    """
  end
  '''
  @heredoc_interpolations_positions [
    {3, 12, 3, 38},
    {3, 49, 3, 56},
    {4, 22, 4, 29}
  ]

  @multiple_interpolations_source ~S[a = "MyModule.#{fun(Module.value() + 1)}.SubModule.#{name}"]
  @multiple_interpolations_positions [{1, 15, 1, 41}, {1, 52, 1, 59}]

  @single_interpolations_source ~S[a = "MyModule.SubModule.#{name}"]
  @single_interpolations_positions [{1, 25, 1, 32}]

  @no_interpolations_source ~S[134 + 145]
  @no_interpolations_positions []

  test "should replace string interpolations with given character" do
    source = ~S"""
    def fun() do
      a = "MyModule.#{fun(Module.value() + 1)}.SubModule.#{name}"
    end
    """

    expected = ~S"""
    def fun() do
      a = "MyModule.$$$$$$$$$$$$$$$$$$$$$$$$$$.SubModule.$$$$$$$"
    end
    """

    assert expected == InterpolationHelper.replace_interpolations(source, "$")
  end

  test "should replace string interpolations with given character /3" do
    source = ~S"""
    case category_count(issues, category) do
      0 -> []
      1 -> [color, "1 #{singular}, "]
      x -> [color, "#{x} #{ x } #{x} #{plural}, "]
    end
    """

    expected = ~S"""
    case category_count(issues, category) do
      0 -> []
      1 -> [color, "1 $$$$$$$$$$$, "]
      x -> [color, "$$$$ $$$$$$ $$$$ $$$$$$$$$, "]
    end
    """

    assert expected == InterpolationHelper.replace_interpolations(source, "$")
  end

  test "should replace sigil interpolations with given character" do
    source = ~S"""
    def fun() do
      a = ~s" MyModule.#{fun(Module.value() + 1)}.SubModule.#{name} "
    end
    """

    expected = ~S"""
    def fun() do
      a = ~s" MyModule.$$$$$$$$$$$$$$$$$$$$$$$$$$.SubModule.$$$$$$$ "
    end
    """

    assert expected == InterpolationHelper.replace_interpolations(source, "$")
  end

  test "should replace sigil interpolations with given character /2" do
    source = ~S"""
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        values = ~s{ #{"}"} }
      end
    end
    """

    expected = ~S"""
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        values = ~s{ $$$$$$ }
      end
    end
    """

    assert expected == InterpolationHelper.replace_interpolations(source, "$")
  end

  test "should replace heredoc interpolations with given character" do
    source = ~S'''
    def fun() do
      a = """
      MyModule.#{fun(Module.value() + 1)}.SubModule.#{name}"
      MyModule.SubModule.#{name}(1 + 3)
      """
    end
    '''

    expected = """
    def fun() do
      a = \"\"\"
      MyModule.$$$$$$$$$$$$$$$$$$$$$$$$$$.SubModule.$$$$$$$"
      MyModule.SubModule.$$$$$$$(1 + 3)
      \"\"\"
    end
    """

    assert expected == InterpolationHelper.replace_interpolations(source, "$")
  end

  @tag :token_position
  test "should give correct token position" do
    positions =
      InterpolationHelper.interpolation_positions(@no_interpolations_source)

    assert @no_interpolations_positions == positions
  end

  @tag :token_position
  test "should give correct token position with a single interpolation" do
    positions =
      InterpolationHelper.interpolation_positions(@single_interpolations_source)

    assert @single_interpolations_positions == positions
  end

  @tag :token_position
  test "should give correct token position with a single interpolation /2" do
    source = ~S[a = ~s{ #{"a" <> fun() <>  "b" } }]
    positions = InterpolationHelper.interpolation_positions(source)

    assert [{1, 9, 1, 33}] == positions
  end

  @tag :token_position
  test "should give correct token position with a single interpolation /3" do
    source = ~S"""
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        values = ~s{ #{ "}" } }
      end
    end
    """

    positions = InterpolationHelper.interpolation_positions(source)

    assert [{3, 18, 3, 26}] == positions
  end

  @tag :token_position
  test "should give correct token position with a single interpolation /4" do
    source = ~S"""
    case category_count(issues, category) do
      0 -> []
      1 -> [color, "1 #{singular}, "]
      x -> [color, "#{x} #{plural}, "]
    end
    """

    positions = InterpolationHelper.interpolation_positions(source)

    assert [{3, 19, 3, 30}, {4, 17, 4, 21}, {4, 22, 4, 31}] == positions
  end

  @tag :token_position
  test "should give correct token position with multiple interpolations" do
    positions =
      InterpolationHelper.interpolation_positions(
        @multiple_interpolations_source
      )

    assert @multiple_interpolations_positions == positions
  end

  @tag :token_position
  test "should give correct token position with multiple interpolations in heredoc" do
    positions =
      InterpolationHelper.interpolation_positions(
        @heredoc_interpolations_source
      )

    assert @heredoc_interpolations_positions == positions
  end

  @tag :token_position
  @tag :to_be_implemented
  test "should replace a single interpolation stretching multiple lines" do
    source = ~S"""
    "Use unquoted atom `#{inspect(atom)}` rather than quoted atom `#{
      trigger
    }`."
    """

    expected = ~S"""
    "Use unquoted atom `$$$$$$$$$$$$$$$$` rather than quoted atom `$$
    $$$$$$$$$
    $`."
    """

    assert expected == InterpolationHelper.replace_interpolations(source, "$")
  end

  @tag :token_position
  @tag :to_be_implemented
  test "should give correct token position with a single interpolation stretching multiple lines" do
    source = ~S"""
    "Use unquoted atom rather than quoted atom `#{
      trigger
    }`."
    """

    positions = InterpolationHelper.interpolation_positions(source)

    assert [] == positions
  end
end
