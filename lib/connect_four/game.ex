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
  #
  # @doc """
  # Primes the cache by parsing files in the `priv/data` directory
  # """
  # def build_store() do
  #   data_path = Application.app_dir(:beans, "priv/data/#{@classification_filename}")
  #   case File.exists?(data_path) do
  #     true ->
  #       GenServer.cast(__MODULE__, {:build_store, [data_path]})
  #     _ ->
  #       msg = "Could not parse classification file in path #{data_path}"
  #       Logger.warn(msg)
  #       {:error, msg}
  #   end
  # end
  #
  # def get_classification(bean_name) do
  #   GenServer.call(__MODULE__, {:get_classification, [bean_name]})
  # end
  #
  # def add_bean(bean_name, classification) do
  #   Beans.Db.BeanClassification.add(bean_name, classification)
  # end
  #
  # #Handlers
  #
  # def handle_cast({:build_store, [data_path]}, state) do
  #   File.stream!(data_path)
  #   |> Stream.filter(fn(line) -> !is_nil(line) end)
  #   |> Stream.filter(fn(line) -> line != "" end)
  #   |> Stream.map(fn(line) -> String.strip(line) end)
  #   |> Stream.map(fn(line) -> line |> String.split(",") end)
  #   |> Stream.filter(fn(list) -> list |> Enum.count >= 2 end)
  #   |> Enum.each(fn(list) ->
  #     key = list |> Enum.at(0) |> String.downcase
  #     value = list |> Enum.at(1) |> String.downcase
  #     GenServer.cast(__MODULE__, {:add_item_to_store, [key, value]})
  #   end)
  #   {:noreply, state}
  # end
  #
  # def handle_cast({:add_item_to_store, [key, val]}, state) do
  #   Beans.Db.BeanClassification.add(key, val)
  #   {:noreply, state}
  # end
  #
  # def handle_call({:get_classification, [bean_name]}, from, state) do
  #   reply = case result = Beans.Db.BeanClassification.find_by_name(bean_name) do
  #     [head|tail] ->
  #       resp = result |> List.first |> Map.get(:classification)
  #       {:ok, resp}
  #     _ ->
  #       {:error, "Classification not found"}
  #   end
  #
  #   {:reply, reply, state}
  # end


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
