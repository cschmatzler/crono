# Crono

[![Hex.pm](https://img.shields.io/hexpm/v/crono.svg)](https://hex.pm/packages/crono) [![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/crono/)

<!-- MDOC !-->

Crono is a library to work with cron expressions.  

It parses cron expressions, allows calculating future runs of the schedule, and representing an
expression as a human-readable description.

## Basic usage

```elixir
iex> Crono.parse("5 * * * *")
{:ok, %Crono.Expression{minute: 5, hour: :*, day: :*, month: :*, weekday: :*}}

iex> ~e[5 * * * *]
%Crono.Expression{minute: 5, hour: :*, day: :*, month: :*, weekday: :*}

iex> Crono.Schedule.get_next_date(~e[5 * * * *], ~N[2023-09-01T10:00:00])
~N[2023-09-01T10:05:00]

iex> Crono.Expression.describe(~e[5 * * * *])
"Every 5 minutes"
```

## Installation

To start off, add `crono` to the list of your dependencies:
```elixir
def deps do
  {:crono, "~> 0.1"},
end
```

If you want to use the `~e[]` sigil for your expressions, also add `import Crono.Expression` to
your module.


