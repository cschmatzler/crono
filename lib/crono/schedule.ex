defmodule Crono.Schedule do
  @moduledoc false
  def get_next_date(%Crono.Expression{} = expression, %DateTime{} = datetime \\ DateTime.utc_now()) do
    get_date(expression, Crono.Expression.to_list(expression), datetime)
  end

  defp get_date(expression, [{_part, [:*]} | tail], datetime) do
    get_date(expression, tail, datetime)
  end

  defp get_date(expression, [{part, value} | tail], datetime) do
    get_date(expression, tail, adjust_datetime(expression, part, value, datetime))
  end

  defp get_date(_expression, [], datetime),
    do: datetime |> Map.put(:second, 0) |> DateTime.truncate(:second)

  @min [minute: 0, hour: 0, day: 1, month: 1, weekday: 0]
  @max [minute: 59, hour: 23, day: 31, month: 12, weekday: 7]
  @next [minute: :hour, hour: :day, day: :month, month: :year]

  defp adjust_datetime(expression, :weekday, [value], datetime) when is_integer(value) do
    case datetime |> DateTime.to_date() |> Date.day_of_week() do
      ^value -> datetime
      _ -> get_next_date(expression, datetime)
    end
  end

  defp adjust_datetime(expression, :weekday, [step: {:*, step}], datetime),
    do: adjust_datetime_weekday_list(@min[:weekday]..@max[:weekday]//step, expression, datetime)

  defp adjust_datetime(expression, :weekday, [step: {start, step}], datetime),
    do: adjust_datetime_weekday_list(start..@max[:weekday]//step, expression, datetime)

  defp adjust_datetime(expression, :weekday, [range: {from, to}], datetime),
    do: adjust_datetime_weekday_list(from..to, expression, datetime)

  defp adjust_datetime(expression, :weekday, [list: list], datetime),
    do: adjust_datetime_weekday_list(list, expression, datetime)

  defp adjust_datetime(_expression, type, [value], datetime)
       when is_integer(value) and type in [:minute, :hour, :day, :month] do
    if value > Map.get(datetime, type) do
      Map.put(datetime, type, value)
    else
      datetime
      |> Map.put(type, value)
      |> Map.update!(@next[type], &(&1 + 1))
    end
  end

  defp adjust_datetime(expression, type, [step: {:*, step}], datetime)
       when type in [:minute, :hour, :day, :month],
       do: adjust_datetime(expression, type, [step: {@min[type], step}], datetime)

  defp adjust_datetime(_expression, type, [step: {start, step}], datetime)
       when type in [:minute, :hour, :day, :month] do
    start..@max[type]//step
    |> Enum.to_list()
    |> adjust_datetime_list(type, datetime)
  end

  defp adjust_datetime(_expression, type, [range: {from, to}], datetime)
       when type in [:minute, :hour, :day, :month] do
    from..to
    |> Enum.to_list()
    |> adjust_datetime_list(type, datetime)
  end

  defp adjust_datetime(_expression, type, [list: list], datetime)
       when type in [:minute, :hour, :day, :month],
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

  defp adjust_datetime_weekday_list(list, expression, datetime) do
    datetime_value = datetime |> DateTime.to_date() |> Date.day_of_week()

    if Enum.member?(list, datetime_value) do
      datetime
    else
      get_next_date(expression, datetime)
    end
  end
end
