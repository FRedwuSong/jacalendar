defmodule JacalendarWeb.PageController do
  use JacalendarWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
