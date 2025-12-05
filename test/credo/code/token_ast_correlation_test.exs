defmodule Credo.Code.TokenAstCorrelationTest do
  use Credo.Test.Case

  @source_example1 ~S'''
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
  '''

  @source_example2 ~S'''
  defmodule Credo.Sample do
    defmodule InlineModule do
      def foobar(x) do
        x = f(g(h(a), b), k(i(c-1) + j(d-2)) * l(e))
      end
    end
  end
  '''

  test "should give correct ast for source_example1" do
    source = @source_example1
    {:ok, ast} = Credo.Code.ast(source)

    expected = {
      :defmodule,
      [
        {:end_of_expression, [newlines: 1, line: 13, column: 4]},
        {:do, [line: 1, column: 24]},
        {:end, [line: 13, column: 1]},
        {:line, 1},
        {:column, 1}
      ],
      [
        {:__aliases__, [{:last, [line: 1, column: 17]}, {:line, 1}, {:column, 11}],
         [:Credo, :Sample]},
        [
          do: {
            :__block__,
            [],
            [
              {
                :@,
                [
                  {:end_of_expression, [newlines: 2, line: 2, column: 23]},
                  {:line, 2},
                  {:column, 3}
                ],
                [{:test_attribute, [line: 2, column: 4], [:foo]}]
              },
              {
                :def,
                [
                  {:end_of_expression, [newlines: 2, line: 6, column: 6]},
                  {:do, [line: 4, column: 25]},
                  {:end, [line: 6, column: 3]},
                  {:line, 4},
                  {:column, 3}
                ],
                [
                  {
                    :foobar,
                    [{:closing, [line: 4, column: 23]}, {:line, 4}, {:column, 7}],
                    [{:parameter, [line: 4, column: 14], nil}]
                  },
                  [
                    do: {
                      :+,
                      [
                        {:end_of_expression, [newlines: 1, line: 5, column: 40]},
                        {:line, 5},
                        {:column, 29}
                      ],
                      [
                        {
                          {
                            :.,
                            [line: 5, column: 11],
                            [
                              {
                                :__aliases__,
                                [{:last, [line: 5, column: 5]}, {:line, 5}, {:column, 5}],
                                [:String]
                              },
                              :split
                            ]
                          },
                          [{:closing, [line: 5, column: 27]}, {:line, 5}, {:column, 12}],
                          [{:parameter, [line: 5, column: 18], nil}]
                        },
                        {:parameter, [line: 5, column: 31], nil}
                      ]
                    }
                  ]
                ]
              },
              {
                :defmodule,
                [
                  {:end_of_expression, [newlines: 1, line: 12, column: 6]},
                  {:do, [line: 8, column: 26]},
                  {:end, [line: 12, column: 3]},
                  {:line, 8},
                  {:column, 3}
                ],
                [
                  {:__aliases__, [{:last, [line: 8, column: 13]}, {:line, 8}, {:column, 13}],
                   [:InlineModule]},
                  [
                    do: {
                      :def,
                      [
                        {:end_of_expression, [newlines: 1, line: 11, column: 8]},
                        {:do, [line: 9, column: 35]},
                        {:end, [line: 11, column: 5]},
                        {:line, 9},
                        {:column, 5}
                      ],
                      [
                        {
                          :when,
                          [line: 9, column: 19],
                          [
                            {
                              :foobar,
                              [{:closing, [line: 9, column: 17]}, {:line, 9}, {:column, 9}],
                              [{:v, [line: 9, column: 16], nil}]
                            },
                            {
                              :is_atom,
                              [{:closing, [line: 9, column: 33]}, {:line, 9}, {:column, 24}],
                              [{:v, [line: 9, column: 32], nil}]
                            }
                          ]
                        },
                        [
                          do: {
                            :=,
                            [
                              {:end_of_expression, [newlines: 1, line: 10, column: 24]},
                              {:line, 10},
                              {:column, 13}
                            ],
                            [
                              {:{},
                               [{:closing, [line: 10, column: 11]}, {:line, 10}, {:column, 7}],
                               [:ok]},
                              {
                                {
                                  :.,
                                  [line: 10, column: 19],
                                  [
                                    {
                                      :__aliases__,
                                      [
                                        {:last, [line: 10, column: 15]},
                                        {:line, 10},
                                        {:column, 15}
                                      ],
                                      [:File]
                                    },
                                    :read
                                  ]
                                },
                                [no_parens: true, line: 10, column: 20],
                                []
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

    expected =
      if Version.match?(System.version(), ">= 1.14.0-dev") do
        [
          {:identifier, {1, 1, ~c"defmodule"}, :defmodule},
          {:alias, {1, 11, ~c"Credo"}, :Credo},
          {:., {1, 16, nil}},
          {:alias, {1, 17, ~c"Sample"}, :Sample},
          {:do, {1, 24, nil}},
          {:eol, {1, 26, 1}},
          {:at_op, {2, 3, nil}, :@},
          {:identifier, {2, 4, ~c"test_attribute"}, :test_attribute},
          {:atom, {2, 19, ~c"foo"}, :foo},
          {:eol, {2, 23, 2}},
          {:identifier, {4, 3, ~c"def"}, :def},
          {:paren_identifier, {4, 7, ~c"foobar"}, :foobar},
          {:"(", {4, 13, nil}},
          {:identifier, {4, 14, ~c"parameter"}, :parameter},
          {:")", {4, 23, nil}},
          {:do, {4, 25, nil}},
          {:eol, {4, 27, 1}},
          {:alias, {5, 5, ~c"String"}, :String},
          {:., {5, 11, nil}},
          {:paren_identifier, {5, 12, ~c"split"}, :split},
          {:"(", {5, 17, nil}},
          {:identifier, {5, 18, ~c"parameter"}, :parameter},
          {:")", {5, 27, nil}},
          {:dual_op, {5, 29, nil}, :+},
          {:identifier, {5, 31, ~c"parameter"}, :parameter},
          {:eol, {5, 40, 1}},
          {:end, {6, 3, nil}},
          {:eol, {6, 6, 2}},
          {:identifier, {8, 3, ~c"defmodule"}, :defmodule},
          {:alias, {8, 13, ~c"InlineModule"}, :InlineModule},
          {:do, {8, 26, nil}},
          {:eol, {8, 28, 1}},
          {:identifier, {9, 5, ~c"def"}, :def},
          {:paren_identifier, {9, 9, ~c"foobar"}, :foobar},
          {:"(", {9, 15, nil}},
          {:identifier, {9, 16, ~c"v"}, :v},
          {:")", {9, 17, nil}},
          {:when_op, {9, 19, nil}, :when},
          {:paren_identifier, {9, 24, ~c"is_atom"}, :is_atom},
          {:"(", {9, 31, nil}},
          {:identifier, {9, 32, ~c"v"}, :v},
          {:")", {9, 33, nil}},
          {:do, {9, 35, nil}},
          {:eol, {9, 37, 1}},
          {:"{", {10, 7, nil}},
          {:atom, {10, 8, ~c"ok"}, :ok},
          {:"}", {10, 11, nil}},
          {:match_op, {10, 13, nil}, :=},
          {:alias, {10, 15, ~c"File"}, :File},
          {:., {10, 19, nil}},
          {:identifier, {10, 20, ~c"read"}, :read},
          {:eol, {10, 24, 1}},
          {:end, {11, 5, nil}},
          {:eol, {11, 8, 1}},
          {:end, {12, 3, nil}},
          {:eol, {12, 6, 1}},
          {:end, {13, 1, nil}},
          {:eol, {13, 4, 1}}
        ]
      else
        [
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
      end

    assert expected == tokens
  end

  test "should give correct tokens for source_example2" do
    source = @source_example2
    tokens = Credo.Code.to_tokens(source)

    expected =
      if Version.match?(System.version(), ">= 1.14.0-dev") do
        [
          {:identifier, {1, 1, ~c"defmodule"}, :defmodule},
          {:alias, {1, 11, ~c"Credo"}, :Credo},
          {:., {1, 16, nil}},
          {:alias, {1, 17, ~c"Sample"}, :Sample},
          {:do, {1, 24, nil}},
          {:eol, {1, 26, 1}},
          {:identifier, {2, 3, ~c"defmodule"}, :defmodule},
          {:alias, {2, 13, ~c"InlineModule"}, :InlineModule},
          {:do, {2, 26, nil}},
          {:eol, {2, 28, 1}},
          {:identifier, {3, 5, ~c"def"}, :def},
          {:paren_identifier, {3, 9, ~c"foobar"}, :foobar},
          {:"(", {3, 15, nil}},
          {:identifier, {3, 16, ~c"x"}, :x},
          {:")", {3, 17, nil}},
          {:do, {3, 19, nil}},
          {:eol, {3, 21, 1}},
          {:identifier, {4, 7, ~c"x"}, :x},
          {:match_op, {4, 9, nil}, :=},
          {:paren_identifier, {4, 11, ~c"f"}, :f},
          {:"(", {4, 12, nil}},
          {:paren_identifier, {4, 13, ~c"g"}, :g},
          {:"(", {4, 14, nil}},
          {:paren_identifier, {4, 15, ~c"h"}, :h},
          {:"(", {4, 16, nil}},
          {:identifier, {4, 17, ~c"a"}, :a},
          {:")", {4, 18, nil}},
          {:",", {4, 19, 0}},
          {:identifier, {4, 21, ~c"b"}, :b},
          {:")", {4, 22, nil}},
          {:",", {4, 23, 0}},
          {:paren_identifier, {4, 25, ~c"k"}, :k},
          {:"(", {4, 26, nil}},
          {:paren_identifier, {4, 27, ~c"i"}, :i},
          {:"(", {4, 28, nil}},
          {:identifier, {4, 29, ~c"c"}, :c},
          {:dual_op, {4, 30, nil}, :-},
          {:int, {4, 31, 1}, ~c"1"},
          {:")", {4, 32, nil}},
          {:dual_op, {4, 34, nil}, :+},
          {:paren_identifier, {4, 36, ~c"j"}, :j},
          {:"(", {4, 37, nil}},
          {:identifier, {4, 38, ~c"d"}, :d},
          {:dual_op, {4, 39, nil}, :-},
          {:int, {4, 40, 2}, ~c"2"},
          {:")", {4, 41, nil}},
          {:")", {4, 42, nil}},
          {:mult_op, {4, 44, nil}, :*},
          {:paren_identifier, {4, 46, ~c"l"}, :l},
          {:"(", {4, 47, nil}},
          {:identifier, {4, 48, ~c"e"}, :e},
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
      else
        [
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
          {:int, {4, 31, 1}, ~c"1"},
          {:")", {4, 32, nil}},
          {:dual_op, {4, 34, nil}, :+},
          {:paren_identifier, {4, 36, nil}, :j},
          {:"(", {4, 37, nil}},
          {:identifier, {4, 38, nil}, :d},
          {:dual_op, {4, 39, nil}, :-},
          {:int, {4, 40, 2}, ~c"2"},
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
      end

    assert expected == tokens
  end

  test "should give correct ast for source_example2" do
    source = @source_example2
    {:ok, ast} = Credo.Code.ast(source)

    expected =
      {
        :defmodule,
        [
          {:end_of_expression, [newlines: 1, line: 7, column: 4]},
          {:do, [line: 1, column: 24]},
          {:end, [line: 7, column: 1]},
          {:line, 1},
          {:column, 1}
        ],
        [
          {:__aliases__, [{:last, [line: 1, column: 17]}, {:line, 1}, {:column, 11}],
           [:Credo, :Sample]},
          [
            do: {
              :defmodule,
              [
                {:end_of_expression, [newlines: 1, line: 6, column: 6]},
                {:do, [line: 2, column: 26]},
                {:end, [line: 6, column: 3]},
                {:line, 2},
                {:column, 3}
              ],
              [
                {:__aliases__, [{:last, [line: 2, column: 13]}, {:line, 2}, {:column, 13}],
                 [:InlineModule]},
                [
                  do: {
                    :def,
                    [
                      {:end_of_expression, [newlines: 1, line: 5, column: 8]},
                      {:do, [line: 3, column: 19]},
                      {:end, [line: 5, column: 5]},
                      {:line, 3},
                      {:column, 5}
                    ],
                    [
                      {
                        :foobar,
                        [{:closing, [line: 3, column: 17]}, {:line, 3}, {:column, 9}],
                        [{:x, [line: 3, column: 16], nil}]
                      },
                      [
                        do: {
                          :=,
                          [
                            {:end_of_expression, [newlines: 1, line: 4, column: 51]},
                            {:line, 4},
                            {:column, 9}
                          ],
                          [
                            {:x, [line: 4, column: 7], nil},
                            {
                              :f,
                              [{:closing, [line: 4, column: 50]}, {:line, 4}, {:column, 11}],
                              [
                                {
                                  :g,
                                  [{:closing, [line: 4, column: 22]}, {:line, 4}, {:column, 13}],
                                  [
                                    {
                                      :h,
                                      [
                                        {:closing, [line: 4, column: 18]},
                                        {:line, 4},
                                        {:column, 15}
                                      ],
                                      [{:a, [line: 4, column: 17], nil}]
                                    },
                                    {:b, [line: 4, column: 21], nil}
                                  ]
                                },
                                {
                                  :*,
                                  [line: 4, column: 44],
                                  [
                                    {
                                      :k,
                                      [
                                        {:closing, [line: 4, column: 42]},
                                        {:line, 4},
                                        {:column, 25}
                                      ],
                                      [
                                        {
                                          :+,
                                          [line: 4, column: 34],
                                          [
                                            {
                                              :i,
                                              [
                                                {:closing, [line: 4, column: 32]},
                                                {:line, 4},
                                                {:column, 27}
                                              ],
                                              [
                                                {:-, [line: 4, column: 30],
                                                 [{:c, [line: 4, column: 29], nil}, 1]}
                                              ]
                                            },
                                            {
                                              :j,
                                              [
                                                {:closing, [line: 4, column: 41]},
                                                {:line, 4},
                                                {:column, 36}
                                              ],
                                              [
                                                {:-, [line: 4, column: 39],
                                                 [{:d, [line: 4, column: 38], nil}, 2]}
                                              ]
                                            }
                                          ]
                                        }
                                      ]
                                    },
                                    {
                                      :l,
                                      [
                                        {:closing, [line: 4, column: 49]},
                                        {:line, 4},
                                        {:column, 46}
                                      ],
                                      [{:e, [line: 4, column: 48], nil}]
                                    }
                                  ]
                                }
                              ]
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
        ]
      }

    assert expected == ast
  end
end
