defmodule Crono.Utilities do
  @moduledoc false

  def min(:minute), do: 0
  def min(:hour), do: 0
  def min(:day), do: 1
  def min(:month), do: 1
  def min(:weekday), do: 0
  def max(:minute), do: 59
  def max(:hour), do: 23
  def max(:day), do: 31
  def max(:month), do: 12
  def max(:weekday), do: 7
end
