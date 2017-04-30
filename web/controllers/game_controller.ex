defmodule ConnectFour.GameController do
  use ConnectFour.Web, :controller
  alias ConnectFour.{Game, Matrix}
  require Logger

  def create(conn, params) do
    %{resp_headers: resp_headers} = conn
    conn = %{conn| resp_headers: [{"content-type", "application/json"}|resp_headers]}

    {:ok, pid} = Game.start_link
    game = Game.get_game_status(pid)

    board = game.board
    |> Map.new(fn {k, v} -> {Integer.to_string(k), v |> convert_keys} end)
    |> Matrix.to_list

    game = game
    |> Map.put(:board, board)

    Logger.warn(inspect game)
    send_resp(conn, 200, game |> Poison.encode!)
  end

  defp convert_keys(map) do
    map
    |> Map.new(fn {k, v} -> {Integer.to_string(k), v} end)
  end


end
