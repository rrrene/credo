defmodule Credo.Code.TokenTest do
  use Credo.Test.Case

  alias Credo.Code.Token

  @heredoc_interpolations_source """
  def fun() do
    a = \"\"\"
    MyModule.\#{fun(Module.value() + 1)}.SubModule.\#{name}"
    \"\"\"
  end
  """
  @heredoc_interpolations_position {1, 5, 1, 60}

  @multiple_interpolations_source ~S[a = "MyModule.#{fun(Module.value() + 1)}.SubModule.#{name}"]
  @multiple_interpolations_position {1, 5, 1, 60}

  @single_interpolations_bin_string_source ~S[a = "MyModule.SubModule.#{name}"]
  @single_interpolations_bin_string_position {1, 5, 1, 33}

  @no_interpolations_source ~S[134 + 145]
  @no_interpolations_position {1, 7, 1, 10}

  # Elixir >= 1.9.0
  if Version.match?(System.version(), ">= 1.9.0") do
    @single_interpolations_list_string_source ~S[a = 'MyModule.SubModule.#{name}']
    @single_interpolations_list_string_position {1, 5, 1, 33}

    @tag :token_position
    test "should give correct token position" do
      source = @no_interpolations_source
      tokens = Credo.Code.to_tokens(source)

      expected = [
        {:int, {1, 1, 134}, ~c"134"},
        {:dual_op, {1, 5, nil}, :+},
        {:int, {1, 7, 145}, ~c"145"}
      ]

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @no_interpolations_position == position
    end

    @tag :token_position
    test "should give correct token position with a single interpolation" do
      source = @single_interpolations_bin_string_source
      tokens = Credo.Code.to_tokens(source)

      expected =
        if Version.match?(System.version(), ">= 1.14.0-dev") do
          [
            {:identifier, {1, 1, ~c"a"}, :a},
            {:match_op, {1, 3, nil}, :=},
            {:bin_string, {1, 5, nil},
             [
               "MyModule.SubModule.",
               {{1, 25, nil}, {1, 31, nil}, [{:identifier, {1, 27, ~c"name"}, :name}]}
             ]}
          ]
        else
          [
            {:identifier, {1, 1, nil}, :a},
            {:match_op, {1, 3, nil}, :=},
            {:bin_string, {1, 5, nil},
             [
               "MyModule.SubModule.",
               {{1, 25, nil}, {1, 31, nil}, [{:identifier, {1, 27, nil}, :name}]}
             ]}
          ]
        end

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @single_interpolations_bin_string_position == position
    end

    @tag :token_position
    test "should give correct token position with a single interpolation with list string" do
      source = @single_interpolations_list_string_source
      tokens = Credo.Code.to_tokens(source)

      expected =
        if Version.match?(System.version(), ">= 1.14.0-dev") do
          [
            {:identifier, {1, 1, ~c"a"}, :a},
            {:match_op, {1, 3, nil}, :=},
            {:list_string, {1, 5, nil},
             [
               "MyModule.SubModule.",
               {{1, 25, nil}, {1, 31, nil}, [{:identifier, {1, 27, ~c"name"}, :name}]}
             ]}
          ]
        else
          [
            {:identifier, {1, 1, nil}, :a},
            {:match_op, {1, 3, nil}, :=},
            {:list_string, {1, 5, nil},
             [
               "MyModule.SubModule.",
               {{1, 25, nil}, {1, 31, nil}, [{:identifier, {1, 27, nil}, :name}]}
             ]}
          ]
        end

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @single_interpolations_list_string_position == position
    end

    @tag :token_position
    test "should give correct token position with multiple interpolations" do
      source = @multiple_interpolations_source
      tokens = Credo.Code.to_tokens(source)

      expected =
        if Version.match?(System.version(), ">= 1.14.0-dev") do
          [
            {:identifier, {1, 1, ~c"a"}, :a},
            {:match_op, {1, 3, nil}, :=},
            {:bin_string, {1, 5, nil},
             [
               "MyModule.",
               {{1, 15, nil}, {1, 40, nil},
                [
                  {:paren_identifier, {1, 17, ~c"fun"}, :fun},
                  {:"(", {1, 20, nil}},
                  {:alias, {1, 21, ~c"Module"}, :Module},
                  {:., {1, 27, nil}},
                  {:paren_identifier, {1, 28, ~c"value"}, :value},
                  {:"(", {1, 33, nil}},
                  {:")", {1, 34, nil}},
                  {:dual_op, {1, 36, nil}, :+},
                  {:int, {1, 38, 1}, ~c"1"},
                  {:")", {1, 39, nil}}
                ]},
               ".SubModule.",
               {{1, 52, nil}, {1, 58, nil}, [{:identifier, {1, 54, ~c"name"}, :name}]}
             ]}
          ]
        else
          [
            {:identifier, {1, 1, nil}, :a},
            {:match_op, {1, 3, nil}, :=},
            {:bin_string, {1, 5, nil},
             [
               "MyModule.",
               {{1, 15, nil}, {1, 40, nil},
                [
                  {:paren_identifier, {1, 17, nil}, :fun},
                  {:"(", {1, 20, nil}},
                  {:alias, {1, 21, nil}, :Module},
                  {:., {1, 27, nil}},
                  {:paren_identifier, {1, 28, nil}, :value},
                  {:"(", {1, 33, nil}},
                  {:")", {1, 34, nil}},
                  {:dual_op, {1, 36, nil}, :+},
                  {:int, {1, 38, 1}, ~c"1"},
                  {:")", {1, 39, nil}}
                ]},
               ".SubModule.",
               {{1, 52, nil}, {1, 58, nil}, [{:identifier, {1, 54, nil}, :name}]}
             ]}
          ]
        end

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @multiple_interpolations_position == position
    end

    @tag :to_be_implemented
    @tag :token_position
    test "should give correct token position with multiple interpolations in heredoc" do
      source = @heredoc_interpolations_source
      tokens = Credo.Code.to_tokens(source)

      expected = [
        {:identifier, {1, 1, nil}, :def},
        {:paren_identifier, {1, 5, nil}, :fun},
        {:"(", {1, 8, nil}},
        {:")", {1, 9, nil}},
        {:do, {1, 11, nil}},
        {:eol, {1, 13, 1}},
        {:identifier, {2, 3, nil}, :a},
        {:match_op, {2, 5, nil}, :=},
        {:bin_heredoc, {2, 7, nil},
         [
           "MyModule.",
           {{3, 10, 3},
            [
              {:paren_identifier, {3, 12, nil}, :fun},
              {:"(", {3, 15, nil}},
              {:alias, {3, 16, nil}, :Module},
              {:., {3, 22, nil}},
              {:paren_identifier, {3, 23, nil}, :value},
              {:"(", {3, 28, nil}},
              {:")", {3, 29, nil}},
              {:dual_op, {3, 31, nil}, :+},
              {:int, {3, 33, 1}, ~c"1"},
              {:")", {3, 34, nil}}
            ]},
           ".SubModule.",
           {{3, 47, 3}, [{:identifier, {3, 49, nil}, :name}]},
           "\"\n"
         ]},
        {:eol, {4, 1, 1}},
        {:end, {5, 1, nil}},
        {:eol, {5, 4, 1}}
      ]

      assert expected == tokens

      position = expected |> List.last() |> Token.position()

      assert @heredoc_interpolations_position == position
    end

    if Version.match?(System.version(), ">= 1.18.0-dev") do
      @kw_identifier_token {:kw_identifier, {1, 3, 34}, :"some-atom-with-quotes"}
    else
      @kw_identifier_token {:kw_identifier, {1, 3, nil}, :"some-atom-with-quotes"}
    end

    @tag needs_elixir: "1.7.0"
    test "should give correct token position for map" do
      source = ~S(%{"some-atom-with-quotes": "#{filename} world"})
      tokens = Credo.Code.to_tokens(source)

      expected =
        cond do
          Version.match?(System.version(), ">= 1.17.0-rc.0") ->
            [
              {:%{}, {1, 1, nil}},
              {:"{", {1, 1, nil}},
              @kw_identifier_token,
              {:bin_string, {1, 28, nil},
               [
                 {{1, 29, nil}, {1, 39, nil}, [{:identifier, {1, 31, ~c"filename"}, :filename}]},
                 " world"
               ]},
              {:"}", {1, 47, nil}}
            ]

          Version.match?(System.version(), ">= 1.14.0-dev") ->
            [
              {:%{}, {1, 1, nil}},
              {:"{", {1, 2, nil}},
              @kw_identifier_token,
              {:bin_string, {1, 28, nil},
               [
                 {{1, 29, nil}, {1, 39, nil}, [{:identifier, {1, 31, ~c"filename"}, :filename}]},
                 " world"
               ]},
              {:"}", {1, 47, nil}}
            ]

          true ->
            [
              {:%{}, {1, 1, nil}},
              {:"{", {1, 2, nil}},
              @kw_identifier_token,
              {:bin_string, {1, 28, nil},
               [{{1, 29, nil}, {1, 39, nil}, [{:identifier, {1, 31, nil}, :filename}]}, " world"]},
              {:"}", {1, 47, nil}}
            ]
        end

      assert expected == tokens

      position = expected |> Enum.take(4) |> List.last() |> Token.position()

      assert {1, 28, 1, 47} == position
    end

    test "should give correct token position for map /2" do
      source = ~S(%{some_atom_with_quotes: "#{filename} world"})
      tokens = Credo.Code.to_tokens(source)

      expected =
        cond do
          Version.match?(System.version(), ">= 1.17.0-rc.0") ->
            [
              {:%{}, {1, 1, nil}},
              {:"{", {1, 1, nil}},
              {:kw_identifier, {1, 3, ~c"some_atom_with_quotes"}, :some_atom_with_quotes},
              {:bin_string, {1, 26, nil},
               [
                 {{1, 27, nil}, {1, 37, nil}, [{:identifier, {1, 29, ~c"filename"}, :filename}]},
                 " world"
               ]},
              {:"}", {1, 45, nil}}
            ]

          Version.match?(System.version(), ">= 1.14.0-dev") ->
            [
              {:%{}, {1, 1, nil}},
              {:"{", {1, 2, nil}},
              {:kw_identifier, {1, 3, ~c"some_atom_with_quotes"}, :some_atom_with_quotes},
              {:bin_string, {1, 26, nil},
               [
                 {{1, 27, nil}, {1, 37, nil}, [{:identifier, {1, 29, ~c"filename"}, :filename}]},
                 " world"
               ]},
              {:"}", {1, 45, nil}}
            ]

          true ->
            [
              {:%{}, {1, 1, nil}},
              {:"{", {1, 2, nil}},
              {:kw_identifier, {1, 3, nil}, :some_atom_with_quotes},
              {:bin_string, {1, 26, nil},
               [{{1, 27, nil}, {1, 37, nil}, [{:identifier, {1, 29, nil}, :filename}]}, " world"]},
              {:"}", {1, 45, nil}}
            ]
        end

      assert expected == tokens

      position = expected |> Enum.take(4) |> List.last() |> Token.position()

      assert {1, 26, 1, 45} == position
    end
  end

  test "should give correct token position for identifiers" do
    source =
      ~S"""
      defmodule InlineModule do
        def foobar do
          {:ok} = File.read(filename)
        end
      end
      """

    tokens = Credo.Code.to_tokens(source)

    expected = [
      {:identifier, {1, 1, ~c"defmodule"}, :defmodule},
      {:alias, {1, 11, ~c"InlineModule"}, :InlineModule},
      {:do, {1, 24, nil}},
      {:eol, {1, 26, 1}},
      {:identifier, {2, 3, ~c"def"}, :def},
      {:do_identifier, {2, 7, ~c"foobar"}, :foobar},
      {:do, {2, 14, nil}},
      {:eol, {2, 16, 1}},
      {:"{", {3, 5, nil}},
      {:atom, {3, 6, ~c"ok"}, :ok},
      {:"}", {3, 9, nil}},
      {:match_op, {3, 11, nil}, :=},
      {:alias, {3, 13, ~c"File"}, :File},
      {:., {3, 17, nil}},
      {:paren_identifier, {3, 18, ~c"read"}, :read},
      {:"(", {3, 22, nil}},
      {:identifier, {3, 23, ~c"filename"}, :filename},
      {:")", {3, 31, nil}},
      {:eol, {3, 32, 1}},
      {:end, {4, 3, nil}},
      {:eol, {4, 6, 1}},
      {:end, {5, 1, nil}},
      {:eol, {5, 4, 1}}
    ]

    assert tokens == expected

    assert {2, 7, 2, 14} == Token.position({:do_identifier, {2, 7, ~c"filenam"}, :filenam})
    assert {3, 6, 3, 9} == Token.position({:atom, {3, 6, ~c"ok"}, :ok})
    assert {3, 23, 3, 31} == Token.position({:identifier, {3, 23, ~c"filename"}, :filename})
    assert {3, 18, 3, 22} == Token.position({:paren_identifier, {3, 18, ~c"read"}, :read})
  end

  test "should give correct token position for sigils" do
    tokens =
      Credo.Code.to_tokens(~S'''
        parse_code(:"okay", acc <> ~s(\"\"\"))
      ''')

    assert match?(
             [
               {:paren_identifier, {1, 3, ~c"parse_code"}, :parse_code},
               {:"(", {1, 13, nil}},
               {:atom_quoted, {1, 14, _nil_or_34}, :okay},
               {:",", {1, 21, 0}},
               {:identifier, {1, 23, ~c"acc"}, :acc},
               {:concat_op, {1, 27, nil}, :<>},
               {:sigil, {1, 30, nil}, :sigil_s, ["\\\"\\\"\\\""], [], nil, "("},
               {:")", {1, 40, nil}},
               {:eol, {1, 41, 1}}
             ],
             tokens
           )

    assert {1, 18, 1, 25} == Token.position({:atom_quoted, {1, 18, 34}, :okay})
    assert {1, 30, 1, 40} == Token.position({:sigil, {1, 30, nil}, :sigil_s, ["\\\"\\\"\\\""], [], nil, "("})

    assert {11, 28, 11, 39} == Token.position({:sigil, {11, 28, nil}, :sigil_XX, ["\\\"\\\"\\\""], [], nil, "("})
  end

  test "should give correct token position for strings" do
    tokens =
      Credo.Code.to_tokens(~S'''
      parse_code("okay")
      x = "a
        b"
      y = "a
        b"
      ''')

    expected = [
      {:paren_identifier, {1, 1, ~c"parse_code"}, :parse_code},
      {:"(", {1, 11, nil}},
      {:bin_string, {1, 12, nil}, ["okay"]},
      {:")", {1, 18, nil}},
      {:eol, {1, 19, 1}},
      {:identifier, {2, 1, ~c"x"}, :x},
      {:match_op, {2, 3, nil}, :=},
      {:bin_string, {2, 5, nil}, ["a\n  b"]},
      {:eol, {3, 5, 1}},
      {:identifier, {4, 1, ~c"y"}, :y},
      {:match_op, {4, 3, nil}, :=},
      {:bin_string, {4, 5, nil}, ["a\n  b"]},
      {:eol, {5, 5, 1}}
    ]

    assert tokens == expected

    assert {1, 12, 1, 18} == Token.position({:bin_string, {1, 12, nil}, ["okay"]})
    assert {2, 5, 3, 5} == Token.position({:bin_string, {2, 5, nil}, ["a\n  b"]})
  end

  test "should give correct token position for strings with interpolations" do
    tokens =
      Credo.Code.to_tokens(~S'''
      a = "MyModule.#{fun(Module.value() + 1)}"
      b = "___#{fun(Module.value() + 1)}.SubModule.#{name}
        MyModule.#{fun(Module.value() + 1)}.SubModule.#{okay}"
      ''')

    expected = [
      {:identifier, {1, 1, ~c"a"}, :a},
      {:match_op, {1, 3, nil}, :=},
      {:bin_string, {1, 5, nil},
       [
         "MyModule.",
         {{1, 15, nil}, {1, 40, nil},
          [
            {:paren_identifier, {1, 17, ~c"fun"}, :fun},
            {:"(", {1, 20, nil}},
            {:alias, {1, 21, ~c"Module"}, :Module},
            {:., {1, 27, nil}},
            {:paren_identifier, {1, 28, ~c"value"}, :value},
            {:"(", {1, 33, nil}},
            {:")", {1, 34, nil}},
            {:dual_op, {1, 36, nil}, :+},
            {:int, {1, 38, 1}, ~c"1"},
            {:")", {1, 39, nil}}
          ]}
       ]},
      {:eol, {1, 42, 1}},
      {:identifier, {2, 1, ~c"b"}, :b},
      {:match_op, {2, 3, nil}, :=},
      {:bin_string, {2, 5, nil},
       [
         "___",
         {{2, 9, nil}, {2, 34, nil},
          [
            {:paren_identifier, {2, 11, ~c"fun"}, :fun},
            {:"(", {2, 14, nil}},
            {:alias, {2, 15, ~c"Module"}, :Module},
            {:., {2, 21, nil}},
            {:paren_identifier, {2, 22, ~c"value"}, :value},
            {:"(", {2, 27, nil}},
            {:")", {2, 28, nil}},
            {:dual_op, {2, 30, nil}, :+},
            {:int, {2, 32, 1}, ~c"1"},
            {:")", {2, 33, nil}}
          ]},
         ".SubModule.",
         {{2, 46, nil}, {2, 52, nil}, [{:identifier, {2, 48, ~c"name"}, :name}]},
         "\n  MyModule.",
         {{3, 12, nil}, {3, 37, nil},
          [
            {:paren_identifier, {3, 14, ~c"fun"}, :fun},
            {:"(", {3, 17, nil}},
            {:alias, {3, 18, ~c"Module"}, :Module},
            {:., {3, 24, nil}},
            {:paren_identifier, {3, 25, ~c"value"}, :value},
            {:"(", {3, 30, nil}},
            {:")", {3, 31, nil}},
            {:dual_op, {3, 33, nil}, :+},
            {:int, {3, 35, 1}, ~c"1"},
            {:")", {3, 36, nil}}
          ]},
         ".SubModule.",
         {{3, 49, nil}, {3, 55, nil}, [{:identifier, {3, 51, ~c"okay"}, :okay}]}
       ]},
      {:eol, {3, 57, 1}}
    ]

    assert tokens == expected

    assert {1, 5, 1, 42} ==
             Token.position(
               {:bin_string, {1, 5, nil},
                [
                  "MyModule.",
                  {{1, 15, nil}, {1, 40, nil},
                   [
                     {:paren_identifier, {1, 17, ~c"fun"}, :fun},
                     {:"(", {1, 20, nil}},
                     {:alias, {1, 21, ~c"Module"}, :Module},
                     {:., {1, 27, nil}},
                     {:paren_identifier, {1, 28, ~c"value"}, :value},
                     {:"(", {1, 33, nil}},
                     {:")", {1, 34, nil}},
                     {:dual_op, {1, 36, nil}, :+},
                     {:int, {1, 38, 1}, ~c"1"},
                     {:")", {1, 39, nil}}
                   ]}
                ]}
             )

    assert {2, 5, 3, 57} ==
             Token.position(
               {:bin_string, {2, 5, nil},
                [
                  "___",
                  {{2, 9, nil}, {2, 34, nil},
                   [
                     {:paren_identifier, {2, 11, ~c"fun"}, :fun},
                     {:"(", {2, 14, nil}},
                     {:alias, {2, 15, ~c"Module"}, :Module},
                     {:., {2, 21, nil}},
                     {:paren_identifier, {2, 22, ~c"value"}, :value},
                     {:"(", {2, 27, nil}},
                     {:")", {2, 28, nil}},
                     {:dual_op, {2, 30, nil}, :+},
                     {:int, {2, 32, 1}, ~c"1"},
                     {:")", {2, 33, nil}}
                   ]},
                  ".SubModule.",
                  {{2, 46, nil}, {2, 52, nil}, [{:identifier, {2, 48, ~c"name"}, :name}]},
                  "\n  MyModule.",
                  {{3, 12, nil}, {3, 37, nil},
                   [
                     {:paren_identifier, {3, 14, ~c"fun"}, :fun},
                     {:"(", {3, 17, nil}},
                     {:alias, {3, 18, ~c"Module"}, :Module},
                     {:., {3, 24, nil}},
                     {:paren_identifier, {3, 25, ~c"value"}, :value},
                     {:"(", {3, 30, nil}},
                     {:")", {3, 31, nil}},
                     {:dual_op, {3, 33, nil}, :+},
                     {:int, {3, 35, 1}, ~c"1"},
                     {:")", {3, 36, nil}}
                   ]},
                  ".SubModule.",
                  {{3, 49, nil}, {3, 55, nil}, [{:identifier, {3, 51, ~c"okay"}, :okay}]}
                ]}
             )
  end

  test "should give correct token position for captures and characters" do
    tokens =
      Credo.Code.to_tokens(~S'''
      {suffix, remainder} = Enum.split_while(remainder, &(&1 != ?\n))
      ''')

    expected = [
      {:"{", {1, 1, nil}},
      {:identifier, {1, 2, ~c"suffix"}, :suffix},
      {:",", {1, 8, 0}},
      {:identifier, {1, 10, ~c"remainder"}, :remainder},
      {:"}", {1, 19, nil}},
      {:match_op, {1, 21, nil}, :=},
      {:alias, {1, 23, ~c"Enum"}, :Enum},
      {:., {1, 27, nil}},
      {:paren_identifier, {1, 28, ~c"split_while"}, :split_while},
      {:"(", {1, 39, nil}},
      {:identifier, {1, 40, ~c"remainder"}, :remainder},
      {:",", {1, 49, 0}},
      {:capture_op, {1, 51, nil}, :&},
      {:"(", {1, 52, nil}},
      {:capture_int, {1, 53, nil}, :&},
      {:int, {1, 54, 1}, ~c"1"},
      {:comp_op, {1, 56, nil}, :!=},
      {:char, {1, 59, ~c"?\\n"}, 10},
      {:")", {1, 62, nil}},
      {:")", {1, 63, nil}},
      {:eol, {1, 64, 1}}
    ]

    assert tokens == expected

    assert {1, 59, 1, 62} == Token.position({:char, {1, 59, ~c"?\\n"}, 10})
  end
end
