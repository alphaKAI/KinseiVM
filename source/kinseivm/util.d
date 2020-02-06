module kinseivm.util;

import std.exception;

class UnimplementedException : Exception {
  this(string msg = "Unimplemented!") {
    super(msg);
  }
}
