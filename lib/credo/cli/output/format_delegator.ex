defmodule Credo.CLI.Output.FormatDelegator do
  @moduledoc """
  This module can be used to easily delegate print-statements for different
  formats to different modules.

  Example:

      use Credo.CLI.Output.FormatDelegator,
        default: Credo.CLI.Command.Suggest.Output.Default,
        flycheck: Credo.CLI.Command.Suggest.Output.FlyCheck,
        oneline: Credo.CLI.Command.Suggest.Output.Oneline,
        json: Credo.CLI.Command.Suggest.Output.Json

  """

  @doc false
  defmacro __using__(format_list) do
    format_mods =
      Enum.map(format_list, fn {format, output_mod} ->
        case format do
          :default ->
            quote do
            end

          _ ->
            quote do
              defp format_mod(%Execution{format: unquote(to_string(format))}) do
                unquote(output_mod)
              end
            end
        end
      end)

    default_format_mod =
      Enum.map(format_list, fn {format, output_mod} ->
        case format do
          :default ->
            quote do
              defp format_mod(_) do
                unquote(output_mod)
              end
            end

          _ ->
            quote do
            end
        end
      end)

    quote do
      alias Credo.Execution

      def print_before_info(source_files, exec) do
        format_mod = format_mod(exec)

        format_mod.print_before_info(source_files, exec)
      end

      def print_after_info(source_files, exec, time_load, time_run) do
        format_mod = format_mod(exec)

        format_mod.print_after_info(source_files, exec, time_load, time_run)
      end

      unquote(format_mods)

      unquote(default_format_mod)
    end
  end
end
