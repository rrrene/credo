defmodule Credo.Check.Consistency.SpaceAroundOperatorsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Consistency.SpaceAroundOperators

  @without_spaces """
  defmodule Credo.Sample1 do
    @spec f(<<_::16, _::_*8>>) :: binary
    defmodule InlineModule do
      @min -1
      @max +1
      @type config_or_func :: Config.t() | (-> Config.t())

      def foobar do
        1+2
        |> test1()
        |> test2()
        |> test3()
        |> test4()
      end
    end
     end
  """

  @without_spaces2 """
  defmodule OtherModule3 do
    defmacro foo do
      3+4
    end

    defp bar do
      6*7
    end
  end
  """
  @without_spaces3 """
  defmodule OtherModule4 do
    defp dictionary_changeset() do
      fields = ~W(
        a
        b
      )a
    end
  end
  """
  @with_spaces """
  defmodule Credo.Sample2 do
    defmodule F do
      def f(), do: 1 + 2
      def g(), do: 3 + 1
      def l(), do: [&+/2, &-/2, &*/2, &//2]

      def x do
        entries
        |> Stream.map(&json_library().encode!/1)
        |> Enum.join(".")
      end
    end

    defmodule InlineModule do
      @type config_or_func :: Config.t() | (-> Config.t())

      # Fine
      defp format_value("NPC_", "NPDT", <<skills::binary-27>>) do
        {time, r} = :timer.tc(&unquote(module).unquote(part)/0)
      end

      # Gives warning
      defp format_value("NPC_", "NPDT", <<stuff::integer, other_stuff::integer, even_more_stuff::integer,
        skills::binary-27>>) do


        skip = (SourceFile.column(source_file, line_no, text) || -1) + name_size
      end

      defp parse_image_stats(<< @gif_89_signature,
        width::little-integer-size(16),
        height::little-integer-size(16),
        _remainder::binary >>) do
        %{ filetype: :gif,
          width: width,
          height: height }

        map_fn = &(enum.__struct__).map/2
      end

      def foo do
        <<_, unquoted::binary-size(size), _>> = quoted
        <<data::size(len)-binary, _::binary>>
        <<102::integer-native, rest::binary>>
        <<102::native-integer, rest::binary>>
        <<102::unsigned-big-integer, rest::binary>>
        <<102::unsigned-big-integer-size(8), rest::binary>>
        <<102::unsigned-big-integer-8, rest::binary>>
        <<102::signed-little-float-8, rest::binary>>
        <<min_ver::size(16)-unsigned-integer-little, rest::binary>>
        <<min_ver::size(16)-unsigned-integer-little, rest::binary>>
        <<min_ver::size(16)-unsigned-integer-little, rest::binary>>
        <<min_ver::size(16)-unsigned-integer-little, rest::binary>>
        <<min_ver::size(16)-unsigned-integer-little, rest::binary>>
        <<min_ver::size(16)-unsigned-integer-little, rest::binary>>

        <<102::8-integer-big-unsigned, rest::binary>>
        <<102, rest::binary>>
        << valsize :: 32-unsigned, rest::binary >>
      end

      def error(err_no) do
        case err_no do
          -1 -> :unknown_error
          +2 -> :known_error
          _  -> @error_map[err_no] || err_no
        end
      end

      test "date_add with negative interval" do
        dec = Decimal.new(-1)
        assert [{2013, 1, 1}] = TestRepo.all(from p in Post, select: date_add(p.posted, ^-1, "year"))
        assert [{2013, 1, 1}] = TestRepo.all(from p in Post, select: date_add(p.posted, ^-1.0, "year"))
        assert [{2013, 1, 1}] = TestRepo.all(from p in Post, select: date_add(p.posted, ^dec, "year"))
      end

      def parse_response(<< _correlation_id :: 32-signed, error_code :: 16-signed, generation_id :: 32-signed,
                           protocol_len :: 16-signed, _protocol :: size(protocol_len)-binary,
                           leader_len :: 16-signed, leader :: size(leader_len)-binary,
                           member_id_len :: 16-signed, member_id :: size(member_id_len)-binary,
                           members_size :: 32-signed, rest :: binary >>) do
        members = parse_members(members_size, rest, [])
        %Response{error_code: KafkaEx.Protocol.error(error_code), generation_id: generation_id,
                  leader_id: leader, member_id: member_id, members: members}
      end

      defp int(<< value :: size(valsize)-binary >>, x) do
        case x |> Integer.parse do
          :error -> -1
          {a, _} -> a
        end
      end

      def bar do
        c = n * -1
        c = n + -1
        c = n / -1
        c = n - -1

        [(3 * 4) + (2 / 2) - (-1 * 4) / 1 - 4]
        [(3 * 4) + (2 / 2) - (-1 * 4) / 1 - 4]
        [(3 * 4) + (2 / 2) - (-1 * 4) / 1 - 4]
        |> my_func(&Some.Deep.Module.is_something/1)
      end
    end
  end
  """
  @with_spaces2 """
  defmodule OtherModule3 do
    defmacro foo do
      1 && 2
    end

    defp bar do
      :ok
    end
  end
  """
  @with_spaces3 """
  defmodule OtherModule3 do
    defmacro foo do
      case foo do
        {line_no, line} -> nil
        {line_no, line} ->
          nil
      end
    end
  end
  """
  @with_spaces4 """
  defmodule OtherModule3 do
    @min -1
    @max 2 + 1
    @base_priority_map  %{low: -10, normal: 1, higher: +20}

    def foo(prio) when prio in -999..-1 do
    end

    for prio < -999..0 do
      # something
    end
  end
  """
  @with_spaces5 """
  defmodule CredoTest do
    @moduledoc ""

    def test do
      &String.capitalize/1
      &String.downcase/1
      &String.reverse/1

      [&String.capitalize/1, &String.downcase/1, &String.reverse/1]

      "foo" <> " Add more."
      1 + 1 = 2
    end
  end
  """
  @with_spaces6 """
  assert -24 == MyModule.fun
  assert MyModule.fun !=  -24
  ExUnit.assert -12 == MyApp.fun_that_should_return_a_negative
  """

  @with_spaces7 """
  defmodule AlwaysNoSpacesInBinaryTypespecTest do
    @callback foo() :: <<_::_*8>>

    def foo, do: 1 + 1
  end
  """

  @with_and_without_spaces """
  defmodule OtherModule3 do
    defmacro foo do
      3+4
    end

    defp bar do
      6 *7
    end
  end
  """
  @with_and_without_spaces2 """
  defmodule CredoTests do
  def bar do
  2+3
  4 + 5
  end
  end
  """

  #
  # cases NOT raising issues
  #

  test "it should not report issues when used with sigil" do
    [
      @without_spaces3
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should not report issues if spaces are used everywhere" do
    [
      @with_spaces,
      @with_spaces2,
      @with_spaces3,
      @with_spaces4
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should not report issues if spaces are used everywhere in a single file" do
    [
      @with_spaces5
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should not report issues if spaces are used everywhere in two files" do
    [
      @with_spaces5,
      @with_spaces6
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should not report issues if spaces are omitted everywhere" do
    [
      @without_spaces,
      @without_spaces2
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report an issue for mixed styles /1" do
    [
      @without_spaces,
      @with_spaces,
      @with_spaces2,
      @with_spaces3
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report an issue for mixed styles /2" do
    [
      @without_spaces,
      @with_spaces2,
      @with_spaces2
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report the correct result /4" do
    [
      @with_and_without_spaces
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report the correct result /5" do
    [
      @with_and_without_spaces2
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report the correct result /6" do
    [
      @with_and_without_spaces,
      @with_and_without_spaces2
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report the correct result /7" do
    [
      ~S"""
      defmodule TestTest do
        def test do
          a = fn b, c -> b + c end

          a.(-30, 10)
          a.(-3.0, 1.0)
        end
      end
      """
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should not crash for issue #731" do
    [
      ~S"""
      %{acc | "#{date_type}_dates": :foo}
      """
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should always allow no spaces in binary typespec" do
    [@with_spaces7]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end
end
