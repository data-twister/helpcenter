defmodule Framework.Accounts.User.Calculations.TenantData do
  @impl true
  def init(_opts) do
    {:ok, []}
  end

  @impl true
  def load(_query, _opts, _context) do
    [
      :tenant
    ]
  end

  @impl true
  def calculate(records, _opts, _arguments) do
    records
  end
end
