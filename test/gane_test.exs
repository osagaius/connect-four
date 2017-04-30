defmodule ConnectFour.GameTest do
  use ExUnit.Case
  require Logger

  setup do
    player_1 = :player_1
    player_2 = :player_2
    player_1_color = "red"
    player_2_color = "blue"

    game_pid = case result = ConnectFour.Game.start_link do
      {:error, {:already_started, pid}} -> pid
      {:ok, pid} -> pid
      _ ->
        Logger.warn("couldn't start process result=#{inspect result}")
        nil
    end

    {:ok, %{
      game_pid: game_pid,
      player_1: player_1,
      player_2: player_2,
      player_1_color: player_1_color,
      player_2_color: player_2_color
    }}
  end

  test "game has valid default state", context do
    state = context.game_pid |> :sys.get_state
    assert state |> Enum.count > 0
  end

  test "updates board after 1 drop", context do
    player_name = context.player_1
    column = 1
    ConnectFour.Game.drop_disc(context.game_pid, column)
    #sleep for 50 seconds so message is sent and handled
    :timer.sleep(50)
    state = context.game_pid |> :sys.get_state
    assert state |> Map.get(:board) |> Map.get(column - 1) |> Map.values |> List.last == context.player_1_color
    assert state.turn == :player_2
  end

  test "updates board after 2 drops", context do
    player_1 = context.player_1
    player_2 = context.player_2
    column = 1
    ConnectFour.Game.drop_disc(context.game_pid, :player_1, column)
    ConnectFour.Game.drop_disc(context.game_pid, :player_2, column)
    state = context.game_pid |> :sys.get_state
    board = state |> Map.get(:board)
    assert board[column-1][5] == context.player_1_color
    assert board[column-1][4] == context.player_2_color
    assert state.turn == :player_1
  end

  test "determine win - horizontal", context do
    player_1 = context.player_1
    column = 1
    expected_status = %{status: :complete, winner: player_1}

    for n <- 1..4, do: ConnectFour.Game.drop_disc(context.game_pid, :player_1, n)

    #sleep for 50 ms so the process state is updated
    :timer.sleep(50)

    game_status = ConnectFour.Game.get_game_status(context.game_pid)
    assert game_status.status == expected_status.status
    assert game_status.winner == expected_status.winner
  end

  test "determine win - vertical", context do
    player = context.player_2
    column = 1
    expected_status = %{status: :complete, winner: player}

    for n <- 1..4, do: ConnectFour.Game.drop_disc(context.game_pid, :player_2, column)

    #sleep for 50 ms so the process state is updated
    :timer.sleep(50)

    game_status = ConnectFour.Game.get_game_status(context.game_pid)
    assert game_status.status == expected_status.status
    assert game_status.winner == expected_status.winner
  end

  test "determine win - ascending diagonal", context do
    player = context.player_2
    column = 1
    expected_status = %{status: :complete, winner: player}

    ConnectFour.Game.drop_disc(context.game_pid, :player_2, 1)

    ConnectFour.Game.drop_disc(context.game_pid, :player_1, 2)
    ConnectFour.Game.drop_disc(context.game_pid, :player_2, 2)

    ConnectFour.Game.drop_disc(context.game_pid, :player_2, 3)
    ConnectFour.Game.drop_disc(context.game_pid, :player_1, 3)
    ConnectFour.Game.drop_disc(context.game_pid, :player_2, 3)

    ConnectFour.Game.drop_disc(context.game_pid, :player_1, 4)
    ConnectFour.Game.drop_disc(context.game_pid, :player_2, 4)
    ConnectFour.Game.drop_disc(context.game_pid, :player_1, 4)
    ConnectFour.Game.drop_disc(context.game_pid, :player_2, 4)

    #sleep for 50 ms so the process state is updated
    :timer.sleep(50)

    game_status = ConnectFour.Game.get_game_status(context.game_pid)
    assert game_status.status == expected_status.status
    assert game_status.winner == expected_status.winner
  end

  test "determine win - descending diagonal", context do
    player = context.player_2
    column = 1
    expected_status = %{status: :complete, winner: player}

    ConnectFour.Game.drop_disc(context.game_pid, :player_2, 7)

    ConnectFour.Game.drop_disc(context.game_pid, :player_1, 6)
    ConnectFour.Game.drop_disc(context.game_pid, :player_2, 6)

    ConnectFour.Game.drop_disc(context.game_pid, :player_2, 5)
    ConnectFour.Game.drop_disc(context.game_pid, :player_1, 5)
    ConnectFour.Game.drop_disc(context.game_pid, :player_2, 5)

    ConnectFour.Game.drop_disc(context.game_pid, :player_1, 4)
    ConnectFour.Game.drop_disc(context.game_pid, :player_2, 4)
    ConnectFour.Game.drop_disc(context.game_pid, :player_1, 4)
    ConnectFour.Game.drop_disc(context.game_pid, :player_2, 4)

    #sleep for 50 ms so the process state is updated
    :timer.sleep(50)

    game_status = ConnectFour.Game.get_game_status(context.game_pid)
    assert game_status.status == expected_status.status
    assert game_status.winner == expected_status.winner
  end

  test "status should be a tie", context do
    expected_status = %{status: :tied, winner: nil}

    board = [
      [nil, "blue", "red", "blue", "red", "blue", "red"],
      ["blue", "red", "blue", "red", "blue", "red", "blue"],
      ["red", "blue", "red", "blue", "red", "blue", "red"],
      ["blue", "red", "blue", "red", "blue", "red", "blue"],
      ["red", "blue", "red", "blue", "red", "blue", "red"],
      ["blue", "red", "blue", "red", "blue", "red", "blue"]
    ]
    |> ConnectFour.Matrix.transpose
    |> ConnectFour.Matrix.from_list

    ConnectFour.Game.set_board(context.game_pid, board)

    #place red in the top left
    ConnectFour.Game.drop_disc(context.game_pid, :player_1, 1)

    #sleep for 50 ms so the game state is updated
    :timer.sleep(50)

    game_status = ConnectFour.Game.get_game_status(context.game_pid)
    assert game_status.status == expected_status.status
    assert game_status.winner == expected_status.winner
  end

  test "AI should block threat", context do
    opts = [mode: :single_player]
    {:ok, game_pid} = ConnectFour.Game.start_link(opts)
    ConnectFour.Game.reset_board(game_pid)

    board = [
      ["red", nil, nil, nil, nil, nil, nil],
      ["red", nil, nil, "red", nil, nil, nil],
      ["red", nil, nil, "blue", nil, nil, nil],
      ["blue", nil, nil, "red", "red", nil, nil],
      ["blue", nil, nil, "red", "red", nil, "blue"],
      ["blue", nil, "red", "red", "blue", "blue", "blue"]
    ]
    |> ConnectFour.Matrix.transpose
    |> ConnectFour.Matrix.from_list

    ConnectFour.Game.set_board(game_pid, board)
    game_status = ConnectFour.Game.get_game_status(game_pid)
    assert game_status.board == board

    expected_board = [
      ["red", nil, nil, nil, nil, nil, nil],
      ["red", nil, nil, "red", nil, nil, nil],
      ["red", nil, nil, "blue", nil, nil, "red"],
      ["blue", nil, nil, "red", "red", nil, "blue"],
      ["blue", nil, nil, "red", "red", nil, "blue"],
      ["blue", nil, "red", "red", "blue", "blue", "blue"]
    ]
    |> ConnectFour.Matrix.transpose
    |> ConnectFour.Matrix.from_list

    ConnectFour.Game.drop_disc(game_pid, :player_2, 7)

    #sleep for 50 ms so the game state is updated
    :timer.sleep(500)

    game_status = ConnectFour.Game.get_game_status(game_pid)
    assert game_status.board == expected_board
  end

end
