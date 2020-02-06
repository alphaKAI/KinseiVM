module kinseivm.register;
import std.conv;
import std.stdio;
import std.format;

class Register {
  uint data;
}

class RegisterFile {
  Register[] regFile;

  this(size_t register_count) {
    regFile.length = register_count;

    foreach (i; 0 .. register_count) {
      regFile[i] = new Register;
    }
  }

  void set_uint(size_t idx, uint data) {
    regFile[idx].data = data;
  }

  void set_ubyte(size_t idx, ubyte data) {
    regFile[idx].data = data;
  }

  T get(T)(size_t idx) {
    return regFile[idx].data.to!(T);
  }

  void debug_dump_register_file() {
    foreach (i, reg; this.regFile) {
      if (i) {
        write(", ");
      }
      if (i && i % 4 == 0) {
        writeln;
      }
      auto v = this.get!uint(i);
      writef("%4s: %0.32b(%3d)", ("R%d".format(i)), v, v);
    }
    writeln;
  }
}
