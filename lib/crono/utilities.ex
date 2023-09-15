defmodule Crono.Utilities do
  @moduledoc false

  def min(:minute), do: 0
  def min(:hour), do: 0
  def min(:day), do: 1
  def min(:month), do: 1
  def min(:weekday), do: 0

  def max(type, next_value \\ 1)
  def max(:minute, _next_value), do: 59
  def max(:hour, _next_value), do: 23
  def max(:day, 1), do: 31
  # TODO: Leap years?!
  def max(:day, 2), do: 28
  def max(:day, 3), do: 31
  def max(:day, 4), do: 30
  def max(:day, 5), do: 31
  def max(:day, 6), do: 30
  def max(:day, 7), do: 31
  def max(:day, 8), do: 31
  def max(:day, 9), do: 30
  def max(:day, 10), do: 31
  def max(:day, 11), do: 30
  def max(:day, 12), do: 31
  def max(:month, _next_value), do: 12
  def max(:weekday, _next_value), do: 7
end
