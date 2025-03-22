defmodule Dopamin.Repo.Migrations.CreateGameParticipants do
  use Ecto.Migration

  def up do
    create table(:game_participants) do
      add :game_id, :integer, null: false
      add :user_id, :integer, null: false
      add :bet_amount, :integer, null: false
      add :status, :string, default: "active"
      add :result, :string
      add :reward_amount, :integer
      add :joined_at, :utc_datetime, null: false

      timestamps()
    end

    create index(:game_participants, [:game_id])
    create index(:game_participants, [:user_id])
    create unique_index(:game_participants, [:game_id, :user_id])
  end

  def down do
    drop table(:game_participants)
  end
end
