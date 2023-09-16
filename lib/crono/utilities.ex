defmodule Crono.Utilities do
  @moduledoc false

  def min_value(:minute), do: 0
  def min_value(:hour), do: 0
  def min_value(:day), do: 1
  def min_value(:month), do: 1
  def min_value(:weekday), do: 0

  def max_value(type, datetime \\ NaiveDateTime.utc_now())
  def max_value(:minute, _datetime), do: 59
  def max_value(:hour, _datetime), do: 23
  def max_value(:day, datetime), do: datetime |> NaiveDateTime.to_date() |> Date.days_in_month()
  def max_value(:month, _next_value), do: 12
  def max_value(:weekday, _next_value), do: 6
end
