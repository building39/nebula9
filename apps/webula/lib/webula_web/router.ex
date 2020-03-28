defmodule WebulaWeb.Router do
  use WebulaWeb, :router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", WebulaWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

end
