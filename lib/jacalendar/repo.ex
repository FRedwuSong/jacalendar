defmodule Jacalendar.Repo do
  use Ecto.Repo,
    otp_app: :jacalendar,
    adapter: Ecto.Adapters.Postgres
end
