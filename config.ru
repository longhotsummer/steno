# config.ru
require "./steno_app"

map StenoApp.assets_prefix do
  run StenoApp.sprockets
end

run StenoApp
