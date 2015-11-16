# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for third-
# party users, it should be done in your mix.exs file.

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

config :bunt, color_aliases: [
                              _category_consistency: :cyan,
                              _category_readability: :blue,
                              _category_design: :olive,
                              _category_refactor: :yellow,
                              _category_warning: :red,
                              _code: :cyan,
                              _explain_code: :yellow
                            ]

config :credo, :category_order, [:design, :readability, :refactor, :warning, :consistency]
config :credo, :category_colors, [
    design: :_category_design,
    readability: :_category_readability,
    refactor: :_category_refactor,
    warning: :_category_warning,
    consistency: :_category_consistency,
  ]
config :credo, :category_titles, [
    design: "Software Design",
    readability: "Code Readability",
    refactor: "Refactoring opportunities",
    warning: "Warnings - please take a look",
    consistency: "Consistency",
  ]

config :credo, :cry_for_help, "Please report incorrect results: https://github.com/rrrene/credo/issues"

config :credo, :base_priority_map, %{ignore: -100, low: -10, normal: 1,
                                                        high: +10, higher: +20}

config :credo, :def_ops, [:def, :defp, :defmacro]

config :credo, :kernel_fun_names, [
  :abs,
  :apply,
  :binary_part,
  :bit_size,
  :byte_size,
  :div,
  :elem,
  :exit,
  :function_exported?,
  :get_and_update_in,
  :get_in,
  :hd,
  :inspect,
  :is_atom,
  :is_binary,
  :is_bitstring,
  :is_boolean,
  :is_float,
  :is_function,
  :is_integer,
  :is_list,
  :is_map,
  :is_number,
  :is_pid,
  :is_port,
  :is_reference,
  :is_tuple,
  :length,
  :macro_exported?,
  :make_ref,
  :map_size,
  :max,
  :min,
  :node,
  :not,
  :put_elem,
  :put_in,
  :rem,
  :round,
  :self,
  :send,
  :spawn,
  :spawn_link,
  :spawn_monitor,
  :struct,
  :throw,
  :tl,
  :trunc,
  :tuple_size,
  :update_in,
]
config :credo, :kernel_macro_names, [
  :alias!,
  :and,
  :binding,
  :def,
  :defdelegate,
  :defexception,
  :defimpl,
  :defmacro,
  :defmacrop,
  :defmodule,
  :defoverridable,
  :defp,
  :defprotocol,
  :defstruct,
  :destructure,
  :get_and_update_in,
  :if,
  :in,
  :is_nil,
  :match?,
  :or,
  :put_in,
  :raise,
  :reraise,
  :sigil_C,
  :sigil_R,
  :sigil_S,
  :sigil_W,
  :sigil_c,
  :sigil_r,
  :sigil_s,
  :sigil_w,
  :to_char_list,
  :to_string,
  :unless,
  :update_in,
  :use,
  :var!,
]
