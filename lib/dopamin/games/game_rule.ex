defmodule Dopamin.Games.GameRule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "game_rules" do
    field :rule, :string
    belongs_to :game, Dopamin.Games.Game

    timestamps()
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [:rule, :game_id])
    |> validate_required([:rule, :game_id])
    |> foreign_key_constraint(:game_id)
  end
end
