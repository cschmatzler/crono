defmodule Crono.ScheduleTest do
  use ExUnit.Case, async: true

  import Crono.Expression
  import Crono.Schedule

  doctest Crono.Schedule

  describe "get_next_date/2" do
    test "returns next date for a cron expression" do
      assert Crono.Schedule.get_next_date(~e[* 0 * * *], ~N[2023-09-01T03:00:00]) ==
               ~N[2023-09-02T00:00:00]
    end

    test "returns the next date when using a step" do
      assert Crono.Schedule.get_next_date(~e[0 1/2 * * *], ~N[2023-09-01T00:00:00]) ==
               ~N[2023-09-01T01:00:00]

      assert Crono.Schedule.get_next_date(~e[0 1/2 * * *], ~N[2023-09-01T02:00:00]) ==
               ~N[2023-09-01T03:00:00]

      assert Crono.Schedule.get_next_date(~e[0 1/2 * * *], ~N[2023-09-01T04:00:00]) ==
               ~N[2023-09-01T05:00:00]

      assert Crono.Schedule.get_next_date(~e[0 1/2 * * *], ~N[2023-09-01T23:30:00]) ==
               ~N[2023-09-02T01:00:00]
    end

    test "returns the next date when using a range" do
      assert Crono.Schedule.get_next_date(~e[0 1-4 * * *], ~N[2023-09-01T00:00:00]) ==
               ~N[2023-09-01T01:00:00]

      assert Crono.Schedule.get_next_date(~e[0 1-4 * * *], ~N[2023-09-01T01:30:00]) ==
               ~N[2023-09-01T02:00:00]

      assert Crono.Schedule.get_next_date(~e[0 1-4 * * *], ~N[2023-09-01T02:30:00]) ==
               ~N[2023-09-01T03:00:00]

      assert Crono.Schedule.get_next_date(~e[0 1-4 * * *], ~N[2023-09-01T03:30:00]) ==
               ~N[2023-09-01T04:00:00]

      assert Crono.Schedule.get_next_date(~e[0 1-4 * * *], ~N[2023-09-01T04:30:00]) ==
               ~N[2023-09-02T01:00:00]
    end

    test "returns the next date when using a list" do
      assert Crono.Schedule.get_next_date(~e[0 1,5,7 * * *], ~N[2023-09-01T00:00:00]) ==
               ~N[2023-09-01T01:00:00]

      assert Crono.Schedule.get_next_date(~e[0 1,5,7 * * *], ~N[2023-09-01T02:00:00]) ==
               ~N[2023-09-01T05:00:00]

      assert Crono.Schedule.get_next_date(~e[0 1,5,7 * * *], ~N[2023-09-01T03:00:00]) ==
               ~N[2023-09-01T05:00:00]

      assert Crono.Schedule.get_next_date(~e[0 1,5,7 * * *], ~N[2023-09-01T06:00:00]) ==
               ~N[2023-09-01T07:00:00]

      assert Crono.Schedule.get_next_date(~e[0 1,5,7 * * *], ~N[2023-09-01T12:00:00]) ==
               ~N[2023-09-02T01:00:00]
    end

    test "returns the next date for a minute" do
      assert Crono.Schedule.get_next_date(~e[20 * * * *], ~N[2023-09-01T01:00:00]) ==
               ~N[2023-09-01T01:20:00]
    end

    test "returns the next date for an hour" do
      assert Crono.Schedule.get_next_date(~e[* 20 * * *], ~N[2023-09-01T01:00:00]) ==
               ~N[2023-09-01T20:00:00]
    end

    test "returns the next date for a day" do
      assert Crono.Schedule.get_next_date(~e[* * 15 * *], ~N[2023-09-01T00:00:00]) ==
               ~N[2023-09-15T00:00:00]
    end

    test "flips over to next hour, setting minute to 0" do
      assert Crono.Schedule.get_next_date(~e[0 * * * *], ~N[2023-09-01T02:59:00]) ==
               ~N[2023-09-01T03:00:00]
    end

    test "flips over to next day, setting hour and minute to 0" do
      assert Crono.Schedule.get_next_date(~e[0 0 * * *], ~N[2023-09-01T23:59:00]) ==
               ~N[2023-09-02T00:00:00]
    end

    test "flips over to next month, setting day to 1, hour and minute to 0" do
      assert Crono.Schedule.get_next_date(~e[0 0 1 * *], ~N[2023-09-30T23:59:00]) ==
               ~N[2023-10-01T00:00:00]
    end

    test "flips over to next year, setting month and day to 1, hour and minute to 0" do
      assert Crono.Schedule.get_next_date(~e[0 0 1 1 *], ~N[2023-12-31T23:59:00]) ==
               ~N[2024-01-01T00:00:00]
    end

    test "respects months having different amount of days" do
      assert Crono.Schedule.get_next_date(~e[0 0 1 * *], ~N[2023-09-30T23:59:00]) ==
               ~N[2023-10-01T00:00:00]

      assert Crono.Schedule.get_next_date(~e[0 0 1 * *], ~N[2023-02-28T23:59:00]) ==
               ~N[2023-03-01T00:00:00]

      assert Crono.Schedule.get_next_date(~e[0 0 1 * *], ~N[2023-01-31T23:59:00]) ==
               ~N[2023-02-01T00:00:00]
    end

    test "respects leap years" do
      assert Crono.Schedule.get_next_date(~e[0 0 * * *], ~N[2024-02-28T23:59:00]) ==
               ~N[2024-02-29T00:00:00]
    end
  end
end
