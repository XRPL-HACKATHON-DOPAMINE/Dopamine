defmodule Dopamin.Games.TopPlayer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "top_players" do
    field :rank, :integer
    field :username, :string
    field :win_rate, :float
    field :games_played, :integer
    field :icon, :string
    belongs_to :game, Dopamin.Games.Game

    timestamps()
  end

  def changeset(top_player, attrs) do
    top_player
    |> cast(attrs, [:rank, :username, :win_rate, :games_played, :icon, :game_id])
    |> validate_required([:rank, :username, :win_rate, :games_played, :icon, :game_id])
    |> foreign_key_constraint(:game_id)
  end
end
