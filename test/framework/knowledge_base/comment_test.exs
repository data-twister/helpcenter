defmodule Framework.KnowledgeBase.CommentTest do
  use FrameworkWeb.ConnCase, async: false
  alias Framework.KnowledgeBase.Comment
  import CommentCase
  import ArticleCase
  require Ash.Query

  describe "Comments Tests" do
    test "A comment can be added" do
      user = create_user()
      article = get_article(user.current_tenant)
      attrs = %{content: "Article looks great!", article_id: article.id}

      {:ok, _comment} =
        Comment
        |> Ash.Changeset.for_create(:create, attrs, actor: user)
        |> Ash.create()

      # Confirm that the comment has been created
      assert Comment
             |> Ash.Query.filter(content == ^attrs.content)
             |> Ash.Query.filter(article_id == ^attrs.article_id)
             |> Ash.exists?(actor: user)
    end

    test "A comment can be updated" do
      user = create_user()
      comment = get_comment(user.current_tenant)

      attrs = %{content: "Updated content"}

      {:ok, _comment} =
        comment
        |> Ash.Changeset.for_update(:update, attrs, actor: user)
        |> Ash.update()

      # Confirm that updates actually happened
      assert Comment
             |> Ash.Query.filter(content == ^attrs.content)
             |> Ash.Query.filter(article_id == ^comment.article_id)
             |> Ash.exists?(actor: user)
    end

    test "A Comment can be deleted" do
      user = create_user()

      assert :ok ==
               get_comment(user.current_tenant)
               |> Ash.destroy!(tenant: user.current_tenant)
    end

    test "Delete an article deletes its comments too without relying on data layer" do
      user = create_user()
      comment = get_comment(user.current_tenant)

      assert Framework.KnowledgeBase.Article
             |> Ash.get!(comment.article_id, actor: user)
             |> Ash.destroy!(tenant: user.current_tenant)

      refute Framework.KnowledgeBase.Article
             |> Ash.Query.filter(id == ^comment.id)
             |> Ash.exists?(actor: user)
    end
  end
end
