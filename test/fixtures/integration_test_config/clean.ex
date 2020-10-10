# Copyright (C) 2010, Mathias Kinzler <mathias.kinzler@sap.com>
# Copyright (C) 2009, Constantine Plotnikov <constantine.plotnikov@gmail.com>
# Copyright (C) 2007, Dave Watson <dwatson@mimvista.com>
# Copyright (C) 2008-2010, Google Inc.
# Copyright (C) 2009, Google, Inc.
# Copyright (C) 2009, JetBrains s.r.o.
# Copyright (C) 2007-2008, Robin Rosenberg <robin.rosenberg@dewire.com>
# Copyright (C) 2006-2008, Shawn O. Pearce <spearce@spearce.org>
# Copyright (C) 2008, Thad Hughes <thadh@thad.corp.google.com>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/Config.java
#
# Copyright (C) 2019, Eric Scouten <eric+xgit@scouten.com>
#
# This program and the accompanying materials are made available
# under the terms of the Eclipse Distribution License v1.0 which
# accompanies this distribution, is reproduced below, and is
# available at http://www.eclipse.org/org/documents/edl-v10.php
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# - Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above
#   copyright notice, this list of conditions and the following
#   disclaimer in the documentation and/or other materials provided
#   with the distribution.
#
# - Neither the name of the Eclipse Foundation, Inc. nor the
#   names of its contributors may be used to endorse or promote
#   products derived from this software without specific prior
#   written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

defmodule Xgit.Lib.Config do
  @moduledoc ~S"""
  Git-style `.config`, `.gitconfig`, `.gitmodules` file.

  INCOMPLETE IMPLEMENTATION: The following features have not yet been ported from jgit:

  * parsing time units
  * change notification
  * include file support
  * a few edge cases

  TO DO: https://github.com/elixir-git/xgit/issues/129

  PORTING NOTE: Xgit does not have explicit enum support, unlike jgit. There is very
  little about the various `ConfigEnum` implementations that is sharable, so it did
  not seem worth it to port that mechanism. Xgit instead stores the enum values
  directly as strings. Some one-off modules may provide additional support for
  recognizing known strings or variants.
  """
  @enforce_keys [:config_pid]
  defstruct [:config_pid, :storage]

  @type t :: %__MODULE__{}

  use GenServer

  alias Xgit.Errors.ConfigInvalidError
  alias Xgit.Lib.ConfigLine

  defmodule State do
    @moduledoc false
    @enforce_keys [:config_lines, :base_config]
    defstruct [:config_lines, :base_config]
  end

  @kib 1024
  @mib 1024 * @kib
  @gib 1024 * @mib

  @doc ~S"""
  Create a configuration with no default fallback.

  Options:
  * `base_config`: A base configuration to be consulted when a key is
    missing from this configuration instance.
  * `storage`: Ties this configuration to a storage approach.
  """
  def new(options \\ []) when is_list(options) do
    base_config =
      case Keyword.get(options, :base_config, nil) do
        nil -> nil
        %__MODULE__{} = config -> config
        x -> raise ArgumentError, message: "Illegal base_config value: #{inspect(x)}"
      end

    {:ok, pid} = GenServer.start_link(__MODULE__, base_config)

    %__MODULE__{config_pid: pid, storage: Keyword.get(options, :storage, nil)}
  end

  @impl true
  def init(base_config) do
    {:ok, %__MODULE__.State{config_lines: [], base_config: base_config}}
  end

  @doc ~S"""
  Escape the value before saving.
  """
  def escape_value(""), do: ""

  def escape_value(s) when is_binary(s) do
    need_quote? = String.starts_with?(s, " ") || String.ends_with?(s, " ")

    {rr, need_quote?} = escape_charlist([], String.to_charlist(s), need_quote?)

    maybe_quote =
      if need_quote?,
        do: "\"",
        else: ""

    "#{maybe_quote}#{rr |> Enum.reverse() |> to_string()}#{maybe_quote}"
  end

  # git-config(1) lists the limited set of supported escape sequences, but
  # the documentation is otherwise not especially normative. In particular,
  # which ones of these produce and/or require escaping and/or quoting
  # around them is not documented and was discovered by trial and error.
  # In summary:
  #
  # * Quotes are only required if there is leading/trailing whitespace or a
  #   comment character.
  # * Bytes that have a supported escape sequence are escaped, except for
  #   `\b` for some reason which isn't.
  # * Needing an escape sequence is not sufficient reason to quote the
  #   value.
  defp escape_charlist(reversed_result, remaining_charlist, need_quote?)

  defp escape_charlist(reversed_result, [], need_quote?), do: {reversed_result, need_quote?}

  # Unix command line calling convention cannot pass a `\0` as an
  # argument, so there is no equivalent way in C git to store a null byte
  # in a config value.
  defp escape_charlist(_, [0 | _], _),
    do: raise(ConfigInvalidError, "config value contains byte 0x00")

  defp escape_charlist(reversed_result, [?\n | remainder], needs_quote?),
    do: escape_charlist('n\\' ++ reversed_result, remainder, needs_quote?)

  defp escape_charlist(reversed_result, [?\t | remainder], needs_quote?),
    do: escape_charlist('t\\' ++ reversed_result, remainder, needs_quote?)

  # Doesn't match `git config foo.bar $'x\by'`, which doesn't escape the
  # \x08, but since both escaped and unescaped forms are readable, we'll
  # prefer internal consistency here.
  defp escape_charlist(reversed_result, [?\b | remainder], needs_quote?),
    do: escape_charlist('b\\' ++ reversed_result, remainder, needs_quote?)

  defp escape_charlist(reversed_result, [?\\ | remainder], needs_quote?),
    do: escape_charlist('\\\\' ++ reversed_result, remainder, needs_quote?)

  defp escape_charlist(reversed_result, [?" | remainder], needs_quote?),
    do: escape_charlist('"\\' ++ reversed_result, remainder, needs_quote?)

  defp escape_charlist(reversed_result, [c | remainder], _needs_quote?)
       when c == ?# or c == ?;,
       do: escape_charlist([c | reversed_result], remainder, true)

  defp escape_charlist(reversed_result, [c | remainder], needs_quote?),
    do: escape_charlist([c | reversed_result], remainder, needs_quote?)

  @doc ~S"""
  Escape a subsection name before saving.
  """
  def escape_subsection(""), do: "\"\""

  def escape_subsection(x) when is_binary(x) do
    x
    |> String.to_charlist()
    |> escape_subsection_impl([])
    |> Enum.reverse()
    |> to_quoted_string()
  end

  defp to_quoted_string(s), do: ~s["#{s}"]

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

  @doc ~S"""
  Get an integer value from the git config.

  If no value was present, returns `default`.
  """
  def get_int(config, section, subsection \\ nil, name, default)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) and is_integer(default) do
    config
    |> config_pid()
    |> GenServer.call({:get_raw_strings, section, subsection, name})
    |> replace_empty_with_missing()
    |> List.last()
    |> to_lowercase_if_string()
    |> trim_if_string()
    |> to_number(section, name, default)
  end

  defp replace_empty_with_missing([]), do: [:missing]
  defp replace_empty_with_missing(x), do: x

  defp to_lowercase_if_string(s) when is_binary(s), do: String.downcase(s)
  defp to_lowercase_if_string(x), do: x

  defp trim_if_string(s) when is_binary(s), do: String.trim(s)
  defp trim_if_string(x), do: x

  defp to_number(:missing, _section, _name, default), do: default
  defp to_number(nil, _section_, _name, default), do: default
  defp to_number("", _section, _name, default), do: default

  defp to_number(s, section, name, _default) do
    case parse_integer_and_strip_whitespace(s) do
      {n, "g"} -> n * @gib
      {n, "m"} -> n * @mib
      {n, "k"} -> n * @kib
      {n, ""} -> n
      _ -> raise(ConfigInvalidError, "Invalid integer value: #{section}.#{name}=#{s}")
    end
  end

  defp parse_integer_and_strip_whitespace(s) do
    case Integer.parse(s) do
      {n, str} -> {n, String.trim(str)}
      x -> x
    end
  end

  @doc ~S"""
  Get a boolean value from the git config.

  Returns `true` if any value or `default` if `true`; `false` for missing or
  an explicit `false`.
  """
  def get_boolean(config, section, subsection \\ nil, name, default)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) and is_boolean(default) do
    config
    |> config_pid()
    |> GenServer.call({:get_raw_strings, section, subsection, name})
    |> replace_empty_with_missing()
    |> List.last()
    |> to_lowercase_if_string()
    |> to_boolean(default)
  end

  defp to_boolean(nil, _default), do: true
  defp to_boolean(:empty, _default), do: true
  defp to_boolean("false", _default), do: false
  defp to_boolean("no", _default), do: false
  defp to_boolean("off", _default), do: false
  defp to_boolean("0", _default), do: false
  defp to_boolean(_, _default), do: true

  @doc ~S"""
  Get a single string value from the git config (or `nil` if not found).
  """
  def get_string(config, section, subsection \\ nil, name)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) do
    config
    |> config_pid()
    |> GenServer.call({:get_raw_strings, section, subsection, name})
    |> replace_empty_with_missing()
    |> List.last()
    |> fix_missing_or_nil_string_result()
  end

  defp fix_missing_or_nil_string_result(:missing), do: nil
  defp fix_missing_or_nil_string_result(:empty), do: ""
  defp fix_missing_or_nil_string_result(nil), do: ""
  defp fix_missing_or_nil_string_result(x), do: to_string(x)

  @doc ~S"""
  Get a list of string values from the git config.

  If this instance was created with a base, the base's values (if any) are
  returned first.
  """
  def get_string_list(config, section, subsection \\ nil, name)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) do
    config
    |> config_pid()
    |> GenServer.call({:get_raw_strings, section, subsection, name})
    |> Enum.map(&fix_missing_or_nil_string_result/1)
  end

  # /**
  #  * Parse a numerical time unit, such as "1 minute", from the configuration.
  #  *
  #  * @param section
  #  *            section the key is in.
  #  * @param subsection
  #  *            subsection the key is in, or null if not in a subsection.
  #  * @param name
  #  *            the key name.
  #  * @param defaultValue
  #  *            default value to return if no value was present.
  #  * @param wantUnit
  #  *            the units of {@code defaultValue} and the return value, as
  #  *            well as the units to assume if the value does not contain an
  #  *            indication of the units.
  #  * @return the value, or {@code defaultValue} if not set, expressed in
  #  *         {@code units}.
  #  * @since 4.5
  #  */
  # public long getTimeUnit(String section, String subsection, String name,
  # 		long defaultValue, TimeUnit wantUnit) {
  # 	return typedGetter.getTimeUnit(this, section, subsection, name,
  # 			defaultValue, wantUnit);
  # }
  #
  # /**
  #  * Parse a list of {@link org.eclipse.jgit.transport.RefSpec}s from the
  #  * configuration.
  #  *
  #  * @param section
  #  *            section the key is in.
  #  * @param subsection
  #  *            subsection the key is in, or null if not in a subsection.
  #  * @param name
  #  *            the key name.
  #  * @return a possibly empty list of
  #  *         {@link org.eclipse.jgit.transport.RefSpec}s
  #  * @since 4.9
  #  */
  # public List<RefSpec> getRefSpecs(String section, String subsection,
  # 		String name) {
  # 	return typedGetter.getRefSpecs(this, section, subsection, name);
  # }

  @doc ~S"""
  Get set of all subsections of specified section within this configuration
  and its base configuration.
  """
  def subsections(config, section) when is_binary(section),
    do: config |> config_pid() |> GenServer.call({:subsections, section})

  # IMPORTANT: subsections_impl/2 runs in GenServer process.
  # See handle_call/3 below.

  defp subsections_impl(config_lines, section) do
    config_lines
    |> Enum.filter(&(&1.section == section))
    |> Enum.map(& &1.subsection)
    |> Enum.dedup()

    # TBD: Dedup globally?
  end

  @doc ~S"""
  Get the sections defined in this `Config`.
  """
  def sections(config), do: config |> config_pid() |> GenServer.call(:sections)

  # IMPORTANT: sections_impl/1 runs in GenServer process.
  # See handle_call/3 below.

  defp sections_impl(config_lines) do
    config_lines
    |> Enum.reject(&(&1.section == nil))
    |> Enum.map(&String.downcase(&1.section))
    |> Enum.dedup()

    # TBD: Dedup globally?
  end

  @doc ~S"""
  Get the list of names defined for this section.

  Options:
  * `recursive`: Include matching names from base config.
  """
  def names_in_section(config, section, options \\ [])
      when is_binary(section) and is_list(options),
      do: config |> config_pid() |> GenServer.call({:names_in_section, section, options})

  # IMPORTANT: names_in_section_impl/4 runs in GenServer process.
  # See handle_call/3 below.

  defp names_in_section_impl(config_lines, section, base_config, options) do
    config_lines
    |> Enum.filter(&(&1.section == section))
    |> Enum.reject(&(&1.name == nil))
    |> Enum.map(&String.downcase(&1.name))
    |> Enum.dedup()
    |> names_in_section_recurse(section, base_config, Keyword.get(options, :recursive, false))

    # TBD: Dedup globally?
  end

  defp names_in_section_recurse(names, _section, _base_config, false), do: names
  defp names_in_section_recurse(names, _section, nil, _recursive), do: names

  defp names_in_section_recurse(names, section, base_config, _recursive),
    do: names ++ names_in_section(base_config, section, recursive: true)

  @doc ~S"""
  Get the list of names defined for this subsection.

  Options:
  * `recursive`: Include matching names from base config.
  """
  def names_in_subsection(config, section, subsection, options \\ [])
      when is_binary(section) and is_binary(subsection) and is_list(options),
      do:
        config
        |> config_pid()
        |> GenServer.call({:names_in_subsection, section, subsection, options})

  # IMPORTANT: names_in_subsection_impl/5 runs in GenServer process.
  # See handle_call/3 below.

  defp names_in_subsection_impl(config_lines, section, subsection, base_config, options) do
    config_lines
    |> Enum.filter(&(&1.section == section && &1.subsection == subsection))
    |> Enum.reject(&(&1.name == nil))
    |> Enum.map(&String.downcase(&1.name))
    |> Enum.dedup()
    |> names_in_subsection_recurse(
      section,
      subsection,
      base_config,
      Keyword.get(options, :recursive, false)
    )

    # TBD: Dedup globally?
  end

  defp names_in_subsection_recurse(names, _section, _subsection, _base_config, false), do: names
  defp names_in_subsection_recurse(names, _section, _subsection, nil, _recursive), do: names

  defp names_in_subsection_recurse(names, section, subsection, base_config, _recursive),
    do: names ++ names_in_subsection(base_config, section, subsection, recursive: true)

  # /**
  #  * Obtain a handle to a parsed set of configuration values.
  #  *
  #  * @param <T>
  #  *            type of configuration model to return.
  #  * @param parser
  #  *            parser which can create the model if it is not already
  #  *            available in this configuration file. The parser is also used
  #  *            as the key into a cache and must obey the hashCode and equals
  #  *            contract in order to reuse a parsed model.
  #  * @return the parsed object instance, which is cached inside this config.
  #  */
  # @SuppressWarnings("unchecked")
  # public <T> T get(SectionParser<T> parser) {
  # 	final ConfigSnapshot myState = getState();
  # 	T obj = (T) myState.cache.get(parser);
  # 	if (obj == null) {
  # 		obj = parser.parse(this);
  # 		myState.cache.put(parser, obj);
  # 	}
  # 	return obj;
  # }
  #
  # /**
  #  * Remove a cached configuration object.
  #  * <p>
  #  * If the associated configuration object has not yet been cached, this
  #  * method has no effect.
  #  *
  #  * @param parser
  #  *            parser used to obtain the configuration object.
  #  * @see #get(SectionParser)
  #  */
  # public void uncache(SectionParser<?> parser) {
  # 	state.get().cache.remove(parser);
  # }
  #
  # /**
  #  * Adds a listener to be notified about changes.
  #  * <p>
  #  * Clients are supposed to remove the listeners after they are done with
  #  * them using the {@link org.eclipse.jgit.events.ListenerHandle#remove()}
  #  * method
  #  *
  #  * @param listener
  #  *            the listener
  #  * @return the handle to the registered listener
  #  */
  # public ListenerHandle addChangeListener(ConfigChangedListener listener) {
  # 	return listeners.addConfigChangedListener(listener);
  # }
  #
  # /**
  #  * Determine whether to issue change events for transient changes.
  #  * <p>
  #  * If <code>true</code> is returned (which is the default behavior),
  #  * {@link #fireConfigChangedEvent()} will be called upon each change.
  #  * <p>
  #  * Subclasses that override this to return <code>false</code> are
  #  * responsible for issuing {@link #fireConfigChangedEvent()} calls
  #  * themselves.
  #  *
  #  * @return <code></code>
  #  */
  # protected boolean notifyUponTransientChanges() {
  # 	return true;
  # }
  #
  # /**
  #  * Notifies the listeners
  #  */
  # protected void fireConfigChangedEvent() {
  # 	listeners.dispatch(new ConfigChangedEvent());
  # }

  defp raw_string_list(
         %__MODULE__.State{base_config: base_config, config_lines: config_lines},
         section,
         subsection,
         name
       ) do
    base_strings =
      if base_config != nil,
        do: get_string_list(base_config, section, subsection, name),
        else: []

    self_strings =
      config_lines
      |> Enum.filter(&ConfigLine.match?(&1, section, subsection, name))
      |> Enum.map(fn %ConfigLine{value: value} -> value end)

    base_strings ++ self_strings
  end

  # private ConfigSnapshot getState() {
  # 	ConfigSnapshot cur, upd;
  # 	do {
  # 		cur = state.get();
  # 		final ConfigSnapshot base = getBaseState();
  # 		if (cur.baseState == base)
  # 			return cur;
  # 		upd = new ConfigSnapshot(cur.entryList, base);
  # 	} while (!state.compareAndSet(cur, upd));
  # 	return upd;
  # }
  #
  # private ConfigSnapshot getBaseState() {
  # 	return baseConfig != null ? baseConfig.getState() : null;
  # }

  @doc ~s"""
  Add or modify a configuration value. The parameters will result in a
  configuration entry like this:

  ```
  [section "subsection"]
    name = value
  ```
  """
  def set_int(config, section, subsection \\ nil, name, value)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) and is_integer(value) do
    config
    |> config_pid()
    |> GenServer.call(
      {:set_string_list, section, subsection, name, [to_string_with_units(value)]}
    )

    config
  end

  def to_string_with_units(value) do
    cond do
      value >= @gib and rem(value, @gib) == 0 -> "#{div(value, @gib)}g"
      value >= @mib and rem(value, @mib) == 0 -> "#{div(value, @mib)}m"
      value >= @kib and rem(value, @kib) == 0 -> "#{div(value, @kib)}k"
      true -> "#{value}"
    end
  end

  @doc ~s"""
  Add or modify a configuration value. The parameters will result in a
  configuration entry like this:

  ```
  [section "subsection"]
    name = value
  ```
  """
  def set_boolean(config, section, subsection \\ nil, name, value)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) and is_boolean(value) do
    config
    |> config_pid()
    |> GenServer.call({:set_string_list, section, subsection, name, [to_string(value)]})

    config
  end

  @doc ~S"""
  Add or modify a configuration value.

  These parameters will result in a configuration entry like this being added
  (in-memory only):

  ```
  [section "subsection"]
    name = value
  ```
  """
  def set_string(config, section, subsection \\ nil, name, value)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) and is_binary(value) do
    config
    |> config_pid()
    |> GenServer.call({:set_string_list, section, subsection, name, [value]})

    config
  end

  # /**
  #  * Remove a configuration value.
  #  *
  #  * @param section
  #  *            section name, e.g "branch"
  #  * @param subsection
  #  *            optional subsection value, e.g. a branch name
  #  * @param name
  #  *            parameter name, e.g. "filemode"
  #  */
  # public void unset(final String section, final String subsection,
  # 		final String name) {
  # 	setStringList(section, subsection, name, Collections
  # 			.<String> emptyList());
  # }

  @doc ~S"""
  Remove all configuration values under a single section.
  """
  def unset_section(config, section, subsection \\ nil)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) do
    config
    |> config_pid()
    |> GenServer.call({:unset_section, section, subsection})

    config
  end

  # IMPORTANT: unset_section_impl/5 runs in GenServer process.
  # See handle_call/3 below.

  defp unset_section_impl(%__MODULE__.State{config_lines: config_lines}, section, subsection),
    do: Enum.reject(config_lines, &ConfigLine.match_section?(&1, section, subsection))

  @doc ~S"""
  Set a configuration value.

  These parameters will result in a configuration entry like this being added
  (in-memory only):

  ```
  [section "subsection"]
    name = value1
    name = value2
  ```
  """
  def set_string_list(config, section, subsection \\ nil, name, values)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) and is_list(values) do
    config
    |> config_pid()
    |> GenServer.call({:set_string_list, section, subsection, name, values})

    config
  end

  # IMPORTANT: set_string_list_impl/5 runs in GenServer process.
  # See handle_call/3 below.

  def set_string_list_impl(
        %__MODULE__.State{config_lines: old_config_lines},
        section,
        subsection,
        name,
        values
      ) do
    new_config_lines =
      old_config_lines
      |> replace_matching_config_lines(values, [], section, subsection, name)
      |> Enum.reverse()

    # UNIMPLEMENTED:
    # if (notifyUponTransientChanges())
    # 	fireConfigChangedEvent();

    new_config_lines
  end

  defp replace_matching_config_lines(
         [],
         new_values,
         reversed_new_config_lines,
         section,
         subsection,
         name
       ) do
    new_config_lines =
      new_values
      |> Enum.map(&%ConfigLine{section: section, subsection: subsection, name: name, value: &1})
      |> Enum.reverse()

    # If we can find a matching key in the existing config, we should insert
    # the new config lines after those. Otherwise, attach to EOF.
    case Enum.split_while(
           reversed_new_config_lines,
           &(!ConfigLine.match_section?(&1, section, subsection))
         ) do
      {all, []} -> new_config_lines ++ [create_section_heaader(section, subsection)] ++ all
      {group1, group2} -> group1 ++ new_config_lines ++ group2
    end
  end

  defp replace_matching_config_lines(
         [current | remainder],
         new_values,
         reversed_new_config_lines,
         section,
         subsection,
         name
       ) do
    if ConfigLine.match?(current, section, subsection, name) do
      {new_values, new_config_lines} =
        consume_next_matching_config_line(new_values, reversed_new_config_lines, current)

      replace_matching_config_lines(
        remainder,
        new_values,
        new_config_lines,
        section,
        subsection,
        name
      )
    else
      replace_matching_config_lines(
        remainder,
        new_values,
        [current | reversed_new_config_lines],
        section,
        subsection,
        name
      )
    end
  end

  defp create_section_heaader(section, subsection),
    do: %ConfigLine{section: section, subsection: subsection}

  defp consume_next_matching_config_line(
         [next_match | remainder],
         reversed_new_config_lines,
         current
       ),
       do: {remainder, [%{current | value: next_match} | reversed_new_config_lines]}

  defp consume_next_matching_config_line([], reversed_new_config_lines, _current),
    do: {reversed_new_config_lines, []}

  # private static List<ConfigLine> copy(final ConfigSnapshot src,
  # 		final List<String> values) {
  # 	// At worst we need to insert 1 line for each value, plus 1 line
  # 	// for a new section header. Assume that and allocate the space.
  # 	//
  # 	final int max = src.entryList.size() + values.size() + 1;
  # 	final ArrayList<ConfigLine> r = new ArrayList<>(max);
  # 	r.addAll(src.entryList);
  # 	return r;
  # }
  #
  # private static int findSectionEnd(final List<ConfigLine> entries,
  # 		final String section, final String subsection,
  # 		boolean skipIncludedLines) {
  # 	for (int i = 0; i < entries.size(); i++) {
  # 		ConfigLine e = entries.get(i);
  # 		if (e.includedFrom != null && skipIncludedLines) {
  # 			continue;
  # 		}
  #
  # 		if (e.match(section, subsection, null)) {
  # 			i++;
  # 			while (i < entries.size()) {
  # 				e = entries.get(i);
  # 				if (e.match(section, subsection, e.name))
  # 					i++;
  # 				else
  # 					break;
  # 			}
  # 			return i;
  # 		}
  # 	}
  # 	return -1;
  # }

  @doc ~S"""
  Load the configuration from the persistent store (if any).

  If the configuration does not exist, this configuration is cleared, and
  thus behaves the same as though the backing store exists, but is empty.
  """
  def load(%__MODULE__{storage: nil}) do
    raise(
      ArgumentError,
      message: "Config.load() called for a Config that doesn't have a storage mechanism defined"
    )
  end

  def load(%__MODULE__{storage: storage} = config), do: __MODULE__.Storage.load(storage, config)

  @doc ~S"""
  Save the configuration to the persistent store (if any).
  """

  def save(%__MODULE__{storage: nil}) do
    raise(
      ArgumentError,
      message: "Config.save() called for a Config that doesn't have a storage mechanism defined"
    )
  end

  def save(%__MODULE__{storage: storage} = config), do: __MODULE__.Storage.save(storage, config)

  defprotocol Storage do
    @moduledoc ~S"""
    Describes how a `Config` struct can be stored and loaded from a location.
    """

    @doc ~S"""
    Load the configuration from the persistent store.

    If the configuration does not exist, this configuration is cleared, and
    thus behaves the same as though the backing store exists, but is empty.
    """
    def load(storage, config)

    @doc ~S"""
    Save the configuration to the persistent store.
    """
    def save(storage, config)
  end

  @doc ~S"""
  Get this configuration, formatted as a git-style text file.
  """
  def to_text(config), do: GenServer.call(config_pid(config), :to_text)

  # IMPORTANT: to_text_impl/1 runs in GenServer process.
  # See handle_call/3 below.

  defp to_text_impl(config_lines) do
    config_lines
    |> Enum.map_join(&config_line_to_text/1)
    |> drop_leading_blank_line()
  end

  defp drop_leading_blank_line("\n" <> remainder), do: remainder
  defp drop_leading_blank_line(s), do: s

  defp config_line_to_text(%ConfigLine{included_from: included_from}) when included_from != nil,
    do: ""

  defp config_line_to_text(%ConfigLine{prefix: prefix, suffix: suffix} = cl),
    do:
      maybe_extra_line_prefix(cl) <>
        "#{config_line_maybe_str(prefix)}#{config_line_body_to_text(cl)}" <>
        "#{config_line_maybe_str(suffix)}\n"

  defp maybe_extra_line_prefix(%ConfigLine{section: section, name: nil}) when section != nil,
    do: "\n"

  defp maybe_extra_line_prefix(_), do: ""

  defp config_line_maybe_str(nil), do: ""
  defp config_line_maybe_str(s), do: s

  defp config_line_body_to_text(%ConfigLine{section: section, subsection: subsection, name: nil})
       when section != nil,
       do: "[#{section}#{subsection_to_text(subsection)}]"

  defp config_line_body_to_text(%ConfigLine{
         prefix: prefix,
         suffix: suffix,
         section: section,
         name: name,
         value: value
       })
       when section != nil do
    "#{prefix_str_for_body(prefix)}#{name}#{value_to_text(value)}#{suffix_str_for_body(suffix)}"
  end

  defp config_line_body_to_text(_), do: ""

  defp subsection_to_text(nil), do: ""

  defp subsection_to_text(subsection) do
    " \"#{subsection}\""

    # UNIMPLEMENTED: Escaping not handled yet.
    # out.append(' ');
    # String escaped = escapeValue(e.subsection);
    # // make sure to avoid double quotes here
    # boolean quoted = escaped.startsWith("\"") //$NON-NLS-1$
    # 		&& escaped.endsWith("\""); //$NON-NLS-1$
    # if (!quoted)
    # 	out.append('"');
    # out.append(escaped);
    # if (!quoted)
    # 	out.append('"');
  end

  defp prefix_str_for_body(nil), do: "\t"
  defp prefix_str_for_body(""), do: "\t"
  defp prefix_str_for_body(_), do: ""

  defp value_to_text(:empty), do: ""
  defp value_to_text(nil), do: " ="
  defp value_to_text(v), do: " = #{escape_value(v)}"

  defp suffix_str_for_body(nil), do: ""
  defp suffix_str_for_body(s), do: s

  @doc ~S"""
  Clear this configuration and reset to the contents of the parsed string.

  `text` should be a git-style text file listing configuration properties

  Raises `ConfigInvalidError` if unable to parse string.
  """
  def from_text(config, text) when is_binary(text) do
    case GenServer.call(config_pid(config), {:from_text, text}) do
      {:error, e} -> raise(e)
      _ -> config
    end
  end

  # IMPORTANT: from_text_impl/3 runs in GenServer process.
  # See handle_call/3 below.

  # UNIMPLEMENTED: Restore this guard when we add support for included config files.
  # defp from_text_impl(_text, 10, _included_from) do
  #   raise ConfigInvalidError, message: "Too many recursions; circular includes in config file(s)?"
  # end

  defp from_text_impl(text, depth, included_from) when is_binary(text) and is_integer(depth) do
    text
    |> String.to_charlist()
    |> config_lines_from([], nil, nil, included_from, [])
  end

  defp config_lines_from(remainder, config_lines_acc, section, subsection, included_from, prefix)

  defp config_lines_from([], config_lines_acc, _section, _subsection, _included_from, _prefix),
    do: config_lines_acc

  # 65_279 = Unicode byte-order-mark (only accepted at beginning of file)
  defp config_lines_from([65_279 | remainder], [], nil, nil, included_from, []),
    do: config_lines_from(remainder, [], nil, nil, included_from, [65_279])

  defp config_lines_from([?\n | remainder], [], nil, nil, included_from, prefix),
    do: config_lines_from(remainder, [], nil, nil, included_from, prefix ++ [?\n])

  defp config_lines_from(
         [?\n | remainder],
         config_lines_acc,
         section,
         subsection,
         included_from,
         _prefix
       ) do
    config_lines_from(remainder, config_lines_acc, section, subsection, included_from, [])
  end

  defp config_lines_from(
         [?\s | remainder],
         config_lines_acc,
         section,
         subsection,
         included_from,
         prefix
       ) do
    config_lines_from(
      remainder,
      config_lines_acc,
      section,
      subsection,
      included_from,
      prefix ++ [?\s]
    )
  end

  defp config_lines_from(
         [?\t | remainder],
         config_lines_acc,
         section,
         subsection,
         included_from,
         prefix
       ) do
    config_lines_from(
      remainder,
      config_lines_acc,
      section,
      subsection,
      included_from,
      prefix ++ [?\t]
    )
  end

  defp config_lines_from(
         [?[ | remainder] = buffer,
         config_lines_acc,
         _section,
         _subsection,
         included_from,
         prefix
       ) do
    # This is a section header.
    {section, remainder} =
      remainder
      |> skip_whitespace()
      |> Enum.split_while(&section_name_char?/1)
      |> section_to_string(buffer)

    {subsection, remainder} =
      remainder
      |> skip_whitespace()
      |> maybe_read_subsection_name(buffer)

    subsection = maybe_string(subsection)

    remainder = expect_close_brace(remainder, buffer)

    {suffix, remainder} = Enum.split_while(remainder, &(&1 != ?\n))

    new_config_line =
      config_line_with_strings(%{
        prefix: prefix,
        section: section,
        subsection: subsection,
        included_from: included_from,
        suffix: suffix
      })

    config_lines_from(
      remainder,
      config_lines_acc ++ [new_config_line],
      section,
      subsection,
      included_from,
      prefix
    )
  end

  defp config_lines_from(
         [c | _] = remainder,
         config_lines_acc,
         section,
         subsection,
         included_from,
         prefix
       )
       when c == ?; or c == ?# do
    {comment, remainder} = Enum.split_while(remainder, &not_eol?/1)

    new_config_line =
      config_line_with_strings(%{
        prefix: prefix,
        section: section,
        subsection: subsection,
        included_from: included_from,
        suffix: comment
      })

    config_lines_from(
      remainder,
      config_lines_acc ++ [new_config_line],
      section,
      subsection,
      included_from,
      prefix
    )
  end

  defp config_lines_from(_remainder, _config_lines_acc, nil, _subsection, _included_from, _prefix) do
    # Attempt to set a value before a section header.
    raise ConfigInvalidError, "Invalid line in config file"
  end

  defp config_lines_from(remainder, config_lines_acc, section, subsection, included_from, prefix) do
    {key, remainder} = read_key_name(remainder, [])
    {value, remainder} = maybe_read_value(remainder)
    {comment, remainder} = maybe_read_comment(remainder)

    new_config_line =
      config_line_with_strings(%{
        prefix: prefix,
        section: section,
        subsection: subsection,
        name: key,
        value: value,
        suffix: comment,
        included_from: included_from
      })

    config_lines_from(
      remainder,
      config_lines_acc ++ [new_config_line],
      section,
      subsection,
      included_from,
      prefix
    )
  end

  defp config_line_with_strings(params) do
    %ConfigLine{
      prefix: maybe_string(params, :prefix),
      section: params.section,
      subsection: params.subsection,
      name: maybe_string(params, :name),
      value: maybe_string(params, :value),
      suffix: maybe_string(params, :suffix),
      included_from: params.included_from
    }
  end

  defp maybe_string(nil), do: nil
  defp maybe_string(x) when is_atom(x), do: x
  defp maybe_string(x), do: to_string(x)
  defp maybe_string(map, key), do: map |> Map.get(key) |> maybe_string()

  defp expect_close_brace([?] | remainder], _buffer), do: remainder
  defp expect_close_brace(_, _buffer), do: raise(ConfigInvalidError, "Bad group header")

  defp section_to_string({[] = _section, _remainder}, buffer), do: raise_bad_section_entry(buffer)
  defp section_to_string({section, remainder}, _buffer), do: {to_string(section), remainder}

  defp maybe_read_subsection_name([?] | _] = remainder, _buffer), do: {nil, remainder}

  defp maybe_read_subsection_name([?" | remainder], buffer),
    do: read_subsection_name(remainder, [], buffer)

  defp maybe_read_subsection_name(_remainder, buffer), do: raise_bad_section_entry(buffer)

  defp read_subsection_name([], _name_acc, buffer), do: raise_bad_section_entry(buffer)
  defp read_subsection_name([?\n | _], _name_acc, buffer), do: raise_bad_section_entry(buffer)
  defp read_subsection_name([?" | remainder], name_acc, _buffer), do: {name_acc, remainder}

  defp read_subsection_name([?\\ | [c | remainder]], name_acc, buffer),
    do: read_subsection_name(remainder, name_acc ++ [c], buffer)

  defp read_subsection_name([c | remainder], name_acc, buffer),
    do: read_subsection_name(remainder, name_acc ++ [c], buffer)

  defp raise_bad_section_entry(buffer) do
    raise(
      ConfigInvalidError,
      "Bad section entry: #{buffer |> first_line_from() |> to_string()}"
    )
  end

  defp read_key_name([], name_acc), do: {name_acc, []}
  defp read_key_name([?\n | _] = remainder, name_acc), do: {name_acc, remainder}
  defp read_key_name([?= | _] = remainder, name_acc), do: {name_acc, remainder}
  defp read_key_name([?\s | remainder], name_acc), do: {name_acc, skip_whitespace(remainder)}
  defp read_key_name([?\t | remainder], name_acc), do: {name_acc, skip_whitespace(remainder)}

  defp read_key_name([c | remainder], name_acc) do
    if letter_or_digit?(c) || c == ?-,
      do: read_key_name(remainder, name_acc ++ [c]),
      else: raise(ConfigInvalidError, message: "Bad entry name: #{to_string(name_acc ++ [c])}")
  end

  defp maybe_read_value([?\n | _] = remainder), do: {:empty, remainder}

  defp maybe_read_value([?= | remainder]),
    do: read_value(skip_whitespace(remainder), [], [], false)

  defp maybe_read_value([?; | remainder]), do: {nil, remainder}
  defp maybe_read_value([?# | remainder]), do: {nil, remainder}
  defp maybe_read_value([]), do: {nil, []}
  defp maybe_read_value(_), do: raise(ConfigInvalidError, message: "Bad entry delimiter.")

  defp read_value([], [], _trailing_ws_acc, _in_quote?), do: {:missing, []}
  defp read_value([], value_acc, _trailing_ws_acc, _in_quote?), do: {value_acc, []}

  defp read_value([?\n | _], _name_acc, _trailing_ws_acc, true = _in_quote?),
    do: raise(ConfigInvalidError, message: "Newline in quotes not allowed")

  defp read_value([?\n | _] = remainder, [], _trailing_ws_acc, _in_quote?),
    do: {:missing, remainder}

  defp read_value([?\n | _] = remainder, value_acc, _trailing_ws_acc, _in_quote?),
    do: {value_acc, remainder}

  defp read_value([c | _] = remainder, value_acc, _trailing_ws_acc, false = _in_quote?)
       when c == ?# or c == ?;,
       do: {value_acc, remainder}

  defp read_value([?\\], _name_acc, _trailing_ws_acc, _in_quote?),
    do: raise(ConfigInvalidError, message: "End of file in escape")

  defp read_value([?\\ | [?\n | remainder]], value_acc, trailing_ws_acc, in_quote?),
    do: read_value(remainder, value_acc ++ trailing_ws_acc, [], in_quote?)

  defp read_value([?\\ | [c | remainder]], value_acc, trailing_ws_acc, in_quote?),
    do:
      read_value(remainder, value_acc ++ trailing_ws_acc ++ [translate_escape(c)], [], in_quote?)

  defp read_value([?" | remainder], value_acc, trailing_ws_acc, in_quote?),
    do: read_value(remainder, value_acc ++ trailing_ws_acc, [], !in_quote?)

  defp read_value([c | remainder], value_acc, trailing_ws_acc, in_quote?) do
    if whitespace?(c),
      do: read_value(remainder, value_acc, trailing_ws_acc ++ [c], in_quote?),
      else: read_value(remainder, value_acc ++ trailing_ws_acc ++ [c], [], in_quote?)
  end

  defp translate_escape(?t), do: ?\t
  defp translate_escape(?b), do: ?\b
  defp translate_escape(?n), do: ?\n
  defp translate_escape(?\\), do: ?\\
  defp translate_escape(?"), do: ?\"
  defp translate_escape(c), do: raise(ConfigInvalidError, message: "Bad escape: #{c}")

  defp maybe_read_comment(remainder) do
    {whitespace, remainder} = Enum.split_while(remainder, &whitespace?/1)
    {comment, remainder} = read_comment(remainder)
    {whitespace ++ comment, remainder}
  end

  defp read_comment([c | _] = remainder) when c == ?; or c == ?#,
    do: Enum.split_while(remainder, &not_eol?/1)

  defp read_comment([?\n | remainder]), do: {[], remainder}
  defp read_comment([]), do: {[], []}

  defp skip_whitespace(s), do: Enum.drop_while(s, &whitespace?/1)

  defp whitespace?(?\s), do: true
  defp whitespace?(?\t), do: true
  defp whitespace?(0xA0), do: true
  defp whitespace?(0x1680), do: true
  defp whitespace?(0x180E), do: true
  defp whitespace?(c) when c >= 0x2000 and c <= 0x200B, do: true
  defp whitespace?(0x202F), do: true
  defp whitespace?(0x205F), do: true
  defp whitespace?(0x3000), do: true
  defp whitespace?(0xFEFF), do: true
  defp whitespace?(_), do: false

  defp first_line_from(buffer), do: Enum.take_while(buffer, &not_eol?/1)

  defp not_eol?(?\n), do: false
  defp not_eol?(_), do: true

  defp section_name_char?(c) when c >= ?0 and c <= ?9, do: true
  defp section_name_char?(c) when c >= ?A and c <= ?Z, do: true
  defp section_name_char?(c) when c >= ?a and c <= ?z, do: true
  defp section_name_char?(?.), do: true
  defp section_name_char?(?-), do: true
  defp section_name_char?(_), do: false

  # HELP: This is not Unicode-savvy. Is there such a thing?
  defp letter_or_digit?(c) when c >= ?0 and c <= ?9, do: true
  defp letter_or_digit?(c) when c >= ?A and c <= ?Z, do: true
  defp letter_or_digit?(c) when c >= ?a and c <= ?z, do: true
  defp letter_or_digit?(_), do: false

  # /**
  #  * Read the included config from the specified (possibly) relative path
  #  *
  #  * @param relPath
  #  *            possibly relative path to the included config, as specified in
  #  *            this config
  #  * @return the read bytes, or null if the included config should be ignored
  #  * @throws org.eclipse.jgit.errors.ConfigInvalidException
  #  *             if something went wrong while reading the config
  #  * @since 4.10
  #  */
  # protected byte[] readIncludedConfig(String relPath)
  # 		throws ConfigInvalidException {
  # 	return null;
  # }
  #
  # private void addIncludedConfig(final List<ConfigLine> newEntries,
  # 		ConfigLine line, int depth) throws ConfigInvalidException {
  # 	if (!line.name.equalsIgnoreCase("path") || //$NON-NLS-1$
  # 			line.value == null || line.value.equals(MAGIC_EMPTY_VALUE)) {
  # 		throw new ConfigInvalidException(MessageFormat.format(
  # 				JGitText.get().invalidLineInConfigFileWithParam, line));
  # 	}
  # 	byte[] bytes = readIncludedConfig(line.value);
  # 	if (bytes == null) {
  # 		return;
  # 	}
  #
  # 	String decoded;
  # 	if (isUtf8(bytes)) {
  # 		decoded = RawParseUtils.decode(UTF_8, bytes, 3, bytes.length);
  # 	} else {
  # 		decoded = RawParseUtils.decode(bytes);
  # 	}
  # 	try {
  # 		newEntries.addAll(fromTextRecurse(decoded, depth + 1, line.value));
  # 	} catch (ConfigInvalidException e) {
  # 		throw new ConfigInvalidException(MessageFormat
  # 				.format(JGitText.get().cannotReadFile, line.value), e);
  # 	}
  # }

  @doc ~S"""
  Clear the configuration file.
  """
  def clear(config), do: config |> config_pid() |> GenServer.call(:clear)

  # /**
  #  * Check if bytes should be treated as UTF-8 or not.
  #  *
  #  * @param bytes
  #  *            the bytes to check encoding for.
  #  * @return true if bytes should be treated as UTF-8, false otherwise.
  #  * @since 4.4
  #  */
  # protected boolean isUtf8(final byte[] bytes) {
  # 	return bytes.length >= 3 && bytes[0] == (byte) 0xEF
  # 			&& bytes[1] == (byte) 0xBB && bytes[2] == (byte) 0xBF;
  # }

  # /**
  #  * Parses a section of the configuration into an application model object.
  #  * <p>
  #  * Instances must implement hashCode and equals such that model objects can
  #  * be cached by using the {@code SectionParser} as a key of a HashMap.
  #  * <p>
  #  * As the {@code SectionParser} itself is used as the key of the internal
  #  * HashMap applications should be careful to ensure the SectionParser key
  #  * does not retain unnecessary application state which may cause memory to
  #  * be held longer than expected.
  #  *
  #  * @param <T>
  #  *            type of the application model created by the parser.
  #  */
  # public static interface SectionParser<T> {
  # 	/**
  # 	 * Create a model object from a configuration.
  # 	 *
  # 	 * @param cfg
  # 	 *            the configuration to read values from.
  # 	 * @return the application model instance.
  # 	 */
  # 	T parse(Config cfg);
  # }
  #
  # private static class StringReader {
  # 	private final char[] buf;
  #
  # 	private int pos;
  #
  # 	StringReader(String in) {
  # 		buf = in.toCharArray();
  # 	}
  #
  # 	int read() {
  # 		try {
  # 			return buf[pos++];
  # 		} catch (ArrayIndexOutOfBoundsException e) {
  # 			pos = buf.length;
  # 			return -1;
  # 		}
  # 	}
  #
  # 	void reset() {
  # 		pos--;
  # 	}
  # }

  @impl true
  def handle_call(:to_text, _from, %__MODULE__.State{config_lines: config_lines} = s),
    do: {:reply, to_text_impl(config_lines), s}

  @impl true
  def handle_call({:from_text, text}, _from, %__MODULE__.State{} = s) when is_binary(text) do
    new_config_lines = from_text_impl(text, 1, nil)
    {:reply, :ok, %{s | config_lines: new_config_lines}}
  rescue
    e in ConfigInvalidError -> {:reply, {:error, e}, s}
  end

  @impl true
  def handle_call({:get_raw_strings, section, subsection, name}, _from, %__MODULE__.State{} = s)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) do
    {:reply, raw_string_list(s, section, subsection, name), s}
  end

  @impl true
  def handle_call(
        {:subsections, section},
        _from,
        %__MODULE__.State{config_lines: config_lines} = s
      )
      when is_binary(section) do
    {:reply, subsections_impl(config_lines, section), s}
  end

  @impl true
  def handle_call(:sections, _from, %__MODULE__.State{config_lines: config_lines} = s),
    do: {:reply, sections_impl(config_lines), s}

  @impl true
  def handle_call(
        {:names_in_section, section, options},
        _from,
        %__MODULE__.State{base_config: base_config, config_lines: config_lines} = s
      )
      when is_binary(section) and is_list(options) do
    {:reply, names_in_section_impl(config_lines, section, base_config, options), s}
  end

  @impl true
  def handle_call(
        {:names_in_subsection, section, subsection, options},
        _from,
        %__MODULE__.State{base_config: base_config, config_lines: config_lines} = s
      )
      when is_binary(section) and is_binary(subsection) and is_list(options) do
    {:reply, names_in_subsection_impl(config_lines, section, subsection, base_config, options), s}
  end

  @impl true
  def handle_call({:unset_section, section, subsection}, _from, %__MODULE__.State{} = s)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) do
    new_config_lines = unset_section_impl(s, section, subsection)
    {:reply, :ok, %{s | config_lines: new_config_lines}}
  end

  @impl true
  def handle_call(
        {:set_string_list, section, subsection, name, values},
        _from,
        %__MODULE__.State{} = s
      )
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) and is_list(values) do
    new_config_lines = set_string_list_impl(s, section, subsection, name, values)
    {:reply, :ok, %{s | config_lines: new_config_lines}}
  end

  @impl true
  def handle_call(:clear, _from, %__MODULE__.State{} = s),
    do: {:reply, :ok, %{s | config_lines: []}}

  @impl true
  def handle_info(_message, %__MODULE__.State{} = s), do: {:noreply, s}

  defp config_pid(%__MODULE__{config_pid: pid}) when is_pid(pid), do: pid
end
