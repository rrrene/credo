defmodule Credo.Code.BlockTest do
  use Credo.Test.Case

  alias Credo.Code.Block

  test "it should return all the blocks" do
    {:ok, ast} =
      """
      try do
        call_in_try
      else
        call_in_else
      rescue
        call_in_rescue
      after
        call_in_after
      end
      """
      |> Code.string_to_quoted()

    assert 4 ==
             ast
             |> Block.all_blocks_for!()
             |> Enum.reject(&is_nil/1)
             |> Enum.count()
  end

  test "the truth" do
    arguments = [
      {:parameter1, [line: 4], nil},
      [
        do: [
          {:->, [line: 5], [[0], nil]},
          {:->, [line: 6],
           [
             [1],
             {:if, [line: 7],
              [
                {:parameter2, [line: 7], nil},
                [do: {:do_something, [line: 7], nil}]
              ]}
           ]}
        ]
      ]
    ]

    expected = [
      {:->, [line: 5], [[0], nil]},
      {:->, [line: 6],
       [
         [1],
         {:if, [line: 7],
          [
            {:parameter2, [line: 7], nil},
            [do: {:do_something, [line: 7], nil}]
          ]}
       ]}
    ]

    assert expected == Block.do_block_for!(arguments)
  end

  test "it should return both the do and else blocks" do
    {:ok, ast} =
      """
      if something? do
        some_action
        IO.puts "HA"
      else
        some_other_action
        IO.puts "Yay!"
      end
      """
      |> Code.string_to_quoted()

    assert {:__block__, [],
            [
              {:some_action, [line: 2], nil},
              {{:., [line: 3], [{:__aliases__, _, [:IO]}, :puts]}, [line: 3],
               [
                 "HA"
               ]}
            ]} = Block.do_block_for!(ast)

    assert Block.else_block?(ast)

    assert {:__block__, [],
            [
              {:some_other_action, [line: 5], nil},
              {{:., [line: 6], [{:__aliases__, _, [:IO]}, :puts]}, [line: 6],
               [
                 "Yay!"
               ]}
            ]} = Block.else_block_for!(ast)
  end

  test "it should return whether an `ast` has a do and/or else block with just one operation in it" do
    {:ok, ast} =
      """
      if something? do
        true
      else
        false
      end
      """
      |> Code.string_to_quoted()

    assert Block.do_block?(ast)
    assert Block.else_block?(ast)
    refute nil == Block.else_block_for!(ast)
  end

  test "it should return whether an `ast` has a do and/or else block" do
    {:ok, ast} =
      """
      if something? do
        some_action
        IO.puts "HA"
      end
      """
      |> Code.string_to_quoted()

    assert Block.do_block?(ast)
    refute Block.else_block?(ast)
    assert nil == Block.else_block_for!(ast)
  end
end
