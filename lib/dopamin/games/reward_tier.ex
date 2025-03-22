defmodule Dopamin.Games.RewardTier do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reward_tiers" do
    field :rank, :string
    field :condition, :string
    field :reward, :integer
    belongs_to :game, Dopamin.Games.Game

    timestamps()
  end

  def changeset(reward_tier, attrs) do
    reward_tier
    |> cast(attrs, [:rank, :condition, :reward, :game_id])
    |> validate_required([:rank, :condition, :reward, :game_id])
    |> foreign_key_constraint(:game_id)
  end
end
