defmodule Plug.CacheControl.Header do
  @moduledoc false

  @typep maybe(t) :: t | nil
  @type t :: %__MODULE__{
          must_revalidate: maybe(boolean()),
          no_cache: maybe(boolean()),
          no_store: maybe(boolean()),
          no_transform: maybe(boolean()),
          proxy_revalidate: maybe(boolean()),
          private: maybe(boolean()),
          public: maybe(boolean()),
          max_age: maybe(integer()),
          s_maxage: maybe(integer()),
          stale_while_revalidate: maybe(integer()),
          stale_if_error: maybe(integer())
        }

  @directives [
    :must_revalidate,
    :no_cache,
    :no_store,
    :no_transform,
    :proxy_revalidate,
    :private,
    :public,
    :max_age,
    :s_maxage,
    :stale_while_revalidate,
    :stale_if_error
  ]
  @numeric_dir [:max_age, :s_maxage, :stale_while_revalidate, :stale_if_error]

  defstruct @directives

  defguardp is_directive(directive) when directive in @directives

  defguardp is_numeric(directive) when directive in @numeric_dir

  defguardp is_delta(time)
            when is_integer(time) and time >= 0

  @doc """
  Creates a new header struct.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Creates a new header struct from an enumerable.
  """
  @spec new(Enum.t()) :: t()
  def new(directives) do
    put_many(%__MODULE__{}, directives)
  end

  @doc """
  Puts a value of a directive in the header struct.
  """
  @spec put(t(), Utils.directive(), term()) :: t()
  def put(%__MODULE__{} = header, directive, value) do
    do_put(header, directive, value)
  end

  @spec put_many(t(), Enum.t()) :: t()
  def put_many(%__MODULE__{} = header, directives) do
    Enum.reduce(directives, header, fn {directive, value}, header ->
      put(header, directive, value)
    end)
  end

  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{} = ha, %__MODULE__{} = hb) do
    ham = Map.from_struct(ha)
    hbm = Map.from_struct(hb)

    ham
    |> Map.merge(hbm)
    |> new()
  end

  @spec from_string(String.t()) :: t()
  def from_string(str) when is_binary(str) do
    str
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.split(&1, "=", trim: true))
    |> Enum.map(fn
      [key] -> {directive_to_atom(key), true}
      [key, value] -> {directive_to_atom(key), value}
    end)
    |> new()
  end

  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = header) do
    Kernel.to_string(header)
  end

  defp do_put(_, directive, _) when not is_directive(directive) do
    raise ArgumentError, "Unsupported directive #{inspect(directive)}"
  end

  defp do_put(header, :public, value) when is_boolean(value) do
    %{header | public: value, private: !value}
  end

  defp do_put(header, :private, value) when is_boolean(value) do
    %{header | public: !value, private: value}
  end

  defp do_put(header, :no_cache, fields) when is_list(fields) do
    joined_fields = Enum.join(fields, ", ")

    %{header | no_cache: "\"#{joined_fields}\""}
  end

  defp do_put(header, directive, {time, _unit} = dur)
       when is_numeric(directive) and is_delta(time) do
    do_put(header, directive, duration_to_seconds(dur))
  end

  defp do_put(header, directive, field) when is_numeric(directive) and is_delta(field) do
    struct_put!(header, directive, field)
  end

  defp do_put(header, directive, value) when is_directive(directive) and is_boolean(value) do
    struct_put!(header, directive, value)
  end

  defimpl String.Chars do
    defp atom_to_directive(atom) when is_atom(atom) do
      atom
      |> Atom.to_string()
      |> String.replace("_", "-")
    end

    def to_string(header) do
      header
      |> Map.from_struct()
      |> Enum.reduce([], fn
        {_key, nil}, acc -> acc
        {_key, false}, acc -> acc
        {key, true}, acc -> [atom_to_directive(key) | acc]
        {key, value}, acc -> ["#{atom_to_directive(key)}=#{value}" | acc]
      end)
      |> Enum.join(", ")
    end
  end

  defp duration_to_seconds({period, _unit} = dur) when is_integer(period) and period >= 0,
    do: do_duration_to_seconds(dur)

  defp do_duration_to_seconds({period, unit}) when unit in [:second, :seconds], do: period
  defp do_duration_to_seconds({period, unit}) when unit in [:minute, :minutes], do: period * 60
  defp do_duration_to_seconds({period, unit}) when unit in [:hour, :hours], do: period * 60 * 60

  defp do_duration_to_seconds({period, unit}) when unit in [:day, :days],
    do: period * 60 * 60 * 24

  defp do_duration_to_seconds({period, unit}) when unit in [:week, :weeks],
    do: period * 60 * 60 * 24 * 7

  defp do_duration_to_seconds({period, unit}) when unit in [:year, :years],
    do: period * 60 * 60 * 24 * 365

  defp do_duration_to_seconds({_, unit}),
    do: raise(ArgumentError, "Invalid unit #{inspect(unit)}.")

  defp directive_to_atom(directive) when is_binary(directive) do
    directive
    |> String.replace("-", "_")
    |> String.to_existing_atom()
  end

  defp struct_put!(struct, field, value) when is_struct(struct) and is_atom(field) do
    to_merge = Map.put(%{}, field, value)

    struct!(struct, to_merge)
  end
end
