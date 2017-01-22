defmodule Squints.PageController do
  use Squints.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
