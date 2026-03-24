defmodule Framework.Accounts.Tenant.Changes.Slugify do
  use Ash.Resource.Change

  # transform and validate opts

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.force_change_attribute(
      changeset,
      :prefix,
      String.downcase(Haikunator.build(Faker.Dog.PtBr.name(), "_"))
    )
  end
end
