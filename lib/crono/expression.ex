defmodule Crono.Expression do
  @moduledoc false
  defstruct [:minute, :hour, :day, :month, :weekday]

  @type t :: %__MODULE__{
          minute: value(non_neg_integer()),
          hour: value(non_neg_integer()),
          day: value(pos_integer()),
          month: value(pos_integer()),
          weekday: value(non_neg_integer())
        }

  @type value(inner_type) ::
          [:*]
          | [inner_type]
          | [step: {inner_type, pos_integer()}]
          | [range: {inner_type, inner_type}]
          | [list: list(inner_type)]

  def to_list(%__MODULE__{} = expression) do
    [
      {:minute, expression.minute},
      {:hour, expression.hour},
      {:day, expression.day},
      {:month, expression.month},
      {:weekday, expression.weekday}
    ]
  end

  def time_of_day(%__MODULE__{minute: [minute], hour: [hour]})
      when is_integer(minute) and is_integer(hour) do
    "At #{hour |> Time.new!(minute, 0) |> Time.to_string()}"
  end

  def time_of_day(%__MODULE__{minute: [minute], hour: [hour]}) do
    "#{minute(minute)} past #{hour(hour)}"
  end

  defp minute(minute) when is_integer(minute), do: "At minute #{minute}"

  defp minute({:range, [from, to]}), do: "Every minute from #{from} to #{to}"

  defp minute({:step, [start, step]}) do
    step_plural =
      case step do
        1 -> "1st"
        2 -> "2nd"
        3 -> "3rd"
        n -> "#{n}th"
      end

    "At every #{step_plural} minute from #{start} through 59"
  end

  defp minute({:list, list}) do
    {last, rest} = List.pop_at(list, -1)
    "At minutes #{Enum.join(rest, ", ")} and #{last}"
  end

  defp hour(hour) when is_integer(hour), do: "hour #{hour}"

  defp hour({:range, [from, to]}), do: "every hour from #{from} to #{to}"

  defp hour({:step, [start, step]}) do
    step_plural =
      case step do
        1 -> "1st"
        2 -> "2nd"
        3 -> "3rd"
        n -> "#{n}th"
      end

    "every #{step_plural} hour from #{start} through 23"
  end

  defp hour({:list, list}) do
    {last, rest} = List.pop_at(list, -1)
    "at hours #{Enum.join(rest, ", ")} and #{last}"
  end
end
