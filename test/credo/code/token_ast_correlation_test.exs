defmodule Credo.Code.TokenAstCorrelationTest do
  use Credo.Test.Case

  @source_example1 """
  defmodule Credo.Sample do
    @test_attribute :foo

    def foobar(parameter) do
      String.split(parameter) + parameter
    end

    defmodule InlineModule do
      def foobar(v) when is_atom(v) do
        {:ok} = File.read
      end
    end
  end
  """

  @source_example2 """
  defmodule Credo.Sample do
    defmodule InlineModule do
      def foobar(x) do
        x = f(g(h(a), b), k(i(c-1) + j(d-2)) * l(e))
      end
    end
  end
  """

  # Elixir >= 1.10.0
  if Version.match?(System.version(), ">= 1.10.0") do
    test "should give correct ast for source_example1" do
      source = @source_example1
      {:ok, ast} = Credo.Code.ast(source)

      expected = {
        :defmodule,
        [line: 1, column: 1],
        [
          {
            :__aliases__,
            [line: 1, column: 11],
            [:Credo, :Sample]
          },
          [
            do: {
              :__block__,
              '',
              [
                {
                  :@,
                  [line: 2, column: 3],
                  [
                    {
                      :test_attribute,
                      [line: 2, column: 4],
                      [:foo]
                    }
                  ]
                },
                {
                  :def,
                  [line: 4, column: 3],
                  [
                    {
                      :foobar,
                      [line: 4, column: 7],
                      [
                        {
                          :parameter,
                          [line: 4, column: 14],
                          nil
                        }
                      ]
                    },
                    [
                      do: {
                        :+,
                        [line: 5, column: 29],
                        [
                          {
                            {
                              :.,
                              [line: 5, column: 11],
                              [
                                {
                                  :__aliases__,
                                  [line: 5, column: 5],
                                  [:String]
                                },
                                :split
                              ]
                            },
                            [line: 5, column: 11],
                            [
                              {
                                :parameter,
                                [line: 5, column: 18],
                                nil
                              }
                            ]
                          },
                          {
                            :parameter,
                            [line: 5, column: 31],
                            nil
                          }
                        ]
                      }
                    ]
                  ]
                },
                {
                  :defmodule,
                  [line: 8, column: 3],
                  [
                    {
                      :__aliases__,
                      [line: 8, column: 13],
                      [:InlineModule]
                    },
                    [
                      do: {
                        :def,
                        [line: 9, column: 5],
                        [
                          {
                            :when,
                            [line: 9, column: 19],
                            [
                              {
                                :foobar,
                                [line: 9, column: 9],
                                [
                                  {
                                    :v,
                                    [line: 9, column: 16],
                                    nil
                                  }
                                ]
                              },
                              {
                                :is_atom,
                                [line: 9, column: 24],
                                [
                                  {
                                    :v,
                                    [line: 9, column: 32],
                                    nil
                                  }
                                ]
                              }
                            ]
                          },
                          [
                            do: {
                              :=,
                              [line: 10, column: 13],
                              [
                                {
                                  :{},
                                  [line: 10, column: 7],
                                  [:ok]
                                },
                                {
                                  {
                                    :.,
                                    [line: 10, column: 19],
                                    [
                                      {
                                        :__aliases__,
                                        [line: 10, column: 15],
                                        [:File]
                                      },
                                      :read
                                    ]
                                  },
                                  [
                                    {:no_parens, true},
                                    {:line, 10},
                                    {:column, 19}
                                  ],
                                  ''
                                }
                              ]
                            }
                          ]
                        ]
                      }
                    ]
                  ]
                }
              ]
            }
          ]
        ]
      }

      assert expected == ast
    end
  end

  # Elixir <= 1.10.0
  if Version.match?(System.version(), "< 1.10.0") do
    test "should give correct ast for source_example1" do
      source = @source_example1
      {:ok, ast} = Credo.Code.ast(source)

      expected =
        {:defmodule, [line: 1, column: 1],
         [
           {:__aliases__, [line: 1, column: 11], [:Credo, :Sample]},
           [
             do:
               {:__block__, [],
                [
                  {:@, [line: 2, column: 3], [{:test_attribute, [line: 2, column: 4], [:foo]}]},
                  {:def, [line: 4, column: 3],
                   [
                     {:foobar, [line: 4, column: 7], [{:parameter, [line: 4, column: 14], nil}]},
                     [
                       do:
                         {:+, [line: 5, column: 29],
                          [
                            {{:., [line: 5, column: 11],
                              [{:__aliases__, [line: 5, column: 5], [:String]}, :split]},
                             [line: 5, column: 11], [{:parameter, [line: 5, column: 18], nil}]},
                            {:parameter, [line: 5, column: 31], nil}
                          ]}
                     ]
                   ]},
                  {:defmodule, [line: 8, column: 3],
                   [
                     {:__aliases__, [line: 8, column: 13], [:InlineModule]},
                     [
                       do:
                         {:def, [line: 9, column: 5],
                          [
                            {:when, [line: 9, column: 19],
                             [
                               {:foobar, [line: 9, column: 9],
                                [{:v, [line: 9, column: 16], nil}]},
                               {:is_atom, [line: 9, column: 24],
                                [{:v, [line: 9, column: 32], nil}]}
                             ]},
                            [
                              do:
                                {:=, [line: 10, column: 13],
                                 [
                                   {:{}, [line: 10, column: 7], [:ok]},
                                   {{:., [line: 10, column: 19],
                                     [{:__aliases__, [line: 10, column: 15], [:File]}, :read]},
                                    [line: 10, column: 19], []}
                                 ]}
                            ]
                          ]}
                     ]
                   ]}
                ]}
           ]
         ]}

      assert expected == ast
    end
  end

  test "should give correct result for source_example1" do
    source = @source_example1
    wanted_token = {:identifier, {4, 14, nil}, :parameter}

    expected = [{:parameter, [line: 4, column: 14], nil}]

    {:ok, ast} = Credo.Code.ast(source)

    assert expected == Credo.Code.TokenAstCorrelation.find_tokens_in_ast(wanted_token, ast)
  end

  test "should give correct tokens for source_example1" do
    source = @source_example1
    tokens = Credo.Code.to_tokens(source)

    expected = [
      {:identifier, {1, 1, nil}, :defmodule},
      {:alias, {1, 11, nil}, :Credo},
      {:., {1, 16, nil}},
      {:alias, {1, 17, nil}, :Sample},
      {:do, {1, 24, nil}},
      {:eol, {1, 26, 1}},
      {:at_op, {2, 3, nil}, :@},
      {:identifier, {2, 4, nil}, :test_attribute},
      {:atom, {2, 19, nil}, :foo},
      {:eol, {2, 23, 2}},
      {:identifier, {4, 3, nil}, :def},
      {:paren_identifier, {4, 7, nil}, :foobar},
      {:"(", {4, 13, nil}},
      {:identifier, {4, 14, nil}, :parameter},
      {:")", {4, 23, nil}},
      {:do, {4, 25, nil}},
      {:eol, {4, 27, 1}},
      {:alias, {5, 5, nil}, :String},
      {:., {5, 11, nil}},
      {:paren_identifier, {5, 12, nil}, :split},
      {:"(", {5, 17, nil}},
      {:identifier, {5, 18, nil}, :parameter},
      {:")", {5, 27, nil}},
      {:dual_op, {5, 29, nil}, :+},
      {:identifier, {5, 31, nil}, :parameter},
      {:eol, {5, 40, 1}},
      {:end, {6, 3, nil}},
      {:eol, {6, 6, 2}},
      {:identifier, {8, 3, nil}, :defmodule},
      {:alias, {8, 13, nil}, :InlineModule},
      {:do, {8, 26, nil}},
      {:eol, {8, 28, 1}},
      {:identifier, {9, 5, nil}, :def},
      {:paren_identifier, {9, 9, nil}, :foobar},
      {:"(", {9, 15, nil}},
      {:identifier, {9, 16, nil}, :v},
      {:")", {9, 17, nil}},
      {:when_op, {9, 19, nil}, :when},
      {:paren_identifier, {9, 24, nil}, :is_atom},
      {:"(", {9, 31, nil}},
      {:identifier, {9, 32, nil}, :v},
      {:")", {9, 33, nil}},
      {:do, {9, 35, nil}},
      {:eol, {9, 37, 1}},
      {:"{", {10, 7, nil}},
      {:atom, {10, 8, nil}, :ok},
      {:"}", {10, 11, nil}},
      {:match_op, {10, 13, nil}, :=},
      {:alias, {10, 15, nil}, :File},
      {:., {10, 19, nil}},
      {:identifier, {10, 20, nil}, :read},
      {:eol, {10, 24, 1}},
      {:end, {11, 5, nil}},
      {:eol, {11, 8, 1}},
      {:end, {12, 3, nil}},
      {:eol, {12, 6, 1}},
      {:end, {13, 1, nil}},
      {:eol, {13, 4, 1}}
    ]

    assert expected == tokens
  end

  test "should give correct tokens for source_example2" do
    source = @source_example2
    tokens = Credo.Code.to_tokens(source)

    expected = [
      {:identifier, {1, 1, nil}, :defmodule},
      {:alias, {1, 11, nil}, :Credo},
      {:., {1, 16, nil}},
      {:alias, {1, 17, nil}, :Sample},
      {:do, {1, 24, nil}},
      {:eol, {1, 26, 1}},
      {:identifier, {2, 3, nil}, :defmodule},
      {:alias, {2, 13, nil}, :InlineModule},
      {:do, {2, 26, nil}},
      {:eol, {2, 28, 1}},
      {:identifier, {3, 5, nil}, :def},
      {:paren_identifier, {3, 9, nil}, :foobar},
      {:"(", {3, 15, nil}},
      {:identifier, {3, 16, nil}, :x},
      {:")", {3, 17, nil}},
      {:do, {3, 19, nil}},
      {:eol, {3, 21, 1}},
      {:identifier, {4, 7, nil}, :x},
      {:match_op, {4, 9, nil}, :=},
      {:paren_identifier, {4, 11, nil}, :f},
      {:"(", {4, 12, nil}},
      {:paren_identifier, {4, 13, nil}, :g},
      {:"(", {4, 14, nil}},
      {:paren_identifier, {4, 15, nil}, :h},
      {:"(", {4, 16, nil}},
      {:identifier, {4, 17, nil}, :a},
      {:")", {4, 18, nil}},
      {:",", {4, 19, 0}},
      {:identifier, {4, 21, nil}, :b},
      {:")", {4, 22, nil}},
      {:",", {4, 23, 0}},
      {:paren_identifier, {4, 25, nil}, :k},
      {:"(", {4, 26, nil}},
      {:paren_identifier, {4, 27, nil}, :i},
      {:"(", {4, 28, nil}},
      {:identifier, {4, 29, nil}, :c},
      {:dual_op, {4, 30, nil}, :-},
      {:int, {4, 31, 1}, '1'},
      {:")", {4, 32, nil}},
      {:dual_op, {4, 34, nil}, :+},
      {:paren_identifier, {4, 36, nil}, :j},
      {:"(", {4, 37, nil}},
      {:identifier, {4, 38, nil}, :d},
      {:dual_op, {4, 39, nil}, :-},
      {:int, {4, 40, 2}, '2'},
      {:")", {4, 41, nil}},
      {:")", {4, 42, nil}},
      {:mult_op, {4, 44, nil}, :*},
      {:paren_identifier, {4, 46, nil}, :l},
      {:"(", {4, 47, nil}},
      {:identifier, {4, 48, nil}, :e},
      {:")", {4, 49, nil}},
      {:")", {4, 50, nil}},
      {:eol, {4, 51, 1}},
      {:end, {5, 5, nil}},
      {:eol, {5, 8, 1}},
      {:end, {6, 3, nil}},
      {:eol, {6, 6, 1}},
      {:end, {7, 1, nil}},
      {:eol, {7, 4, 1}}
    ]

    assert expected == tokens
  end

  test "should give correct ast for source_example2" do
    source = @source_example2
    {:ok, ast} = Credo.Code.ast(source)

    expected =
      {:defmodule, [line: 1, column: 1],
       [
         {:__aliases__, [line: 1, column: 11], [:Credo, :Sample]},
         [
           do:
             {:defmodule, [line: 2, column: 3],
              [
                {:__aliases__, [line: 2, column: 13], [:InlineModule]},
                [
                  do:
                    {:def, [line: 3, column: 5],
                     [
                       {:foobar, [line: 3, column: 9], [{:x, [line: 3, column: 16], nil}]},
                       [
                         do:
                           {:=, [line: 4, column: 9],
                            [
                              {:x, [line: 4, column: 7], nil},
                              {:f, [line: 4, column: 11],
                               [
                                 {:g, [line: 4, column: 13],
                                  [
                                    {:h, [line: 4, column: 15],
                                     [{:a, [line: 4, column: 17], nil}]},
                                    {:b, [line: 4, column: 21], nil}
                                  ]},
                                 {:*, [line: 4, column: 44],
                                  [
                                    {:k, [line: 4, column: 25],
                                     [
                                       {:+, [line: 4, column: 34],
                                        [
                                          {:i, [line: 4, column: 27],
                                           [
                                             {:-, [line: 4, column: 30],
                                              [{:c, [line: 4, column: 29], nil}, 1]}
                                           ]},
                                          {:j, [line: 4, column: 36],
                                           [
                                             {:-, [line: 4, column: 39],
                                              [{:d, [line: 4, column: 38], nil}, 2]}
                                           ]}
                                        ]}
                                     ]},
                                    {:l, [line: 4, column: 46],
                                     [{:e, [line: 4, column: 48], nil}]}
                                  ]}
                               ]}
                            ]}
                       ]
                     ]}
                ]
              ]}
         ]
       ]}

    assert expected == ast
  end
end
