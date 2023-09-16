defmodule Crono.Expression do
  @moduledoc """
  A parsed cron expression.
  """

  defstruct [:minute, :hour, :day, :month, :weekday]

  @type t :: %__MODULE__{
          minute: value(non_neg_integer()),
          hour: value(non_neg_integer()),
          day: value(pos_integer()),
          month: value(pos_integer()),
          weekday: value(non_neg_integer())
        }

  @type value(inner_type) ::
          :*
          | inner_type
          # [step: {start, step}]
          | [step: {inner_type, pos_integer()}]
          # [range: {from, to}]
          | [range: {inner_type, inner_type}]
          | [list: list(inner_type)]

  @doc """
  Sigil to parse an input and create a `Crono.Expression`.

  ## Examples

  ```elixir
  iex> ~e[*/15 * * * *]
  %Crono.Expression{minute: [step: {:*, 15}], hour: :*, day: :*, month: :*, weekday: :*}
  ```
  """
  def sigil_e(input, _opts), do: Crono.parse!(input)

  @doc false
  def to_fields(%__MODULE__{} = expression) do
    [
      {:weekday, expression.weekday},
      {:month, expression.month},
      {:day, expression.day},
      {:hour, expression.hour},
      {:minute, expression.minute}
    ]
  end
end
