# lib/framework/extensions/ash_parental/transformers/add_children_count_aggregate.ex
defmodule Framework.Extensions.AshParental.Transformers.AddChildrenCountAggregate do
  use Spark.Dsl.Transformer

  def after?(Framework.Extensions.AshParental.Transformers.AddHasManyChildrenRelationship) do
    true
  end

  def after?(_), do: false

  def transform(dsl_state) do
    Ash.Resource.Builder.add_new_aggregate(
      dsl_state,
      :count_of_children,
      :count,
      # <-- Use the configured children relationship name
      [get_children_relationship_name(dsl_state)]
    )
  end

  defp get_children_relationship_name(dsl_state) do
    dsl_state
    |> Framework.Extensions.AshParental.Info.ash_parental_children_relationship_name!()
  end
end
