defmodule Framework.Domains do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Framework.Domains.Domain do
      define :lookup_by_auth_code, action: :read, get_by: [:auth_code]
    end
  end
end
