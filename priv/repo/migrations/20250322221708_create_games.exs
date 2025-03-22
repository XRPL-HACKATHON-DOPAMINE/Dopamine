defmodule Dopamin.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def up do
    create table(:games) do
      add :category, :string
      add :name, :string
      add :description, :text
      add :players, :integer
      add :xrp, :integer
      add :win_rate, :float
      add :plays, :integer
      add :image, :string

      # 게임 종료 시간 필드
      add :end_time, :utc_datetime

      timestamps()
    end
  end

  def down do
    drop table(:games)
  end
end
