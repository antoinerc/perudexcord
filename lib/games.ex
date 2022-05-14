defmodule PerudoCord.Games do
  alias PerudoCord.{Game, GameRegistry, Supervisors.GameSupervisor, InteractiveMessageHistory}

  def create(id, creator, game_name) do
    game = Game.create(id, creator, game_name)
    GameSupervisor.add_game_to_supervisor(game)
    game
  end

  def get(game_id) do
    game_id
    |> GameRegistry.lookup_game()
    |> case do
      {:ok, pid} -> GenServer.call(pid, :get)
      error -> error
    end
  end

  def start(game_id, player_id) do
    game_id
    |> GameRegistry.lookup_game()
    |> case do
      {:ok, pid} -> GenServer.call(pid, {:start, player_id})
      error -> error
    end
  end

  @spec delete(Game.game_id(), Game.discord_user_id()) :: :ok | {:error, atom}
  def delete(game_id, issued_by) do
    game_id
    |> GameRegistry.lookup_game()
    |> case do
      {:ok, pid} -> GenServer.call(pid, {:delete, issued_by})
      error -> error
    end
  end

  @spec add_player(Game.game_id(), Game.discord_user_id()) :: any
  def add_player(game_id, player_id) do
    game_id
    |> GameRegistry.lookup_game()
    |> case do
      {:ok, pid} -> GenServer.call(pid, {:add_player, player_id})
      error -> error
    end
  end

  def remove_player(game_id, player_id) do
    game_id
    |> GameRegistry.lookup_game()
    |> case do
      {:ok, pid} -> GenServer.call(pid, {:remove_player, player_id})
      error -> error
    end
  end

  def calza(message_id, player_id) do
    case InteractiveMessageHistory.lookup(player_id) do
      %{message_id: ^message_id, game_id: game_id} ->
        game_id
        |> GameRegistry.lookup_game()
        |> case do
          {:ok, pid} -> GenServer.call(pid, {:calza, player_id})
          error -> error
        end

      _ ->
        {:error, "Something bad happened"}
    end
  end

  def dudo(message_id, player_id) do
    case InteractiveMessageHistory.lookup(player_id) do
      %{message_id: ^message_id, game_id: game_id} ->
        game_id
        |> GameRegistry.lookup_game()
        |> case do
          {:ok, pid} -> GenServer.call(pid, {:dudo, player_id})
          error -> error
        end

      _ ->
        {:error, "Something bad happened"}
    end
  end

  def outbid(message_id, player_id, bid) do
    case InteractiveMessageHistory.lookup(player_id) do
      %{message_id: ^message_id, game_id: game_id} ->
        game_id
        |> GameRegistry.lookup_game()
        |> case do
          {:ok, pid} -> GenServer.call(pid, {:outbid, player_id, bid})
          error -> error
        end

      _ ->
        {:error, "Something bad happened"}
    end
  end
end
