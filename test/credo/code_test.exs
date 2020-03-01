defmodule Credo.CodeTest do
  use Credo.Test.Case

  test "it should NOT report expected code" do
    lines =
      """
      defmodule CredoSampleModule do
        def some_function(parameter1, parameter2) do
          some_value = parameter1 + parameter2
        end
      end
      """
      |> Credo.Code.to_lines()

    expected = [
      {1, "defmodule CredoSampleModule do"},
      {2, "  def some_function(parameter1, parameter2) do"},
      {3, "    some_value = parameter1 + parameter2"},
      {4, "  end"},
      {5, "end"},
      {6, ""}
    ]

    assert expected == lines
  end

  test "it should parse source" do
    {:ok, ast} =
      """
      defmodule CredoSampleModule do
        def some_function(parameter1, parameter2) do
          some_value = parameter1 + parameter2
        end
      end
      """
      |> Credo.Code.ast()

    refute is_nil(ast)
  end

  test "it issues a parser error when reading non-utf8 files" do
    # This is `"René"` encoded as ISO-8859-1, which causes a `UnicodeConversionError`.
    source_file = <<34, 82, 101, 110, 233, 34>>
    {:error, [error]} = Credo.Code.ast(source_file)
    %Credo.Issue{message: message, line_no: 1} = error

    assert "invalid encoding starting at <<233, 34>>" == message
  end

  test "it should return true" do
    parent = {
      {:., [line: 5],
       [
         {:__aliases__, [counter: 0, line: 5], [:String]},
         :split
       ]},
      [line: 5],
      [{:parameter1, [line: 5], nil}]
    }

    child = {:parameter1, [line: 5], nil}

    assert Credo.Code.contains_child?(parent, child)
  end

  test "it should return the function name" do
    ast =
      """
      defp foobar(v) do
        List.wrap(v)
        something
      end
      """
      |> Code.string_to_quoted!()

    assert :foobar == Credo.Code.Module.def_name(ast)

    ast =
      """
      defp foobar(v), do: List.wrap(v)
      """
      |> Code.string_to_quoted!()

    assert :foobar == Credo.Code.Module.def_name(ast)

    ast =
      """
      defp foobar(v) when is_atom(v) or is_nil(v), do: List.wrap(v)
      """
      |> Code.string_to_quoted!()

    assert :foobar == Credo.Code.Module.def_name(ast)
  end

  test "it should NOT report expected code /1" do
    source = """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + " this is a string" # WARNING: NÃO ESTÁ A FUNCIONAR
      end
    end
    """

    expected =
      "defmodule CredoSampleModule do\n  def some_function(parameter1, parameter2) do\n    parameter1 + \"                 \" \n  end\nend\n"

    assert expected == Credo.Code.clean_charlists_strings_sigils_and_comments(source)
  end

  test "it should NOT report expected code 4" do
    input = ~S"""
    defp escape_charlist(reversed_result, [?" | remainder], needs_quote?),
    do: escape_charlist('"\\' ++ reversed_result, remainder, needs_quote?)
    """

    expected = ~S"""
    defp escape_charlist(reversed_result, [?" | remainder], needs_quote?),
    do: escape_charlist('   ' ++ reversed_result, remainder, needs_quote?)
    """

    assert expected == Credo.Code.clean_charlists_strings_sigils_and_comments(input)
  end

  test "it should NOT report expected code 3" do
    source = """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + " this is a string"# tell the most browser´s to open
      end
    end
    """

    expected =
      "defmodule CredoSampleModule do\n  def some_function(parameter1, parameter2) do\n    parameter1 + \"                 \"\n  end\nend\n"

    assert expected == Credo.Code.clean_charlists_strings_sigils_and_comments(source)
  end

  test "it should NOT report expected code on clean_charlists_strings_and_sigils" do
    source = ~S"""
    defmodule Foo do
      def foo(a) do
        "#{a} #{a}"
      end

      def bar do
        " )"
      end
    end
    """

    expected = ~S"""
    defmodule Foo do
      def foo(a) do
        "         "
      end

      def bar do
        "  "
      end
    end
    """

    assert expected == Credo.Code.clean_charlists_strings_and_sigils(source)
  end

  test "it should NOT report expected code on clean_charlists_strings_sigils_and_comments" do
    source = ~S"""
    defmodule Foo do
      def foo(a) do
        "#{a} #{a}"
      end

      def bar do
        " )"
      end
    end
    """

    expected = ~S"""
    defmodule Foo do
      def foo(a) do
        "         "
      end

      def bar do
        "  "
      end
    end
    """

    assert expected == Credo.Code.clean_charlists_strings_sigils_and_comments(source)
  end

  test "it should NOT report expected code on clean_charlists_strings_sigils_and_comments /2" do
    source = """
    defmodule CredoSampleModule do
      def fun do
        # '
        ','
      end
    end
    """

    expected =
      """
      defmodule CredoSampleModule do
        def fun do
          *
          ' '
        end
      end
      """
      |> String.replace("*", "")

    assert expected == Credo.Code.clean_charlists_strings_sigils_and_comments(source)
  end

  test "it should NOT report expected code on clean_charlists_strings_and_sigils /2" do
    expected =
      """
      defmodule CredoSampleModule do
        def fun do
          # '
          ' '
        end
      end
      """
      |> String.replace("*", "")

    source_file =
      """
      defmodule CredoSampleModule do
        def fun do
          # '
          ','
        end
      end
      """
      |> to_source_file

    assert expected == Credo.Code.clean_charlists_strings_and_sigils(source_file)
  end

  @tag slow: :disk_io
  test "it should produce valid code" do
    example_code = File.read!("test/fixtures/example_code/clean.ex")
    result = Credo.Code.clean_charlists_strings_sigils_and_comments(example_code)
    result2 = Credo.Code.clean_charlists_strings_sigils_and_comments(result)

    assert result == result2, "clean_charlists_strings_sigils_and_comments/2 should be idempotent"
    assert match?({:ok, _}, Code.string_to_quoted(result))
  end

  @tag slow: :disk_io
  test "it should produce valid code /2" do
    example_code = File.read!("test/fixtures/example_code/nested_escaped_heredocs.ex")
    result = Credo.Code.clean_charlists_strings_sigils_and_comments(example_code)
    result2 = Credo.Code.clean_charlists_strings_sigils_and_comments(result)

    assert result == result2,
           "Credo.Code.clean_charlists_strings_sigils_and_comments/1 should be idempotent"

    assert match?({:ok, _}, Code.string_to_quoted(result)),
           "Credo.Code.clean_charlists_strings_sigils_and_comments/1 should produce valid code"
  end

  @tag slow: :disk_io
  test "it should produce valid code /3" do
    example_code = File.read!("test/fixtures/example_code/clean.ex")
    result = Credo.Code.clean_charlists_strings_and_sigils(example_code)
    result2 = Credo.Code.clean_charlists_strings_and_sigils(result)

    assert result == result2, "clean_charlists_strings_and_sigils/2 should be idempotent"
    assert match?({:ok, _}, Code.string_to_quoted(result))
  end

  @tag slow: :disk_io
  test "it should produce valid code /4" do
    example_code = File.read!("test/fixtures/example_code/nested_escaped_heredocs.ex")
    result = Credo.Code.clean_charlists_strings_and_sigils(example_code)
    result2 = Credo.Code.clean_charlists_strings_and_sigils(result)

    assert result == result2,
           "Credo.Code.clean_charlists_strings_and_sigils/1 should be idempotent"

    assert match?({:ok, _}, Code.string_to_quoted(result)),
           "Credo.Code.clean_charlists_strings_and_sigils/1 should produce valid code"
  end

  test "it should produce valid code /5" do
    source = ~S"""
    file_patt   = "*.{#{ Enum.join(file_exts, ",") }}"
    """

    expected = ~S"""
    file_patt   = "                                  "
    """

    result = Credo.Code.clean_charlists_strings_sigils_and_comments(source)
    result2 = Credo.Code.clean_charlists_strings_sigils_and_comments(result)

    assert result == expected
    assert result == result2, "clean_charlists_strings_sigils_and_comments/2 should be idempotent"
    assert match?({:ok, _}, Code.string_to_quoted(result))
  end

  test "it should produce valid code /6" do
    source = ~S"""
    file_patt   = "*.{#{ Enum.join(file_exts, ",") }}"
    """

    expected = ~S"""
    file_patt   = "                                  "
    """

    result = Credo.Code.clean_charlists_strings_and_sigils(source)
    result2 = Credo.Code.clean_charlists_strings_and_sigils(result)

    assert result == expected
    assert result == result2, "clean_charlists_strings_and_sigils/2 should be idempotent"
    assert match?({:ok, _}, Code.string_to_quoted(result))
  end

  test "returns ast without metadata" do
    ast =
      {:__block__, [],
       [
         {:defmodule, [line: 1],
          [
            {:__aliases__, [counter: 0, line: 1], [:M1]},
            [
              do:
                {:def, [line: 2],
                 [
                   {:when, [line: 2],
                    [
                      {:myfun, [line: 2],
                       [
                         {:p1, [line: 2], nil},
                         {:p2, [line: 2], nil}
                       ]},
                      {:is_list, [line: 2], [{:p2, [line: 2], nil}]}
                    ]},
                   [
                     do:
                       {:if, [line: 3],
                        [
                          {:==, [line: 3],
                           [
                             {:p1, [line: 3], nil},
                             {:p2, [line: 3], nil}
                           ]},
                          [
                            do: {:p1, [line: 4], nil},
                            else:
                              {:+, [line: 6],
                               [
                                 {:p2, [line: 6], nil},
                                 {:p1, [line: 6], nil}
                               ]}
                          ]
                        ]}
                   ]
                 ]}
            ]
          ]},
         {:defmodule, [line: 11],
          [
            {:__aliases__, [counter: 0, line: 11], [:M2]},
            [
              do:
                {:def, [line: 12],
                 [
                   {:myfun2, [line: 12],
                    [
                      {:p1, [line: 12], nil},
                      {:p2, [line: 12], nil}
                    ]},
                   [
                     do:
                       {:if, [line: 13],
                        [
                          {:==, [line: 13],
                           [
                             {:p1, [line: 13], nil},
                             {:p2, [line: 13], nil}
                           ]},
                          [
                            do: {:p1, [line: 14], nil},
                            else:
                              {:+, [line: 16],
                               [
                                 {:p2, [line: 16], nil},
                                 {:p1, [line: 16], nil}
                               ]}
                          ]
                        ]}
                   ]
                 ]}
            ]
          ]}
       ]}

    expected =
      {:__block__, [],
       [
         {:defmodule, [],
          [
            {:__aliases__, [], [:M1]},
            [
              do:
                {:def, [],
                 [
                   {:when, [],
                    [
                      {:myfun, [], [{:p1, [], nil}, {:p2, [], nil}]},
                      {:is_list, [], [{:p2, [], nil}]}
                    ]},
                   [
                     do:
                       {:if, [],
                        [
                          {:==, [], [{:p1, [], nil}, {:p2, [], nil}]},
                          [
                            do: {:p1, [], nil},
                            else: {:+, [], [{:p2, [], nil}, {:p1, [], nil}]}
                          ]
                        ]}
                   ]
                 ]}
            ]
          ]},
         {:defmodule, [],
          [
            {:__aliases__, [], [:M2]},
            [
              do:
                {:def, [],
                 [
                   {:myfun2, [], [{:p1, [], nil}, {:p2, [], nil}]},
                   [
                     do:
                       {:if, [],
                        [
                          {:==, [], [{:p1, [], nil}, {:p2, [], nil}]},
                          [
                            do: {:p1, [], nil},
                            else: {:+, [], [{:p2, [], nil}, {:p1, [], nil}]}
                          ]
                        ]}
                   ]
                 ]}
            ]
          ]}
       ]}

    assert expected == Credo.Code.remove_metadata(ast)
  end

  test "returns ast with external call without metadata" do
    ast =
      {{:., [line: 1, column: 7],
        [
          {:__aliases__, [line: 1, column: 1], [:Kernel]},
          :node
        ]}, [line: 1, column: 7], []}

    expected =
      {{:., [],
        [
          {:__aliases__, [], [:Kernel]},
          :node
        ]}, [], []}

    assert expected == Credo.Code.remove_metadata(ast)
  end
end
