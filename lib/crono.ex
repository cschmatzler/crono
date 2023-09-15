defmodule Crono do
  @moduledoc """
  Documentation for `Crono`.
  """

  import Crono.Parser
  import NimbleParsec

  defparsec :parse_input,
            parts([
              tag(minute(), :minute),
              tag(hour(), :hour),
              tag(day(), :day),
              tag(month(), :month),
              tag(weekday(), :weekday)
            ])

  def parse(input) do
    parsed_input = parse_input(input)

    case parsed_input do
      {:ok, parsed_input, _, _, _, _} ->
        Enum.reduce(parsed_input, %Crono.Expression{}, fn {part, value}, expression ->
          Map.put(expression, part, value)
        end)

      error ->
        error
    end
  end
end
