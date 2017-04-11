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
    #TODO Support multiple game processes running simulteaneously for the same players
    opts_map = get_player_opts_map(opts)

    case opts_map |> Map.values |> Enum.all?(&(&1 != nil)) do
      true ->
        name = get_game_process_name(opts_map.player_1, opts_map.player_2)
        GenServer.start_link(__MODULE__, opts, name: name)
      _ ->
        Logger.warn("#{__MODULE__} error: both player names required to start game")
    end
  end

  def init(opts) do
    Logger.debug("#{__MODULE__} starting...")
    board = generate_default_board()

    state = %{
      board: board
    } |> Map.merge(get_player_opts_map(opts))

    {:ok, state}
  end

  #API
  @doc """
  Drops a disc into an available slot in the specified column.

  The specified column should be a number between 1 and 7
  """
  def drop_disc(pid, player_name, column_number) do
    internal_column_number = column_number-1
    GenServer.cast(pid, {:drop_disc, [player_name, internal_column_number]})
  end

  @doc """
  Resets the game board to its default state.
  """
  def reset_board(pid) do
    GenServer.cast(pid, {:reset_game_board})
  end

  def handle_cast({:drop_disc, [player_name, column_number]}, state) do
    Logger.debug("handle_cast drop_disc player_name=#{player_name}, column=#{column_number}")

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

    {:noreply, %{state | board: board}}
  end

  def handle_cast({:reset_game_board}, state) do
    board = generate_default_board()

    {:noreply, %{state | board: board}}
  end

  def get_game_process_name(player_1, player_2) do
    "#{__MODULE__}-#{player_1}v#{player_2}" |> String.to_atom
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

  defp get_player_opts_map(opts) do
    player_1 = opts[:player_1]
    player_2 = opts[:player_2]
    player_1_color = opts[:player_1_color]
    player_2_color = opts[:player_2_color]

    game_opts = [player_1: player_1, player_2: player_2, player_1_color: player_1_color, player_2_color: player_2_color]
    game_opts |> Enum.into(%{})
  end

end
