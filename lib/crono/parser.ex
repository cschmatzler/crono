defmodule Crono.Parser do
  @moduledoc """
  Helper functions to parse a cron expression, used by the parser in `Crono`.
  """

  import Crono.Utilities
  import NimbleParsec

  def fields(fields) do
    fields
    |> Enum.reverse()
    |> Enum.reduce(fn field, rest ->
      concat(
        field,
        concat(
          ignore(" " |> string() |> label("space")),
          rest
        )
      )
    end)
  end

  def minute, do: base(number(min(:minute), max(:minute)))
  def hour, do: base(number(min(:hour), max(:hour)))
  def day, do: base(number(min(:day), max(:day)))

  def month, do: [number(min(:month), max(:month)), month_as_letters()] |> choice() |> base()

  def weekday,
    do: [number(min(:weekday), max(:weekday)), weekday_as_letters()] |> choice() |> base()

  defp base(base) do
    choice([
      step(base),
      range(base),
      list(base),
      wildcard(),
      base
    ])
  end

  def wildcard do
    "*" |> string() |> replace(:*) |> label("wildcard")
  end

  def number(min, max) do
    "-"
    |> string()
    |> replace(:negative)
    |> optional()
    |> concat(integer(min: 1))
    |> label("number (#{min} - #{max})")
    |> post_traverse({__MODULE__, :number, [min, max]})
  end

  def step(base) do
    [base, wildcard()]
    |> choice()
    |> ignore(string("/"))
    |> concat(integer(min: 1))
    |> tag(:step)
    |> label("step")
    |> post_traverse({__MODULE__, :step, []})
  end

  def range(base) do
    [base, wildcard()]
    |> choice()
    |> ignore(string("-"))
    |> concat(base)
    |> tag(:range)
    |> label("range")
    |> post_traverse({__MODULE__, :range, []})
  end

  def list(base) do
    [base, wildcard()]
    |> choice()
    |> ignore(optional(string(",")))
    |> times(min: 2)
    |> tag(:list)
    |> label("list")
  end

  def number(rest, [number, :negative], context, line, offset, min, max),
    do: number(rest, [0 - number], context, line, offset, min, max)

  def number(_rest, [number], context, _line, _offset, min, max)
      when number >= min and number <= max,
      do: {[number], context}

  def number(_rest, [number], _context, _line, _offset, min, max),
    do: {:error, "number #{number} must be between #{min} and #{max}"}

  def step(_rest, [step: [start, step]], context, _line, _offset),
    do: {[step: {start, step}], context}

  def range(_rest, [range: [from, to]], context, _line, _offset) when to > from,
    do: {[range: {from, to}], context}

  def range(_rest, [range: [from, to]], _context, _line, _offset),
    do: {:error, "range start #{from} needs to be before end #{to}"}

  defp month_as_letters do
    choice([
      "JAN" |> string() |> replace(1),
      "FEB" |> string() |> replace(2),
      "MAR" |> string() |> replace(3),
      "APR" |> string() |> replace(4),
      "MAY" |> string() |> replace(5),
      "JUN" |> string() |> replace(6),
      "JUL" |> string() |> replace(7),
      "AUG" |> string() |> replace(8),
      "SEP" |> string() |> replace(9),
      "OCT" |> string() |> replace(10),
      "NOV" |> string() |> replace(11),
      "DEC" |> string() |> replace(12)
    ])
  end

  defp weekday_as_letters do
    choice([
      "SUN" |> string() |> replace(0),
      "MON" |> string() |> replace(1),
      "TUE" |> string() |> replace(2),
      "WED" |> string() |> replace(3),
      "THU" |> string() |> replace(4),
      "FRI" |> string() |> replace(5),
      "SAT" |> string() |> replace(6)
    ])
  end
end
