defmodule Credo.Check.Consistency.SpaceAroundOperatorsTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.SpaceAroundOperators

  @without_spaces """
  defmodule Credo.Sample1 do
    defmodule InlineModule do
      @min -1
      @max +1
      @type config_or_func :: Config.t() | (-> Config.t())

      def foobar do
        1+2
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
    defmodule InlineModule do
      @type config_or_func :: Config.t() | (-> Config.t())

      # Fine
      defp format_value("NPC_", "NPDT", <<skills::binary-27>>) do
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

        [1 | 2]

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
    |> refute_issues(@described_check)
  end

  test "it should not report issues if spaces are used everywhere" do
    [
      @with_spaces,
      @with_spaces2,
      @with_spaces3,
      @with_spaces4
    ]
    |> to_source_files()
    |> refute_issues(@described_check)
  end

  test "it should not report issues if spaces are used everywhere in a single file" do
    [
      @with_spaces5
    ]
    |> to_source_files()
    |> refute_issues(@described_check)
  end

  @pipe_op_mixed """
  defmodule CredoTest do
    def test do
      [[3] | 3]
      [[3]|3]
    end
  end
  """

  test "it should not report an issue a according to the pipe_op" do
    [
      @pipe_op_mixed
    ]
    |> to_source_files()
    |> refute_issues(@described_check)
  end

  test "it should not report issues if spaces are omitted everywhere" do
    [
      @without_spaces,
      @without_spaces2
    ]
    |> to_source_files()
    |> refute_issues(@described_check)
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
    |> assert_issue(@described_check)
  end

  test "it should report an issue for mixed styles /2" do
    [
      @without_spaces,
      @with_spaces2,
      @with_spaces2
    ]
    |> to_source_files()
    |> assert_issue(@described_check)
  end

  test "it should report the correct result /4" do
    [
      @with_and_without_spaces
    ]
    |> to_source_files()
    |> assert_issue(@described_check)
  end

  test "it should report the correct result /5" do
    [
      @with_and_without_spaces2
    ]
    |> to_source_files()
    |> assert_issue(@described_check)
  end

  test "it should report the correct result /6" do
    [
      @with_and_without_spaces,
      @with_and_without_spaces2
    ]
    |> to_source_files()
    |> assert_issues(@described_check)
  end
end
