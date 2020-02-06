module kinseivm.memory;
import std.traits;
import std.stdio;

class Memory {
  size_t size;
  ubyte[] memory;
  size_t inserted;

  this(size_t size) {
    this.size = size;
    this.memory = new ubyte[size];
  }

  void set_ubyte(size_t idx, ubyte data) {
    this.memory[idx] = data;
    this.inserted++;
  }

  void set_uint(size_t idx, uint data) {
    this.memory[idx + 0] = (data >> 0) & 0xFF;
    this.memory[idx + 1] = (data >> 8) & 0xFF;
    this.memory[idx + 2] = (data >> 16) & 0xFF;
    this.memory[idx + 3] = (data >> 24) & 0xFF;
    this.inserted += 4;
  }

  ubyte get_ubyte(size_t idx) {
    return this.memory[idx];
  }

  uint get_uint(size_t idx) {
    return (this.memory[idx + 0] & 0xFFFFFFFF) | (
        (this.memory[idx + 1] & 0xFFFFFFFF) << 8) | (
        (this.memory[idx + 2] & 0xFFFFFFFF) << 16) | ((this.memory[idx + 3] & 0xFFFFFFFF) << 24);
  }

  void debug_dump_memory() {
    write("Memory [");
    size_t N = this.inserted / uint.sizeof;
    foreach (i; 0 .. N) {
      size_t idx = i * uint.sizeof;
      if (i) {
        write(", ");
      }
      writef("%0.32b", this.get_uint(idx));
    }

    writeln("]");
  }
}

size_t get_addr(T)(T v) if (isNumeric!T) {
  return v * uint.sizeof;
}
