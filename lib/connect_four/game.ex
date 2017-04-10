defmodule ConnectFour.Game do
  @moduledoc """
  Module to conduct a game.
  """
  use GenServer
  require Logger
  @board_columns 7
  @board_rows 6

  # Startup and Initialization
  def start_link(opts \\ []) do
    #TODO Support multiple game processes running simulteaneously
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    Logger.debug("#{__MODULE__} starting...")
    board = generate_default_board()

    state = %{
      board: board
    }

    {:ok, state}
  end

  #API
  @doc """
  Drops a disc into an available slot in the specified column.

  The specified column should be a number between 1 and 7
  """
  def drop_disc(player_name \\ "default", column_number) do
    internal_column_number = column_number-1
    GenServer.cast(__MODULE__, {:drop_disc, [player_name, internal_column_number]})
  end

  @doc """
  Resets the game board to its default state.
  """
  def reset_board() do
    GenServer.cast(__MODULE__, {:reset_game_board})
  end

  def handle_cast({:drop_disc, [player_name, column_number]}, state) do
    column = state.board |> Enum.at(column_number) |> elem(1)

    available_slots = column |> Enum.filter(fn{k, v} -> v == nil end) |> Enum.into(%{})
    board = case available_slots |> Enum.count do
      0 ->
        Logger.warn("No available slots in column #{column_number}")
        state.board
      _ ->
        slot = available_slots |> Map.keys |> List.last
        put_in(state.board[column_number][slot], player_name) |> Map.get(:board)
    end
    Logger.debug("Current game board #{inspect board}")

    {:noreply, %{state | board: board}}
  end

  def handle_cast({:reset_game_board}, state) do
    board = generate_default_board()

    {:noreply, %{state | board: board}}
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

end
