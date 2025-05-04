defmodule Dopamin.Board.Post do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "posts" do
    field :title, :string
    field :content, :string
    field :views, :integer, default: 0

    belongs_to :board, Dopamin.Board.Board
    belongs_to :user, Dopamin.Accounts.User
    has_many :comments, Dopamin.Board.Comment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :content, :board_id, :user_id])
    |> validate_required([:title, :content, :board_id, :user_id])
    |> validate_length(:title, min: 2, max: 255)
    |> validate_length(:content, min: 10)
    |> foreign_key_constraint(:board_id)
    |> foreign_key_constraint(:user_id)
  end

  def inc_views(post) do
    post
    |> change(views: post.views + 1)
  end
end
