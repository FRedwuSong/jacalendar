defmodule Jacalendar.Itinerary do
  defstruct [:title, :date_range, :metadata, days: []]

  defmodule Day do
    defstruct [:date, :weekday, :title, items: []]
  end

  defmodule Item do
    defstruct [:time, :description, sub_items: []]
  end
end
