# lib/framework/extensions/ash_parental/info.ex
defmodule Framework.Extensions.AshParental.Info do
  use Spark.InfoGenerator, extension: Framework.Extensions.AshParental, sections: [:ash_parental]
end
