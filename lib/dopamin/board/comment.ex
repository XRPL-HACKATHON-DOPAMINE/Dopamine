defmodule Dopamin.Board.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "comments" do
    field :content, :string

    belongs_to :post, Dopamin.Board.Post
    belongs_to :user, Dopamin.Accounts.User
    belongs_to :parent, Dopamin.Board.Comment, foreign_key: :parent_id
    has_many :replies, Dopamin.Board.Comment, foreign_key: :parent_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :post_id, :user_id, :parent_id])
    |> validate_required([:content, :post_id, :user_id])
    |> validate_length(:content, min: 2, max: 1000)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:parent_id)
  end
end
