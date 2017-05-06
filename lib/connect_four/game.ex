defmodule ConnectFour.Game do
  @moduledoc """
  Module to conduct a game.
  """
  use GenServer
  require Logger
  alias ConnectFour.Matrix
  @board_columns 7
  @board_rows 6

  # Startup and Initialization
  def start_link(opts \\ []) do
    game_id = UUID.uuid1()
    name = get_game_process_name(game_id)
    GenServer.start_link(__MODULE__, opts |> Keyword.put(:game_id, game_id), name: name)
  end

  def init(opts) do
    Logger.debug("#{__MODULE__} starting...")
    board = generate_default_board()
    mode = opts[:mode]

    state = %{
      board: board,
      status: nil,
      turn: :player_1,
      winner: nil,
      mode: mode,
      player: 1,
      game_id: opts[:game_id]
    }

    state = case mode do
      :single_player ->
        # make the initial move as the AI,
        # in the center column
        internal_column_number = 3
        color = get_player_color(:player_1)
        get_new_state(:player_1, color, state.board, internal_column_number, state)

      _ ->
        #don't do anything
        state
    end

    IO.puts "Turn: #{state.turn}"

    {:ok, state}
  end

  #API

  @doc """
  Drops a disc into an available slot in the specified column.

  The specified column should be a number between 1 and 7
  """
  def drop_disc(pid, column_number) do
    valid_columns = 1..@board_columns |> Enum.to_list
    cond do
      !Enum.member?(valid_columns, column_number) ->
        msg = "Invalid column number. Try on of these #{inspect valid_columns}"
        Logger.warn(msg)
        {:error, msg}
      true ->
        internal_column_number = column_number-1
        GenServer.call(pid, {:drop_disc, [pid, internal_column_number]})
    end
  end

  @doc """
  Drops a disc into an available slot in the specified column, for the specified player.

  The specified column should be a number between 1 and 7
  """
  def drop_disc(pid, player, column_number) do
    internal_column_number = column_number-1
    GenServer.call(pid, {:drop_disc, [pid, player, internal_column_number]})
  end

  @doc """
  Set the game board to the specified board.
  """
  def set_board(pid, board) do
    GenServer.call(pid, {:set_game_board, [board]})
  end

  @doc """
  Gets the current status of the game.
  """
  def get_game_status(pid) do
    GenServer.call(pid, {:get_game_status})
  end

  def get_game_process_name(id) do
    "#{__MODULE__}-#{id}" |> String.to_atom
  end

  def get_winner(board) do
    cond do
      four_connected?(get_player_color(:player_1), board) ->
        1
      four_connected?(get_player_color(:player_2), board) ->
        2
      true ->
        nil
    end
  end

  def generate_default_board() do
    board_columns = for n <- 0..(@board_columns-1), do: %{n => generate_default_board_rows()}
    board_columns |> Enum.reduce(fn(x, acc) -> Map.merge(x, acc) end)
  end

  #Handlers

  def handle_call({:drop_disc, [pid, column_number]}, _from, state) do
    player = state.turn
    color = get_player_color(player)

    state = get_new_state(player, color, state.board, column_number, state)

    {:reply, {:ok, state}, state}
  end

  def handle_call({:drop_disc, [pid, player, column_number]}, _from, state) do
    color = get_player_color(player)

    state = get_new_state(player, color, state.board, column_number, state)

    {:reply, state, state}
  end

  def handle_call({:set_game_board, [board]}, _from, state) do
    state = %{state | board: board}
    {:reply, {:ok, state}, state}
  end

  def handle_call({:get_game_status}, from, state) do
    reply = state
    {:reply, reply, state}
  end

  #Private Helpers
  defp get_new_state(player, color, board, column_number, state) do
    state = case state.status do
      nil ->
        board = update_board(column_number, color, board)

        turn = get_next_turn(player)
        player = get_player_number(player)

        #print board
        IO.puts "Current board"
        #Matrix.to_list(board) |> Matrix.print
        Matrix.to_list(board) |> Matrix.transpose |> Matrix.print

        {status, winner} = cond do
          count_empty_spaces(board) == 0 ->
            Logger.warn "GAME OVER : tie"
            {:tied, nil}
          four_connected?(color, board) ->
            Logger.warn "GAME OVER : #{player} has won"
            {:complete, player}
          true ->
            Logger.warn("game still in progress")
            {nil, nil}
        end

        IO.puts "Turn: #{turn}"

        # make a move if it is the computer's turn
        # and we're in single player mode
        case state.mode == :single_player && turn == :player_1 do
          true ->
            color = get_player_color(turn)
            col = make_move_0(board) - 1
            Logger.warn("current pieces at col #{inspect board[col]}")

            get_new_state(turn, color, board, col, state)
          _ ->
            %{state | board: board, turn: turn, winner: winner, status: status}
        end
        
      _ ->
        Logger.warn("Game state is #{state.status} and no action can be taken")
        state
    end
  end

  defp make_move_0(board) do
    # find threats (possible wins for the other player)
    opponent_wins = find_wins(get_player_color(:player_2), board)

    # take first threat
    threat_column_number = case opponent_wins do
      [head|tail] -> head + 1
      _ -> nil
    end

    # find wins for self
    self_wins = find_wins(get_player_color(:player_1), board)

    # take first win
    self_win_column_number = case self_wins do
      [head|tail] -> head + 1
      _ -> nil
    end

    # block a threat, execute a self-win, or use a random column
    column = (threat_column_number || self_win_column_number || :rand.uniform(@board_columns))
  end

  defp find_wins(color, board) do
    # updates the board by dropping a disc
    # in each column and checks if a win exists
    # if a win exists, return the columns
    boards = for n <- 0..(@board_columns-1), do: {n, update_board(n, color, board)}

    boards
    |> Enum.filter(fn{col, board} -> four_connected?(color, board) end)
    |> Enum.map(fn{col, board} -> col end)
  end

  defp update_board(column_number, color, board) do
    Logger.warn("attempting to update board column_number=#{column_number} color=#{color} board=#{inspect board}")

    valid_columns = 0..(@board_columns-1) |> Enum.to_list
    cond do
      !Enum.member?(valid_columns, column_number) ->
        msg = "Invalid column number."
        Logger.warn(msg)
        board
      true ->
        column = board |> Enum.at(column_number) |> elem(1)

        available_slots = column |> Enum.filter(fn{k, v} -> v == nil end) |> Enum.into(%{})

        case available_slots |> Enum.count do
          0 ->
            Logger.warn("No available slots in column #{column_number}")
            board
          _ ->
            slot = available_slots |> Map.keys |> List.last
            put_in(board[column_number][slot], color)
        end
    end

  end

  defp generate_default_board_rows() do
    rows = for n <- 0..(@board_rows-1), do: %{n => nil}
    rows |> Enum.reduce(fn(x, acc) -> Map.merge(x, acc) end)
  end

  defp four_connected?(color, board) do
    cond do
      horizontal_win?(color, board) ->
        Logger.debug("horizontal win")
        true
      vertical_win?(color, board) ->
        Logger.debug("vertical win")
        true
      ascending_diagnonal_win?(color, board) ->
        Logger.debug("ascending diagnonal win")
        true
      descending_diagnonal_win?(color, board) ->
        Logger.debug("descending diagnonal win")
        true
      true -> false
    end
  end

  defp horizontal_win?(color, board) do
    Matrix.to_list(board)
    |> Matrix.transpose
    |> Enum.any?(fn(list) -> list |> contains_four?(color) end)
  end

  defp vertical_win?(color, board) do
    Matrix.to_list(board)
    |> Enum.any?(fn(list) -> list |> contains_four?(color) end)
  end

  defp ascending_diagnonal_win?(color, board) do
    results = 2..@board_columns-1 |> Enum.to_list |> Enum.map(fn(i) ->
      check_rows_ascending(i, board, color)
    end)

    results |> Enum.any?(&(&1))
  end

  defp descending_diagnonal_win?(color, board) do
    results = 2..@board_columns-1 |> Enum.to_list |> Enum.map(fn(i) ->
      check_rows_descending(i, board, color)
    end)

    results |> Enum.any?(&(&1))
  end

  defp contains_four?(list, color) do
    list
    |> Enum.chunk_by(fn arg -> arg end)
    |> Enum.any?(fn(chunk) ->
      chunk
      |> Enum.filter(&(&1 == color))
      |> Enum.count == 4
    end)
  end

  defp check_rows_ascending(column, board, color) do
    results = 0..@board_rows-3 |> Enum.to_list |> Enum.map(fn(row) ->
      [
        board[column][row],
        board[column-1][row+1],
        board[column-2][row+2],
        board[column-3][row+3]
      ] |> Enum.all?(&(&1) == color)
    end)

    results |> Enum.any?(&(&1))
  end

  defp check_rows_descending(column, board, color) do
    results = 2..@board_rows-1 |> Enum.to_list |> Enum.map(fn(row) ->
      [
        board[column][row],
        board[column-1][row-1],
        board[column-2][row-2],
        board[column-3][row-3]
      ] |> Enum.all?(&(&1) == color)
    end)

    results |> Enum.any?(&(&1))
  end

  defp count_empty_spaces(board) do
    Matrix.to_list(board)
    |> List.flatten
    |> Enum.filter(&(&1 == nil))
    |> Enum.count
  end

  defp get_player_color(player) do
    case player do
      :player_1 -> "red"
      :player_2 -> "blue"
    end
  end

  defp get_next_turn(current) do
    case current do
      :player_1 -> :player_2
      :player_2 -> :player_1
    end
  end

  defp get_player_number(current) do
    case current do
      :player_1 -> 1
      :player_2 -> 2
    end
  end
end
