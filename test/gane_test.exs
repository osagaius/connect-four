defmodule ConnectFour.GameTest do
  use ExUnit.Case

  setup do
    ConnectFour.Game.reset_board()
    {:ok, %{}}
  end

  test "game has valid default state", context do
    state = ConnectFour.Game |> Process.whereis |> :sys.get_state
    assert state |> Enum.count > 0
  end

  test "updates board after 1 drop", context do
    player_name = "test1"
    column = 1
    ConnectFour.Game.drop_disc(player_name, column)
    state = ConnectFour.Game |> Process.whereis |> :sys.get_state
    assert state |> Map.get(:board) |> Map.get(column - 1) |> Map.values |> List.last == player_name
  end

  test "updates board after 2 drop", context do
    player_1 = "test1"
    player_2 = "test2"
    column = 1
    ConnectFour.Game.drop_disc(player_1, column)
    ConnectFour.Game.drop_disc(player_2, column)
    board = ConnectFour.Game |> Process.whereis |> :sys.get_state |> Map.get(:board)
    assert board[column-1][5] == player_1
    assert board[column-1][4] == player_2
  end
end
