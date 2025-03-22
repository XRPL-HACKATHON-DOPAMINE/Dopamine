defmodule Dopamin.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :category, :string
    field :name, :string
    field :description, :string
    field :players, :integer
    field :xrp, :integer
    field :win_rate, :float
    field :plays, :integer
    field :image, :string

    # 게임 종료 시간 필드
    field :end_time, :utc_datetime

    has_many :rules, Dopamin.Games.GameRule
    has_many :betting_options, Dopamin.Games.BettingOption
    has_many :reward_tiers, Dopamin.Games.RewardTier
    has_many :top_players, Dopamin.Games.TopPlayer
    has_many :participants, Dopamin.Games.GameParticipants

    timestamps()
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, [
      :category,
      :name,
      :description,
      :players,
      :xrp,
      :win_rate,
      :plays,
      :image,
      :end_time
    ])
    |> validate_required([
      :category,
      :name,
      :description,
      :players,
      :xrp,
      :win_rate,
      :plays,
      :image,
      :end_time
    ])
  end
end
