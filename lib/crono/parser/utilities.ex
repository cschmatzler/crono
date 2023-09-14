defmodule Crono.Parser.Utilities do
  @moduledoc false
  import NimbleParsec

  def parts(parts) do
    parts
    |> Enum.reverse()
    |> Enum.reduce(fn part, rest ->
      concat(
        part,
        concat(
          ignore(" " |> string() |> label("space")),
          rest
        )
      )
    end)
  end

  def minute, do: base(number(0, 59))
  def hour, do: base(number(0, 23))
  def day, do: base(number(1, 31))

  def month, do: [number(1, 12), month_as_letters()] |> choice() |> base()

  def weekday, do: [number(0, 7), weekday_as_letters()] |> choice() |> base()

  defp base(base) do
    choice([
      wildcard(),
      step(base),
      range(base),
      list(base),
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
    base
    |> ignore(string("/"))
    |> concat(integer(min: 1))
    |> tag(:step)
    |> label("step")
  end

  def range(base) do
    base
    |> ignore(string("-"))
    |> concat(base)
    |> tag(:range)
    |> label("range")
    |> post_traverse({__MODULE__, :range, []})
  end

  def list(base) do
    base
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

  def range(_rest, [range: [from, to]], context, _line, _offset) when to > from,
    do: {[range: [from, to]], context}

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