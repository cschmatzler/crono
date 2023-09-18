defmodule Crono.Schedule do
  @moduledoc """
  Functions to work with cron schedules.
  """

  import Crono.Utilities

  @next [minute: :hour, hour: :day, day: :month, month: :year]
  @previous [hour: :minute, day: :hour, month: :day, year: :month]

  @doc """
  Calculates the next scheduled run given a `Crono.Expression` and a date (defaulting to now).

  ## Examples

  ```elixir
  iex> get_next_date(~e[0 0 * * *], ~N[2023-09-01T15:00:00])
  ~N[2023-09-02T00:00:00]
  ```
  """
  @spec get_next_date(Crono.Expression.t(), NaiveDateTime.t() | DateTime.t()) ::
          NaiveDateTime.t() | DateTime.t()
  def get_next_date(expression, datetime \\ NaiveDateTime.utc_now())

  def get_next_date(%Crono.Expression{} = expression, %DateTime{} = datetime) do
    datetime
    |> DateTime.to_naive()
    |> then(&get_next_date(expression, &1))
    |> DateTime.from_naive(datetime.time_zone)
  end

  def get_next_date(%Crono.Expression{} = expression, %NaiveDateTime{} = datetime) do
    get_date(expression, datetime)
  end

  @doc """
  Calculates the next few scheduled runs given a `Crono.Expression`, a date (defaulting to now) and
  a count.

  ## Examples

  ```elixir
  iex> get_next_dates(~e[0 0 * * *], ~N[2023-09-01T15:00:00], 3)
  [~N[2023-09-02T00:00:00], ~N[2023-09-03T00:00:00], ~N[2023-09-04T00:00:00]]
  ```
  """
  @spec get_next_dates(Crono.Expression.t(), NaiveDateTime.t(), pos_integer()) ::
          list(NaiveDateTime.t())
  def get_next_dates(
        %Crono.Expression{} = expression,
        %NaiveDateTime{} = datetime \\ NaiveDateTime.utc_now(),
        count
      )
      when count > 0 do
    expression
    |> get_next_dates_stream(datetime)
    |> Stream.take(count)
    |> Enum.to_list()
  end

  defp get_next_dates_stream(%Crono.Expression{} = expression, %NaiveDateTime{} = datetime) do
    Stream.unfold(datetime, fn previous_datetime ->
      next_date = get_next_date(expression, previous_datetime)

      {next_date, NaiveDateTime.add(next_date, 1, :minute)}
    end)
  end

  defp get_date(expression, datetime, previous_field \\ nil)

  defp get_date(expression, datetime, nil) do
    adjust_for_field(expression, :month, expression.month, datetime)
  end

  defp get_date(expression, datetime, :month) do
    value =
      case {expression.day, expression.weekday} do
        {:*, :*} ->
          :*

        {:*, weekday_value} ->
          weekday_value

        {day_value, :*} ->
          day_value

        {day_value, weekday_value} ->
          {:list, [day_value | get_weekdays_in_month(datetime, weekday_value)]}
      end

    adjust_for_field(expression, :day, value, datetime)
  end

  defp get_date(_expression, datetime, :minute),
    do: NaiveDateTime.truncate(%{datetime | second: 0}, :second)

  defp get_date(expression, datetime, previous_field) do
    field = @previous[previous_field]

    adjust_for_field(expression, field, Map.get(expression, field), datetime)
  end

  defp adjust_for_field(expression, type, value, datetime) do
    get_date(expression, adjust_datetime(expression, type, value, datetime), type)
  end

  defp adjust_datetime(_expression, _type, :*, datetime), do: datetime

  defp adjust_datetime(expression, type, value, datetime) when is_integer(value) do
    case Map.get(datetime, type) do
      ^value ->
        datetime

      datetime_value when datetime_value < value ->
        datetime
        |> Map.put(type, value)
        |> clean_datetime(type)

      _ ->
        datetime
        |> Map.put(type, value)
        |> Map.update!(@next[type], &(&1 + 1))
        |> clean_datetime(type)
        |> then(&get_next_date(expression, &1))
    end
  end

  defp adjust_datetime(expression, type, {:list, list}, datetime),
    do: adjust_datetime_list(expand_list(list, type, datetime), expression, type, datetime)

  defp adjust_datetime(expression, type, {:step, {:*, step}}, datetime),
    do: adjust_datetime(expression, type, {:step, {min_value(type), step}}, datetime)

  defp adjust_datetime(expression, type, {:step, {start, step}}, datetime) do
    start..max_value(type, datetime)//step
    |> Enum.to_list()
    |> adjust_datetime_list(expression, type, datetime)
  end

  defp adjust_datetime(expression, type, {:range, {from, to}}, datetime) do
    from..(to + 1)
    |> Enum.to_list()
    |> adjust_datetime_list(expression, type, datetime)
  end

  defp adjust_datetime_list(list, expression, type, datetime) do
    datetime_value = Map.get(datetime, type)

    if Enum.max([datetime_value | list]) == datetime_value do
      datetime
      |> Map.put(type, Enum.min(list))
      |> Map.update!(@next[type], &(&1 + 1))
      |> clean_datetime(type)
    else
      list
      |> Enum.sort()
      |> Enum.drop_while(fn x -> x < datetime_value end)
      |> List.first()
      |> then(&adjust_datetime(expression, type, &1, datetime))
    end
  end

  def get_weekdays_in_month(datetime, value) do
    allowed_weekdays = expand_list(List.wrap(value), :weekday, datetime)

    last_day_in_month = datetime |> NaiveDateTime.to_date() |> Date.end_of_month()

    datetime.day..last_day_in_month.day
    |> Enum.map(&Date.new!(datetime.year, datetime.month, &1))
    |> Enum.filter(fn date ->
      date |> Date.day_of_week() |> then(&Enum.member?(allowed_weekdays, &1))
    end)
    |> Enum.map(& &1.day)
  end

  # TODO: rename
  defp expand_list(list, type, datetime, acc \\ []) do
    case list do
      [item | tail] when is_integer(item) ->
        expand_list(tail, type, datetime, [item | acc])

      [{:step, {start, step}} | tail] when is_integer(start) ->
        item = start..max_value(type, datetime)//step
        expand_list(tail, type, datetime, [item | acc])

      [{:step, {{:range, {from, to}}, step}} | tail] when is_integer(from) and is_integer(to) ->
        item = Enum.to_list(from..to//step)
        expand_list(tail, type, datetime, [item | acc])

      [{:range, {from, to}} | tail] when is_integer(from) and is_integer(to) ->
        item = Enum.to_list(from..to)
        expand_list(tail, type, datetime, [item | acc])

      [{:list, list} | tail] ->
        expand_list(tail, type, datetime, [expand_list(list, type, datetime) | acc])

      [] ->
        acc |> Enum.reverse() |> List.flatten()

      list ->
        acc ++ list
    end
  end

  defp clean_datetime(datetime, :month), do: %{datetime | minute: 0, hour: 0, day: 1}
  defp clean_datetime(datetime, :day), do: %{datetime | minute: 0, hour: 0}
  defp clean_datetime(datetime, :hour), do: %{datetime | minute: 0}
  defp clean_datetime(datetime, _), do: datetime
end
