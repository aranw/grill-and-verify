// A minimal valid Quint module, used only to warm the Apalache download
// into /root/.quint during the image build.
module warm {
  var x: int
  action init = x' = 1
  action step = x' = if (x == 1) 2 else 1
}
