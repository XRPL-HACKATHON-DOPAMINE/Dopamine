defmodule Dopamin.Repo.Migrations.CreateTopPlayers do
  use Ecto.Migration

  def up do
    create table(:top_players) do
      add :game_id, :integer, null: false
      add :rank, :integer
      add :username, :string
      add :win_rate, :float
      add :games_played, :integer
      add :icon, :string

      timestamps()
    end

    create index(:top_players, [:game_id])
    create index(:top_players, [:rank])
  end

  def down do
    drop index(:top_players, [:rank])
    drop index(:top_players, [:game_id])
    drop table(:top_players)
  end
end
