defmodule Crono do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  import Crono.Parser
  import NimbleParsec

  defparsecp(
    :parse_input,
    fields([
      tag(minute(), :minute),
      tag(hour(), :hour),
      tag(day(), :day),
      tag(month(), :month),
      tag(weekday(), :weekday)
    ])
  )

  @doc """
  Parses a cron expression, returning a `Crono.CronExpression` struct if successful.

  ## Examples

  ```elixir
  iex> Crono.parse("* * * * *")
  {:ok, %Crono.Expression{minute: :*, hour: :*, day: :*, month: :*, weekday: :*}}

  iex> Crono.parse("5 * * * *")
  {:ok, %Crono.Expression{minute: 5, hour: :*, day: :*, month: :*, weekday: :*}}

  iex> Crono.parse("5/10 * * * *")
  {:ok,%Crono.Expression{minute: [step: {5, 10}], hour: :*, day: :*, month: :*, weekday: :*}}

  iex> Crono.parse("15-45 * * * *")
  {:ok, %Crono.Expression{minute: [range: {15, 45}], hour: :*, day: :*, month: :*, weekday: :*}}

  iex> Crono.parse("15,45 * * * *")
  {:ok, %Crono.Expression{minute: [list: [15, 45]], hour: :*, day: :*, month: :*, weekday: :*}}

  iex> Crono.parse("15,45 */6 14,28 * *")
  {:ok, %Crono.Expression{minute: [list: [15, 45]], hour: [step: {:*, 6}], day: [list: [14, 28]], month: :*, weekday: :*}}

  iex> Crono.parse("0 0 1 JAN *")
  {:ok, %Crono.Expression{minute: 0, hour: 0, day: 1, month: 1, weekday: :*}}

  iex> Crono.parse("0 0 * * WED")
  {:ok, %Crono.Expression{minute: 0, hour: 0, day: :*, month: :*, weekday: 3}}
  ```
  """
  def parse(input) do
    parsed_input = parse_input(input)

    case parsed_input do
      {:ok, parsed_input, _, _, _, _} ->
        expression =
          Enum.reduce(parsed_input, %Crono.Expression{}, fn
            {field, [:*]}, expression ->
              Map.put(expression, field, :*)

            {field, [value]}, expression when is_integer(value) ->
              Map.put(expression, field, value)

            {field, value}, expression ->
              Map.put(expression, field, value)
          end)

        {:ok, expression}

      {:error, error, _, _, _, _} ->
        {:error, error}
    end
  end

  def parse!(input) do
    case parse(input) do
      {:ok, %Crono.Expression{} = expression} -> expression
      {:error, error} -> raise error
    end
  end
end
