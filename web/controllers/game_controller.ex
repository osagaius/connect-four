defmodule ConnectFour.GameController do
  use ConnectFour.Web, :controller
  alias ConnectFour.{Game, Matrix}
  require Logger

  def create(conn, params) do
    %{resp_headers: resp_headers} = conn
    conn = %{conn| resp_headers: [{"content-type", "application/json"}|resp_headers]}

    {:ok, pid} = Game.start_link
    game = get_game(pid)

    Logger.warn(inspect game)
    send_resp(conn, 200, game |> Poison.encode!)
  end

  def make_move(conn, params) do
    %{resp_headers: resp_headers} = conn
    conn = %{conn| resp_headers: [{"content-type", "application/json"}|resp_headers]}

    Logger.debug("params #{inspect params}")

    {col, _} = params["column"] |> Integer.parse
    game_id = params["game_id"]

    pid = Game.get_game_process_name(game_id) |> Process.whereis

    case resp = Game.drop_disc(pid, col) do
      {:error, msg} ->
        send_resp(conn, 400, msg)
      {:ok, game} ->
        Logger.warn("drop disc resp #{inspect game}")
        game = game
        |> convert_board

        send_resp(conn, 200, game |> Poison.encode!)
    end
  end

  defp convert_keys(map) do
    map
    |> Map.new(fn {k, v} -> {Integer.to_string(k), v} end)
  end

  defp get_game(pid) do
    game = Game.get_game_status(pid)
    |> convert_board
  end

  defp convert_board(game) do
    board = game.board
    |> Map.new(fn {k, v} -> {Integer.to_string(k), v |> convert_keys} end)
    |> Matrix.to_list

    Logger.warn("game state #{inspect game}")

    game = game
    |> Map.put(:board, board)
  end

end
