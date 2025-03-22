defmodule Dopamin.Repo.Migrations.CreateRewardTiers do
  use Ecto.Migration

  def up do
    create table(:reward_tiers) do
      add :game_id, :integer, null: false
      add :rank, :string, null: false
      add :condition, :string, null: false
      add :reward, :integer, null: false

      timestamps()
    end

    create index(:reward_tiers, [:game_id])
  end

  def down do
    drop index(:reward_tiers, [:game_id])
    drop table(:reward_tiers)
  end
end
