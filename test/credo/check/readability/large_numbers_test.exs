defmodule Credo.Check.Readability.LargeNumbersTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.LargeNumbers

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    @budgets %{
      budget1: 100_000,
      budget2: 200_000,
      budget3: 300_000,
      budget4: 500_000,
      budget5: 1_000_000,
      budget6: 2_000_000
    }

    @int32_min -2_147_483_648
    @int32_max  2_147_483_647
    @int64_min -9_223_372_036_854_775_808
    @int64_max  9_223_372_036_854_775_807

    def numbers do
      1024 + 1_000_000 + 11_000 + 22_000 + 33_000
      10_000..20_000
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should allow multiple large floats on a line" do
    """
    def numbers do
      100_000.1 + 5_000_000.2 + 66_000.3
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should not complain about numbers in anon function calls" do
    """
      defmodule Demo.LargeNumberAnonWarning do
        @moduledoc false

        def harmless_function do
          say_num = fn num ->
            IO.inspect num
          end

          say_num.( say_num.(10_000), say_num.(20_000) )
        end
      end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should not complain about non-decimal numbers" do
    """
    def numbers do
      0xFFFF
      0x123456
      0b1111_1111_1111_1111
      0o777_777
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "check old false positive is fixed /1" do
    " defmacro oid_ansi_x9_62, do: quote do: {1,2,840,10_045}"
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "check old false positive is fixed /2" do
    """
    %{
      bounds: [
        0, 1, 2, 5, 10, 20, 30, 65, 85,
        100, 200, 400, 800,
        1_000, 2_000, 4_000, 8_000, 16_000]
    }
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "check old false positive is fixed /3" do
    """
    check all integer <- integer(-10_000..-1) do
      assert is_integer(integer)
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    def numbers do
      1024 + 1000000 + 43534
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report a violation, since it is formatted incorrectly" do
    """
    def numbers do
      1024 + 10_00_00_0 + 43534
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report only one violation" do
    """
    def numbers do
      1024 + 1000000 + 43534
    end
    """
    |> to_source_file
    |> run_check(@described_check, only_greater_than: 50_000)
    |> assert_issue()
  end

  test "it should report only one violation for ranges /1" do
    """
    def numbers do
      10000..20_000
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report only one violation for ranges /2" do
    """
    def numbers do
      10_000..20000
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report only two violation for ranges" do
    """
    def numbers do
      10000..20000
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report a violation /2" do
    """
    defp numbers do
      1024 + 43534
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /3" do
    """
    defp numbers do
      1024 + 43534.0
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /4" do
    """
    defmacro numbers do
      1024 + 1_000000
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should format floating point numbers nicely" do
    """
    def numbers do
      10000.00001
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn %Credo.Issue{message: message} ->
      assert ~r/[\d\._]+/ |> Regex.run(message) |> hd == "10_000.00001"
    end)
  end

  test "it should report all digits from the source" do
    """
    def numbers do
      10000.000010
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn %Credo.Issue{message: message} ->
      assert ~r/[\d\._]+/ |> Regex.run(message) |> hd == "10_000.000010"
    end)
  end

  test "it should detect report issues with multiple large floats on a line" do
    """
    def numbers do
      100_000.1 + 5_000_000.2 + 66000.3
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
