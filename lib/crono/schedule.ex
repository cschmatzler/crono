defmodule Crono.Schedule do
  @moduledoc false

  import Crono.Utilities
  import Kernel, except: [max: 2]

  def get_next_dates(%Crono.Expression{} = expression, %DateTime{} = datetime \\ DateTime.utc_now()) do
    Stream.unfold(datetime, fn previous_datetime ->
      next_date = get_next_date(expression, previous_datetime)

      {next_date, DateTime.add(next_date, 1, :minute)}
    end)
  end

  def get_next_date(%Crono.Expression{} = expression, %DateTime{} = datetime \\ DateTime.utc_now()) do
    get_date(expression, Crono.Expression.to_fields(expression), datetime)
  end

  defp get_date(expression, [{_field, [:*]} | tail], datetime) do
    get_date(expression, tail, datetime)
  end

  defp get_date(expression, [{field, value} | tail], datetime) do
    get_date(
      expression,
      tail,
      adjust_datetime(expression, field, value, datetime)
    )
  end

  defp get_date(_expression, [], datetime), do: DateTime.truncate(%{datetime | second: 0}, :second)

  @next [minute: :hour, hour: :day, day: :month, month: :year]
  defp adjust_datetime(expression, :weekday, [value], datetime) when is_integer(value) do
    case datetime |> DateTime.to_date() |> Date.day_of_week() do
      ^value -> datetime
      _ -> get_next_date(expression, datetime)
    end
  end

  defp adjust_datetime(expression, :weekday, [step: {:*, step}], datetime),
    do: adjust_datetime_weekday_list(min(:weekday)..max(:weekday)//step, expression, datetime)

  defp adjust_datetime(expression, :weekday, [step: {start, step}], datetime),
    do: adjust_datetime_weekday_list(start..max(:weekday)//step, expression, datetime)

  defp adjust_datetime(expression, :weekday, [range: {from, to}], datetime),
    do: adjust_datetime_weekday_list(from..to, expression, datetime)

  defp adjust_datetime(expression, :weekday, [list: list], datetime),
    do: adjust_datetime_weekday_list(list, expression, datetime)

  defp adjust_datetime(expression, type, [value], datetime)
       when is_integer(value) and type in [:minute, :hour, :day, :month] do
    case Map.get(datetime, type) do
      ^value ->
        datetime

      datetime_value when datetime_value <= value ->
        Map.put(datetime, type, value)

      _ ->
        datetime
        |> Map.put(type, value)
        |> Map.update!(@next[type], &(&1 + 1))
        |> clean_datetime(type)
        |> then(&get_next_date(expression, &1))
    end
  end

  defp adjust_datetime(expression, type, [step: {:*, step}], datetime)
       when type in [:minute, :hour, :day, :month],
       do: adjust_datetime(expression, type, [step: {min(type), step}], datetime)

  defp adjust_datetime(expression, type, [step: {start, step}], datetime)
       when type in [:minute, :hour, :day, :month] do
    start..max(type, Map.get(datetime, @next[type]))//step
    |> Enum.to_list()
    |> adjust_datetime_list(expression, type, datetime)
  end

  defp adjust_datetime(expression, type, [range: {from, to}], datetime)
       when type in [:minute, :hour, :day, :month] do
    from..(to + 1)
    |> Enum.to_list()
    |> adjust_datetime_list(expression, type, datetime)
  end

  defp adjust_datetime(expression, type, [list: list], datetime)
       when type in [:minute, :hour, :day, :month],
       do: adjust_datetime_list(list, expression, type, datetime)

  defp adjust_datetime_list(list, expression, type, datetime) do
    datetime_value = Map.get(datetime, type)

    if Enum.max([datetime_value | list]) == datetime_value do
      datetime
      |> Map.put(type, Enum.min(list))
      |> Map.update!(@next[type], &(&1 + 1))
      |> clean_datetime(type)
      |> then(&get_next_date(expression, &1))
    else
      list
      |> Enum.sort()
      |> Enum.drop_while(fn x -> x < datetime_value end)
      |> List.first()
      |> then(&Map.put(datetime, type, &1))
      |> clean_datetime(type)
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

  defp clean_datetime(datetime, :month), do: %{datetime | minute: 0, hour: 0, day: 0}
  defp clean_datetime(datetime, :day), do: %{datetime | minute: 0, hour: 0}
  defp clean_datetime(datetime, :hour), do: %{datetime | minute: 0}
  defp clean_datetime(datetime, _), do: datetime
end
