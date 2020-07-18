defmodule Credo.Code.HeredocsTest do
  use Credo.Test.Case

  alias Credo.Code.Heredocs

  test "it should return the source without string literals 2" do
    source = """
    @moduledoc \"\"\"
    this is an example # TODO: and this is no actual comment
    \"\"\"

    x = ~s{also: # TODO: no comment here}
    ?" # TODO: this is the third
    # "

    "also: # TODO: no comment here as well"
    """

    expected =
      """
      @moduledoc \"\"\"
      @@EMPTY_STRING@@
      \"\"\"

      x = ~s{also: # TODO: no comment here}
      ?" # TODO: this is the third
      # "

      "also: # TODO: no comment here as well"
      """
      |> String.replace(
        "@@EMPTY_STRING@@",
        "                                                        "
      )

    assert expected == source |> Heredocs.replace_with_spaces()
  end

  test "it should return the source without string sigils 2" do
    source = """
      should "not error for a quote in a heredoc" do
        errors = ~s(
        \"\"\"
    this is an example " TODO: and this is no actual comment
        \"\"\") |> lint
        assert [] == errors
      end
    """

    result = source |> Heredocs.replace_with_spaces()
    assert source == result
  end

  test "it should work with nested heredocs" do
    source = """
    defmodule HereDocDemo do
      @doc ~S'''
      José suggested using an outer sigil so the inner sigil was more normal in the documentation

        ~E\"\"\"
        but Credo didn't like it at all
        \"\"\"
      '''
      def demo, do: :ok
    end
    """

    expected = """
    defmodule HereDocDemo do
      @doc ~S'''
      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

      @@@@@@@
      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      @@@@@
      '''
      def demo, do: :ok
    end
    """

    assert expected == Heredocs.replace_with_spaces(source, "@")
  end

  test "it should return the source without string literals 3" do
    source = """
    x =   "↑ ↗ →"
    x = ~s|text|
    x = ~s"text"
    x = ~s'text'
    x = ~s(text)
    x = ~s[text]
    x = ~s{text}
    x = ~s<text>
    x = ~S|text|
    x = ~S"text"
    x = ~S'text'
    x = ~S(text)
    x = ~S[text]
    x = ~S{text}
    x = ~S<text>
    ?" # <-- this is not a string
    """

    assert source == source |> Heredocs.replace_with_spaces()
  end

  test "it should return the source without string sigils and replace the contents" do
    source = """
    t = ~S\"\"\"
    abc
    \"\"\"
    """

    expected = """
    t = ~S\"\"\"
    ...
    \"\"\"
    """

    result = source |> Heredocs.replace_with_spaces(".")
    assert expected == result
  end

  test "it should return the source without the strings and replace the contents" do
    source = """
      t = ~S\"\"\"
      abc
      我是中國人
      \"\"\"
    """

    expected = """
      t = ~S\"\"\"
      ...
      .....
      \"\"\"
    """

    result = source |> Heredocs.replace_with_spaces(".")
    assert expected == result
  end

  test "it should NOT report expected code /2" do
    source = ~S"""
    defmodule CredoSampleModule do
      def escape_subsection(""), do: "\"\""

      def escape_subsection(x) when is_binary(x) do
        x
        |> String.to_charlist()
        |> escape_subsection_impl([])
        |> Enum.reverse()
        |> to_quoted_string()
      end

      defp to_quoted_string(s), do: ~s["test string"]

      # git-config(1) lists the limited set of supported escape sequences
      # (which is even more limited for subsection names than for values).

      defp escape_subsection_impl([], reversed_result), do: reversed_result

      defp escape_subsection_impl([0 | _], _reversed_result),
        do: raise(ConfigInvalidError, "config subsection name contains byte 0x00")

      defp escape_subsection_impl([?\n | _], _reversed_result),
        do: raise(ConfigInvalidError, "config subsection name contains newline")

      defp escape_subsection_impl([c | remainder], reversed_result)
           when c == ?\\ or c == ?",
           do: escape_subsection_impl(remainder, [c | [?\\ | reversed_result]])

      defp escape_subsection_impl([c | remainder], reversed_result),
        do: escape_subsection_impl(remainder, [c | reversed_result])

    end
    """

    expected = source

    assert expected == Heredocs.replace_with_spaces(source)
  end

  test "it should return the source without string sigils and replace the contents including interpolation" do
    source = """
    def fun() do
      a = \"\"\"
      MyModule.\#{fun(Module.value() + 1)}.SubModule.\#{name}"
      \"\"\"
    end
    """

    expected = """
    def fun() do
      a = \"\"\"
      ......................................................
      \"\"\"
    end
    """

    result = source |> Heredocs.replace_with_spaces(".")
    assert expected == result
  end

  test "it should not modify commented out code" do
    source = """
    defmodule Foo do
      defmodule Bar do
        # @doc \"\"\"
        # Reassign a student to a discussion group.
        # This will un-assign student from the current discussion group
        # \"\"\"
        # def assign_group(leader = %User{}, student = %User{}) do
        #   cond do
        #     leader.role == :student ->
        #       {:error, :invalid}
        #
        #     student.role != :student ->
        #       {:error, :invalid}
        #
        #     true ->
        #       Repo.transaction(fn ->
        #         {:ok, _} = unassign_group(student)
        #
        #         %Group{}
        #         |> Group.changeset(%{})
        #         |> put_assoc(:leader, leader)
        #         |> put_assoc(:student, student)
        #         |> Repo.insert!()
        #       end)
        #   end
        # end
        def baz, do: 123
      end
    end
    """

    expected = source

    assert expected == source |> Heredocs.replace_with_spaces(".")
  end

  test "it should overwrite whitespace in heredocs" do
    source =
      """
      defmodule CredoSampleModule do
        @doc '''
        Foo++
        Bar
        '''
      end
      """
      |> String.replace("++", "  ")

    expected = """
    defmodule CredoSampleModule do
      @doc '''
      .....
      ...
      '''
    end
    """

    assert expected == source |> Heredocs.replace_with_spaces(".")
  end

  @tag slow: :disk_io
  test "it should produce valid code" do
    example_code = File.read!("test/fixtures/example_code/clean_redux.ex")
    result = Heredocs.replace_with_spaces(example_code)
    result2 = Heredocs.replace_with_spaces(result)

    assert result == result2, "Heredocs.replace_with_spaces/2 should be idempotent"
    assert match?({:ok, _}, Code.string_to_quoted(result))
  end

  @tag slow: :disk_io
  test "it should produce valid code /2" do
    example_code = File.read!("test/fixtures/example_code/nested_escaped_heredocs.ex")
    result = Heredocs.replace_with_spaces(example_code)
    result2 = Heredocs.replace_with_spaces(result)

    assert result == result2, "Heredocs.replace_with_spaces/2 should be idempotent"
    assert match?({:ok, _}, Code.string_to_quoted(result))
  end

  test "it should return the source without the strings and replace the contents /2" do
    source = ~S'''
    defmodule Quora.Issues.Issue do
      @moduledoc """
      工单模型
      """
      use Ecto.Schema
      import Ecto.{Changeset, Query}
      import HljUtil.Util
      import Quora.Utils.AASM

      alias Quora.{
        Repo,
        Site,
        Issues,
        Version
      }

      alias Quora.Utils.DateUtil
      alias Version.Footprint
      alias Site.{User, Tag}
      alias Issues.Issue

      @type t :: %Issue{}

      schema "issues" do
        field(:code, :string)
        field(:title, :string)
        field(:description, :string)
        field(:reason, :string)
        field(:solution, :string)
        field(:remark, :string)
        field(:state, :string, default: "created")
        field(:assigned_reason, :string)
        field(:assigned_at, :naive_datetime)
        field(:due_date, :naive_datetime)
        field(:closed_time, :naive_datetime)
        field(:operator_id, :integer, virtual: true)
        field(:base_reason, :string)
        field(:influenced, :string)
        field(:punishment, :string)
        field(:improvement, :string)
        field(:level, :string)

        timestamps()

        belongs_to(:author, User)
        belongs_to(:assignee, User)
        belongs_to(:bug_creator, User)
        has_many(:footprints, Footprint, foreign_key: :item_id)
        many_to_many(:tags, Tag, join_through: "issues_tags", on_replace: :delete)
      end

      # created     新建
      # assigned    已指派
      # finished    该问题已解决
      # coe_report  已发 COE 报告
      # closed      关闭问题
      aasm :state do
        defstate(~w(created assigned finished coe_report closed)a)

        # 设置为已指派
        defevent(:handle_assigned, %{from: ~w(created)a, to: :assigned}, fn changeset ->
          changeset |> Version.update()
        end)

        # 设置问题已解决
        defevent(:handle_finished, %{from: ~w(assigned)a, to: :finished}, fn changeset ->
          changeset |> Version.update()
        end)

        # 设置状态为 COE 报告已发
        defevent(:handle_coe_report, %{from: ~w(finished)a, to: :coe_report}, fn changeset ->
          changeset |> Version.update()
        end)

        # 设置 issue 关闭, 不限制状态，所有状态下都可以关闭。
        defevent(
          :handle_closed,
          %{from: ~w(created assigned finished coe_report)a, to: :closed},
          fn changeset -> changeset |> Version.update() end
        )
      end

      def state_names do
        %{
          created: "新问题",
          assigned: "已指派",
          finished: "已解决",
          coe_report: "已复盘",
          closed: "已关闭"
        }
      end

      def state_name(issue) do
        state_names()
        |> Map.get(String.to_atom(issue.state), "新问题")
      end

      @doc """
      Preloads all of a issue.
      """
      @spec preload_all(t()) :: t()
      def preload_all(issue) do
        Repo.preload(issue, [:author, :assignee, :tags, :bug_creator])
      end

      @doc ~S"""
      `Issue` 搜索集
      """
      @spec build_query(Ecto.Query.t(), Map.t()) :: Ecto.Query.t()
      def build_query(base \\ __MODULE__, params) do
        params
        |> Enum.filter(fn {_, v} -> byte_size(to_string(v)) != 0 end)
        |> Enum.reduce(base, fn {name, value}, acc ->
          query_by(acc, String.to_atom(name), value)
        end)
      end

      defp query_by(query, :query, term) do
        query
        |> where([i, ...], like(i.code, ^"%#{term}%"))
        |> or_where([i, ...], like(i.description, ^"%#{term}%"))
      end

      defp query_by(query, :author, author_id) do
        where(query, [i, ...], i.author_id == ^author_id)
      end

      defp query_by(query, :state, state) do
        where(query, [i, ...], i.state == ^state)
      end

      defp query_by(query, :tag, tag_id) do
        from(i in query,
          join: tag in assoc(i, :tags),
          where: tag.id == ^tag_id
        )
      end

      defp query_by(query, :created, time) do
        {from, to} = DateUtil.parse_range(time, naive: true)

        query
        |> either(from, fn base -> where(base, [i, ...], i.inserted_at > ^from) end)
        |> either(to, fn base -> where(base, [i, ...], i.inserted_at < ^to) end)
      end

      defp query_by(query, _, _), do: query

      @doc """
      Changeset
      """
      def changeset(issue, attrs \\ %{}) do
        permitted_attrs = ~w(
          code
          title
          description
          state
          reason
          solution
          base_reason
          influenced
          punishment
          improvement
          operator_id
          assigned_reason
          assigned_at
          bug_creator_id
          remark
          due_date
          closed_time
          author_id
          assignee_id
          level
        )a

        required_attrs = ~w(
          code
          author_id
        )a

        issue
        |> cast(attrs, permitted_attrs)
        |> validate_required(required_attrs)
        |> assoc_tags(attrs["tags"])
        |> assoc_constraint(:author)
        |> assoc_constraint(:assignee)
      end

      defp assoc_tags(changeset, nil), do: changeset

      defp assoc_tags(changeset, ids) when is_list(ids) do
        tags =
          ids
          |> Enum.map(&parse_int/1)
          |> Enum.filter(& &1)
          |> Tag.get_by_ids()

        put_assoc(changeset, :tags, tags)
      end

      defp either(ctx, check, inner) do
        if check, do: inner.(ctx), else: ctx
      end
    end
    '''

    expected = ~S'''
    defmodule Quora.Issues.Issue do
      @moduledoc """
      ....
      """
      use Ecto.Schema
      import Ecto.{Changeset, Query}
      import HljUtil.Util
      import Quora.Utils.AASM

      alias Quora.{
        Repo,
        Site,
        Issues,
        Version
      }

      alias Quora.Utils.DateUtil
      alias Version.Footprint
      alias Site.{User, Tag}
      alias Issues.Issue

      @type t :: %Issue{}

      schema "issues" do
        field(:code, :string)
        field(:title, :string)
        field(:description, :string)
        field(:reason, :string)
        field(:solution, :string)
        field(:remark, :string)
        field(:state, :string, default: "created")
        field(:assigned_reason, :string)
        field(:assigned_at, :naive_datetime)
        field(:due_date, :naive_datetime)
        field(:closed_time, :naive_datetime)
        field(:operator_id, :integer, virtual: true)
        field(:base_reason, :string)
        field(:influenced, :string)
        field(:punishment, :string)
        field(:improvement, :string)
        field(:level, :string)

        timestamps()

        belongs_to(:author, User)
        belongs_to(:assignee, User)
        belongs_to(:bug_creator, User)
        has_many(:footprints, Footprint, foreign_key: :item_id)
        many_to_many(:tags, Tag, join_through: "issues_tags", on_replace: :delete)
      end

      # created     新建
      # assigned    已指派
      # finished    该问题已解决
      # coe_report  已发 COE 报告
      # closed      关闭问题
      aasm :state do
        defstate(~w(created assigned finished coe_report closed)a)

        # 设置为已指派
        defevent(:handle_assigned, %{from: ~w(created)a, to: :assigned}, fn changeset ->
          changeset |> Version.update()
        end)

        # 设置问题已解决
        defevent(:handle_finished, %{from: ~w(assigned)a, to: :finished}, fn changeset ->
          changeset |> Version.update()
        end)

        # 设置状态为 COE 报告已发
        defevent(:handle_coe_report, %{from: ~w(finished)a, to: :coe_report}, fn changeset ->
          changeset |> Version.update()
        end)

        # 设置 issue 关闭, 不限制状态，所有状态下都可以关闭。
        defevent(
          :handle_closed,
          %{from: ~w(created assigned finished coe_report)a, to: :closed},
          fn changeset -> changeset |> Version.update() end
        )
      end

      def state_names do
        %{
          created: "新问题",
          assigned: "已指派",
          finished: "已解决",
          coe_report: "已复盘",
          closed: "已关闭"
        }
      end

      def state_name(issue) do
        state_names()
        |> Map.get(String.to_atom(issue.state), "新问题")
      end

      @doc """
      ........................
      """
      @spec preload_all(t()) :: t()
      def preload_all(issue) do
        Repo.preload(issue, [:author, :assignee, :tags, :bug_creator])
      end

      @doc ~S"""
      ...........
      """
      @spec build_query(Ecto.Query.t(), Map.t()) :: Ecto.Query.t()
      def build_query(base \\ __MODULE__, params) do
        params
        |> Enum.filter(fn {_, v} -> byte_size(to_string(v)) != 0 end)
        |> Enum.reduce(base, fn {name, value}, acc ->
          query_by(acc, String.to_atom(name), value)
        end)
      end

      defp query_by(query, :query, term) do
        query
        |> where([i, ...], like(i.code, ^"%       %"))
        |> or_where([i, ...], like(i.description, ^"%       %"))
      end

      defp query_by(query, :author, author_id) do
        where(query, [i, ...], i.author_id == ^author_id)
      end

      defp query_by(query, :state, state) do
        where(query, [i, ...], i.state == ^state)
      end

      defp query_by(query, :tag, tag_id) do
        from(i in query,
          join: tag in assoc(i, :tags),
          where: tag.id == ^tag_id
        )
      end

      defp query_by(query, :created, time) do
        {from, to} = DateUtil.parse_range(time, naive: true)

        query
        |> either(from, fn base -> where(base, [i, ...], i.inserted_at > ^from) end)
        |> either(to, fn base -> where(base, [i, ...], i.inserted_at < ^to) end)
      end

      defp query_by(query, _, _), do: query

      @doc """
      .........
      """
      def changeset(issue, attrs \\ %{}) do
        permitted_attrs = ~w(
          code
          title
          description
          state
          reason
          solution
          base_reason
          influenced
          punishment
          improvement
          operator_id
          assigned_reason
          assigned_at
          bug_creator_id
          remark
          due_date
          closed_time
          author_id
          assignee_id
          level
        )a

        required_attrs = ~w(
          code
          author_id
        )a

        issue
        |> cast(attrs, permitted_attrs)
        |> validate_required(required_attrs)
        |> assoc_tags(attrs["tags"])
        |> assoc_constraint(:author)
        |> assoc_constraint(:assignee)
      end

      defp assoc_tags(changeset, nil), do: changeset

      defp assoc_tags(changeset, ids) when is_list(ids) do
        tags =
          ids
          |> Enum.map(&parse_int/1)
          |> Enum.filter(& &1)
          |> Tag.get_by_ids()

        put_assoc(changeset, :tags, tags)
      end

      defp either(ctx, check, inner) do
        if check, do: inner.(ctx), else: ctx
      end
    end
    '''

    result = source |> Heredocs.replace_with_spaces(".")
    assert expected == result
  end

  test "should treat heredoc sigils correctly (issue #732)" do
    foo = """
    defmodule InflictParserError do
      @moduledoc false

      def a_method do
        ~S(")
        ~S(])
        ~S([)
      end

      @doc \"\"\"
      \"\"\"
      def another_method, do: nil
    end
    """

    assert foo ==
             foo
             |> to_source_file
             |> Heredocs.replace_with_spaces()
  end
end
