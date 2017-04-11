defmodule ConnectFour.GameTest do
  use ExUnit.Case

  setup do
    player_1 = "player_1-#{:os.system_time(:seconds)}"
    player_2 = "player_2-#{:os.system_time(:seconds)}"
    player_1_color = "red"
    player_2_color = "blue"
    game_opts = [player_1: player_1, player_2: player_2, player_1_color: player_1_color, player_2_color: player_2_color]
    {:ok, game_pid} = ConnectFour.Game.start_link(game_opts)

    {:ok, %{
      game_pid: game_pid,
      player_1: player_1,
      player_2: player_2
    }}
  end

  test "game has valid default state", context do
    state = context.game_pid |> :sys.get_state
    assert state |> Enum.count > 0
  end

  test "updates board after 1 drop", context do
    player_name = context.player_1
    column = 1
    ConnectFour.Game.drop_disc(context.game_pid, player_name, column)
    state = context.game_pid |> :sys.get_state
    assert state |> Map.get(:board) |> Map.get(column - 1) |> Map.values |> List.last == player_name
  end

  test "updates board after 2 drop", context do
    player_1 = context.player_1
    player_2 = context.player_2
    column = 1
    ConnectFour.Game.drop_disc(context.game_pid, player_1, column)
    ConnectFour.Game.drop_disc(context.game_pid, player_2, column)
    board = context.game_pid |> :sys.get_state |> Map.get(:board)
    assert board[column-1][5] == player_1
    assert board[column-1][4] == player_2
  end
end
