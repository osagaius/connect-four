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
    #TODO Support multiple game processes running simulteaneously for the same players
    #TODO Name the games based on some unique identifier i.e. UUID
    #TODO Excise usage of player names

    game_id = UUID.uuid1()
    name = get_game_process_name(game_id)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    Logger.debug("#{__MODULE__} starting...")
    board = generate_default_board()

    state = %{
      board: board,
      status: nil,
      turn: :player_1,
      winner: nil
    }

    {:ok, state}
  end

  #API
  @doc """
  Drops a disc into an available slot in the specified column.

  The specified column should be a number between 1 and 7
  """
  def drop_disc(pid, player, column_number) do
    internal_column_number = column_number-1
    GenServer.cast(pid, {:drop_disc, [player, internal_column_number]})
  end

  @doc """
  Resets the game board to its default state.
  """
  def reset_board(pid) do
    GenServer.cast(pid, {:reset_game_board})
  end

  @doc """
  Set the game board to the specified board.
  """
  def set_board(pid, board) do
    GenServer.cast(pid, {:set_game_board, [board]})
  end

  @doc """
  Gets the current status of the game.
  """
  def get_game_status(pid) do
    GenServer.call(pid, {:get_game_status})
  end

  def handle_cast({:drop_disc, [player, column_number]}, state) do
    Logger.debug("handle_cast drop_disc player=#{player}, column=#{column_number}")
    color = get_player_color(player)

    column = state.board |> Enum.at(column_number) |> elem(1)

    available_slots = column |> Enum.filter(fn{k, v} -> v == nil end) |> Enum.into(%{})
    board = case available_slots |> Enum.count do
      0 ->
        Logger.warn("No available slots in column #{column_number}")
        state.board
      _ ->
        slot = available_slots |> Map.keys |> List.last
        put_in(state.board[column_number][slot], color) |> Map.get(:board)
    end

    Matrix.to_list(board) |> Matrix.print
    Matrix.to_list(board) |> Matrix.transpose |> Matrix.print

    #TODO determine/update game state i.e. win/lose/tie etc.
    GenServer.cast(self(), {:update_status, [color, board, player]})

    {:noreply, %{state | board: board}}
  end

  def handle_cast({:reset_game_board}, state) do
    board = generate_default_board()

    {:noreply, %{state | board: board}}
  end

  def handle_cast({:set_game_board, [board]}, state) do
    {:noreply, %{state | board: board}}
  end

  def handle_cast({:update_status, [color, board, player]}, state) do
    {status, winner} = cond do
      count_empty_spaces(board) == 0 ->
        {:tie, nil}
      four_connected?(color, board) -> {:complete, player}
      true -> {nil, nil}
    end

    {:noreply, %{state | status: status, winner: winner}}
  end

  def handle_call({:get_game_status}, from, state) do
    reply = %{status: state.status, winner: state.winner}
    {:reply, reply, state}
  end

  #Private Helpers
  defp generate_default_board() do
    board_columns = for n <- 0..(@board_columns-1), do: %{n => generate_default_board_rows()}
    board_columns |> Enum.reduce(fn(x, acc) -> Map.merge(x, acc) end)
  end

  defp generate_default_board_rows() do
    rows = for n <- 0..(@board_rows-1), do: %{n => nil}
    rows |> Enum.reduce(fn(x, acc) -> Map.merge(x, acc) end)
  end

  def get_game_process_name(id) do
    "#{__MODULE__}-#{id}" |> String.to_atom
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
    |> Enum.filter(&(&1 == color))
    |> Enum.count == 4
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
end
