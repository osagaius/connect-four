defmodule ConnectFour.Router do
  use ConnectFour.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api" do
    pipe_through :api

    post "/game", ConnectFour.GameController, :create
    post "/game/make_move", ConnectFour.GameController, :make_move
  end

  scope "/", ConnectFour do
    pipe_through :browser # Use the default browser stack

    get "*path", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", ConnectFour do
  #   pipe_through :api
  # end
end
