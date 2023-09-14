defmodule Crono.Parser do
  @moduledoc false
  import Crono.Parser.Utilities
  import NimbleParsec

  defparsec :parse,
            parts([
              tag(minute(), :minute),
              tag(hour(), :hour),
              tag(day(), :day),
              tag(month(), :month),
              tag(weekday(), :weekday)
            ])

  def to_expression(parts) do
    Enum.reduce(parts, %Crono.Expression{}, fn {part, value}, expression ->
      Map.put(expression, part, value)
    end)
  end
end
