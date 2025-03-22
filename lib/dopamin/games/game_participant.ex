defmodule Dopamin.Games.GameParticipants do
  use Ecto.Schema
  import Ecto.Changeset

  schema "game_participants" do
    field :user_id, :integer
    field :bet_amount, :integer
    field :status, :string, default: "active"
    field :result, :string
    field :reward_amount, :integer
    field :joined_at, :utc_datetime
    belongs_to :game, Dopamin.Games.Game

    timestamps()
  end

  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:game_id, :user_id, :bet_amount, :status, :result, :reward_amount, :joined_at])
    |> validate_required([:game_id, :user_id, :bet_amount, :joined_at])
    |> foreign_key_constraint(:game_id)
    |> unique_constraint([:game_id, :user_id], message: "이미 게임에 참가하셨습니다")
    |> validate_inclusion(:status, ~w(active completed cancelled), message: "유효하지 않은 상태입니다")
  end
end
