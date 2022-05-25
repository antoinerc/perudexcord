defmodule PerudexCord.DiscordCmdTokens do
  def prefix(), do: "!per"
  def help_cmd(), do: prefix() <> " help"
  def rules_short_cmd(), do: prefix() <> " -r"
  def rules_cmd(), do: prefix() <> " --rules"
  def join_reaction(), do: "👍"
  def calza_reaction(), do: "👌"
  def dudo_reaction(), do: "👎"
  def start_reaction(), do: "▶️"
  def cancel_reaction(), do: "❌"
  def congratulations_reaction(), do: "🏆"
  def presentation(), do: ~s"""
  perudexcord - a bot to play Perudo inside of Discord [beta]

  USAGE
    !per [-r | --rules] <game-name>

  EXAMPLES
    `!per my-game`
    Start a game named 'my-game'

    `!per --rules`
    Reply to your message with the rules of the game
  """

  def rules(), do: ~s"""
  In a game of Perudo, each player starts with 5 dice in his hand.
  Players are betting on the sum of the count of a specific die value.
  When you increase the bid, you are saying there is AT LEAST the number of specified die value

  **Playing the game**
  The game is played in rounds. The player who goes first in a round sets the starting bid.
  From then, each player has three possible move:
  **Outbid**:
    - Increase the count of the current die value and/or or increase the die value
    - Reduce the current count by turning it into a Paco bid
      - Pacos (1) are aces/wilds
      - To turn a bid into a Paco bid, the count must be at least the current count divided by two rounded up
        - Ex: [4 x 5 turns into 2 x 1], [9 x 3 turns into 5 x 1]
    - Increase the current count and/or change the current value by turning a Paco bid into a normal bid, the count must be at least twice the current count plus one. You decide the value
        - Ex: [3 x 1 turns into 7 x 5], [1 x 1 turns into 3 x 2]
  **Calza #{calza_reaction()}**: if you believe the current bid to be exact you can call Calza
    - If you are right, you will add a die back to your hand, unless your hand is already full
    - If you are wrong, you will lose a die from your hand
    - In both cases, you will start the next round
  **Dudo #{dudo_reaction()}**: if you believe the bid made by the last player is too ambitious
    - The player that is wrong will lose a die and start the next round

  Both Calza and Dudo end the round.

  **End of round**
  When a round end, the players hands are revealed and the bid is validated.
  The bid is calculated using the sum of all the die of current value PLUS the wildcards.
  Example:
    The current bid is 4 x 3
    - Hand 1 : [3, 3, 5]
    - Hand 2 : [2, 5, 3, 4, 1]
    The bid is spot on because Hand 1 contains 2 x 3, and Hand 2 contains 1 x 3 + 1 x 1, making it 4 x 3.

  **End of game**
  The last player standing with at least one die is crowned winner of the game #{congratulations_reaction()}.
  """
end
