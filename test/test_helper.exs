# Start a BrowseChrome pool for integration tests
{:ok, _} =
  Browse.start_link(Carta.TestPool,
    implementation: BrowseChrome.Browser,
    pool_size: 1
  )

ExUnit.start()
