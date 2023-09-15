defmodule Crono.Schedule do
  @moduledoc false
  def get_next_date(%Crono.Expression{} = expression, %DateTime{} = datetime \\ DateTime.utc_now()) do
    expression
    |> Crono.Expression.to_list()
    |> get_date(datetime)
  end

  defp get_date([{_part, [:*]} | tail], datetime) do
    get_date(tail, datetime)
  end

  defp get_date([{part, value} | tail], datetime) do
    get_date(tail, adjust_datetime(part, value, datetime))
  end

  defp get_date([], datetime), do: datetime |> Map.put(:second, 0) |> DateTime.truncate(:second)

  @min [minute: 0, hour: 0, day: 1, month: 1]
  @max [minute: 59, hour: 23, day: 31, month: 12]
  @next [minute: :hour, hour: :day, day: :month, month: :year]
  defp adjust_datetime(type, [value], datetime)
       when is_integer(value) and type in [:minute, :hour, :day, :month] do
    if value > Map.get(datetime, type) do
      Map.put(datetime, type, value)
    else
      datetime
      |> Map.put(type, value)
      |> Map.update!(@next[type], &(&1 + 1))
    end
  end

  defp adjust_datetime(type, [step: {:*, step}], datetime)
       when type in [:minute, :hour, :day, :month],
       do: adjust_datetime(type, [step: {@min[type], step}], datetime)

  defp adjust_datetime(type, [step: {start, step}], datetime)
       when type in [:minute, :hour, :day, :month] do
    start..@max[type]//step
    |> Enum.to_list()
    |> adjust_datetime_list(type, datetime)
  end

  defp adjust_datetime(type, [range: {from, to}], datetime)
       when type in [:minute, :hour, :day, :month] do
    from..to
    |> Enum.to_list()
    |> adjust_datetime_list(type, datetime)
  end

  defp adjust_datetime(type, [list: list], datetime) when type in [:minute, :hour, :day, :month],
    do: adjust_datetime_list(list, type, datetime)

  defp adjust_datetime_list(list, type, datetime) do
    datetime_value = Map.get(datetime, :type)

    if Enum.max([datetime_value | list]) == datetime_value do
      datetime
      |> Map.put(type, Enum.min(list))
      |> Map.update!(@next[type], &(&1 + 1))
    else
      list
      |> Enum.sort()
      |> Enum.drop_while(fn x -> x <= datetime_value end)
      |> List.first()
      |> then(&Map.put(datetime, type, &1))
    end
  end
end
