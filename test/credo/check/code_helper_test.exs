defmodule Credo.Check.CodeHelperTest do
  use Credo.TestHelper

  alias Credo.Check.CodeHelper

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

    assert CodeHelper.contains_child?(parent, child)
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

    assert :foobar == CodeHelper.def_name(ast)

    ast =
      """
      defp foobar(v), do: List.wrap(v)
      """
      |> Code.string_to_quoted!()

    assert :foobar == CodeHelper.def_name(ast)

    ast =
      """
      defp foobar(v) when is_atom(v) or is_nil(v), do: List.wrap(v)
      """
      |> Code.string_to_quoted!()

    assert :foobar == CodeHelper.def_name(ast)
  end

  test "it should NOT report expected code" do
    expected =
      "defmodule CredoSampleModule do\n  def some_function(parameter1, parameter2) do\n    parameter1 + \"                 \" \n  end\nend\n"

    source_file =
      """
      defmodule CredoSampleModule do
        def some_function(parameter1, parameter2) do
          parameter1 + " this is a string" # WARNING: NÃO ESTÁ A FUNCIONAR
        end
      end
      """
      |> to_source_file

    assert expected ==
             source_file
             |> CodeHelper.clean_charlists_strings_sigils_and_comments()
  end

  test "it should NOT report expected code 2" do
    expected =
      "defmodule CredoSampleModule do\n  def some_function(parameter1, parameter2) do\n    parameter1 + \"                 \"\n  end\nend\n"

    source_file =
      """
      defmodule CredoSampleModule do
        def some_function(parameter1, parameter2) do
          parameter1 + " this is a string"# tell the most browser´s to open
        end
      end
      """
      |> to_source_file

    assert expected ==
             source_file
             |> CodeHelper.clean_charlists_strings_sigils_and_comments()
  end

  test "it should NOT report expected code on clean_charlists_strings_sigils_and_comments" do
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

    assert expected ==
             CodeHelper.clean_charlists_strings_sigils_and_comments(source_file)
  end

  test "it should NOT report expected code on clean_charlists_strings_and_sigils" do
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

    assert expected ==
             CodeHelper.clean_charlists_strings_and_sigils(source_file)
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

    assert expected == CodeHelper.remove_metadata(ast)
  end
end
