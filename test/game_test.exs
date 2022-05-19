defmodule GameTest do
  use ExUnit.Case
  doctest PerudexCord.Game

  alias PerudexCord.Game

  test "create/3 returns an initialized struct" do
    assert %Game{id: :a, creator_id: :first, game_name: "name"} = valid_game()
  end

  test "add_player/2 add player to list only once" do
    assert %Game{players: [:third, :second, :first]} =
             Game.create(:a, :first, "name")
             |> Game.add_player(:second)
             |> Game.add_player(:second)
             |> Game.add_player(:third)
  end

  test "remove_player/2 remove player from list if he's not creator" do
    assert %Game{players: [:first]} =
             Game.create(:a, :first, "name")
             |> Game.add_player(:second)
             |> Game.remove_player(:first)
             |> Game.remove_player(:second)
  end

  defp valid_game() do
    Game.create(:a, :first, "name")
  end
end
