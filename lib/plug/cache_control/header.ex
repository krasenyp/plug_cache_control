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

  defstruct [
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

  @spec new() :: t()
  def new(), do: %__MODULE__{}

  @spec new(Enum.t()) :: t()
  def new(fields) do
    put_many(%__MODULE__{}, fields)
  end

  @spec put(t(), {atom(), term()}) :: t()
  def put(%__MODULE__{} = header, {field, value}) do
    do_put(header, field, value)
  end

  @spec put(t(), atom(), term()) :: t()
  def put(%__MODULE__{} = header, field, value) do
    do_put(header, field, value)
  end

  @spec put_many(t(), Enum.t()) :: t()
  def put_many(%__MODULE__{} = header, fields) do
    Enum.reduce(fields, header, fn clause, header -> put(header, clause) end)
  end

  defp do_put(header, :public, value) do
    %{header | public: value, private: !value}
  end

  defp do_put(header, :private, value) do
    %{header | public: !value, private: value}
  end

  defp do_put(header, :no_cache, fields) when is_list(fields) do
    joined_fields = Enum.join(fields, ", ")

    %{header | no_cache: "\"#{joined_fields}\""}
  end

  defp do_put(header, field, {_, _} = duration) do
    do_put(header, field, duration_to_seconds(duration))
  end

  defp do_put(header, field, value) do
    struct_put!(header, field, value)
  end

  @spec from_string(String.t()) :: t()
  def from_string(str) when is_binary(str) do
    str
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.split(&1, "=", trim: true))
    |> Enum.map(fn
      [key] -> {field_to_atom(key), true}
      [key, value] -> {field_to_atom(key), value}
    end)
    |> new()
  end

  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = header) do
    Kernel.to_string(header)
  end

  # Header-specific utility functions

  defp duration_to_seconds({period, unit}) when unit in [:second, :seconds], do: period
  defp duration_to_seconds({period, unit}) when unit in [:minute, :minutes], do: period * 60
  defp duration_to_seconds({period, unit}) when unit in [:hour, :hours], do: period * 60 * 60
  defp duration_to_seconds({period, unit}) when unit in [:day, :days], do: period * 60 * 60 * 24

  defp duration_to_seconds({period, unit}) when unit in [:week, :weeks],
    do: period * 60 * 60 * 24 * 7

  defp duration_to_seconds({period, unit}) when unit in [:year, :years],
    do: period * 60 * 60 * 24 * 365

  defp field_to_atom(field) when is_binary(field) do
    field
    |> String.replace("-", "_")
    |> String.to_existing_atom()
  end

  defp struct_put!(struct, field, value) when is_atom(field) do
    to_merge = Map.put(%{}, field, value)

    struct!(struct, to_merge)
  end

  defimpl String.Chars do
    def to_string(header) do
      header
      |> Map.from_struct()
      |> Enum.reduce([], fn
        {_key, nil}, acc -> acc
        {_key, false}, acc -> acc
        {key, true}, acc -> [atom_to_field(key) | acc]
        {key, value}, acc -> ["#{atom_to_field(key)}=#{value}" | acc]
      end)
      |> Enum.join(", ")
    end

    defp atom_to_field(atom) when is_atom(atom) do
      atom
      |> Atom.to_string()
      |> String.replace("_", "-")
    end
  end
end
