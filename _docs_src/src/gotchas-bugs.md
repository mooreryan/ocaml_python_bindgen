# Gotchas & Known Bugs

* You cannot bind Python properties or attributes that return `None`.  So, `val f : t -> unit` will currently fail.
