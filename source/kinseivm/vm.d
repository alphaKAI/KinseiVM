module kinseivm.vm;
import kinseivm.memory;
import kinseivm.register;
import kinseivm.util;
import std.file, std.stdio;
import std.string, std.conv;
import std.algorithm, std.array;

enum Inst : ubyte {
  ADD = 0b000_0000,
  SUB = 0b000_0001,
  MUL = 0b000_0010,
  DIV = 0b000_0011,
  CMP = 0b000_0100,
  ABS = 0b000_0101,
  ADC = 0b000_0110,
  SBC = 0b000_0111,
  SHL = 0b000_1000,
  SHR = 0b000_1001,
  ASH = 0b000_1010,
  ROL = 0b000_1100,
  ROR = 0b000_1101,
  AND = 0b001_0000,
  OR = 0b001_0001,
  NOT = 0b001_0010,
  XOR = 0b001_0011,
  SETL = 0b001_0110,
  SETH = 0b001_0111,
  Load = 0b001_1000,
  Store = 0b001_1001,
  Jump = 0b001_1100,
  JumpA = 0b001_1101,
  NOP = 0b001_1110,
  HLT = 0b001_1111
}

enum FLAG_REGISTERS = 6;

enum FlagRegister {
  Underflow = 0,
  Overflow = 1,
  Carry = 2,
  Negative = 3,
  Positive = 4,
  Zero = 5
}

class VM {
  size_t memory_size;
  size_t register_count;

  Memory memory;
  RegisterFile register_file;

  size_t pc;
  uint inst;
  bool[] flag_register;

  void initVM() {
    this.memory = new Memory(this.memory_size);
    this.register_file = new RegisterFile(this.register_count);
    this.flag_register = new bool[FLAG_REGISTERS];
  }

  this(size_t memory_size, size_t register_count) {
    this.memory_size = 65536;
    this.register_count = 16;

    initVM();
  }

  this() {
    this(65536, 16);
  }

  void loadMemoryFile(string file_path) {
    auto data = readText(file_path).split("\n").filter!(e => e.length)
      .map!(data => data.to!uint(2))
      .array;

    foreach (size_t i, uint e; data) {
      this.memory.set_uint(i * uint.sizeof, e);
    }
  }

  void debug_dump_inst() {
    ubyte op = this.inst >> 25;
    bool immf = (this.inst >> 24) & 1;
    ubyte rd = (this.inst >> 20) & 0b1111;
    ubyte rs = (this.inst >> 16) & 0b1111;
    ushort imm = this.inst & 0xFFFF;

    writefln("inst: %0.32b", inst);
    writefln("op  : %0.7b%29s%s", op, " -> ", cast(Inst) op);
    writefln("immf:        %0.1b%28s%s", immf, " -> ", immf);
    writefln("rd  :         %0.4b%24sR%s", rd, " -> ", rd);
    writefln("rs  :             %0.4b%20sR%s", rs, " -> ", rs);
    writefln("imm :                 %0.16b%s%s", imm, " -> ", imm);
  }

  void debug_dump_flag_registers() {
    write("flag_register: [");

    foreach (i, reg; flag_register) {
      if (i) {
        write(", ");
      }
      writef("%s: %s", cast(FlagRegister) i, reg);
    }

    writeln("]");
  }

  void debug_dump_current_state() {
    writeln("--------------------------------------------------------------");
    writefln("pc  : %s, memory_size: %s, register_count: %s", this.pc,
        this.memory_size, this.register_count);
    debug_dump_inst();
    debug_dump_flag_registers();
  }

  enum JumpCondition : ubyte {
    Always = 0b000,
    Zero = 0b001,
    Positive = 0b010,
    Negative = 0b011,
    Carry = 0b100,
    Overflow = 0b101
  }

  bool check_jump_condition(ubyte cc) {
    final switch (cc) with (JumpCondition) {
    case Always:
      return true;
    case Zero:
      return this.flag_register[FlagRegister.Zero];
    case Positive:
      return this.flag_register[FlagRegister.Positive];
    case Negative:
      return this.flag_register[FlagRegister.Negative];
    case Carry:
      return this.flag_register[FlagRegister.Carry];
    case Overflow:
      return this.flag_register[FlagRegister.Overflow];
    }
  }

  void run() {
    while (get_addr(pc) < this.memory_size) {
      this.inst = memory.get_uint(get_addr(pc));
      ubyte op = this.inst >> 25;
      bool immf = (this.inst >> 24) & 1;
      ubyte rd = (this.inst >> 20) & 0b1111;
      ubyte rs = (this.inst >> 16) & 0b1111;
      ushort imm = this.inst & 0xFFFF;

      debug_dump_current_state();
      memory.debug_dump_memory();
      register_file.debug_dump_register_file();

      uint dst_value;
      uint src_value;

      void load_reg_values() {
        dst_value = register_file.get!uint(rd);

        if (immf) {
          src_value = imm;
        } else {
          src_value = register_file.get!uint(rs);
        }
      }

      final switch (op) with (Inst) {
      case ADD: {
          load_reg_values();
          uint result_value = dst_value + src_value;
          // TODO: OF, UF
          this.flag_register[FlagRegister.Negative] = cast(int) result_value < 0;
          this.flag_register[FlagRegister.Positive] = cast(int) result_value > 0;
          this.flag_register[FlagRegister.Zero] = result_value == 0;
          register_file.set_uint(rd, result_value);
          break;
        }
      case SUB: {
          load_reg_values();
          uint result_value = dst_value - src_value;
          // TODO: OF, UF
          this.flag_register[FlagRegister.Negative] = cast(int) result_value < 0;
          this.flag_register[FlagRegister.Positive] = cast(int) result_value > 0;
          this.flag_register[FlagRegister.Zero] = result_value == 0;
          register_file.set_uint(rd, result_value);
          break;
        }
      case MUL: {
          load_reg_values();
          uint result_value = dst_value * src_value;
          // TODO: OF, UF
          this.flag_register[FlagRegister.Negative] = cast(int) result_value < 0;
          this.flag_register[FlagRegister.Positive] = cast(int) result_value > 0;
          this.flag_register[FlagRegister.Zero] = result_value == 0;
          register_file.set_uint(rd, result_value);
          break;
        }
      case DIV: {
          load_reg_values();
          uint result_value = dst_value / src_value;
          // TODO: OF, UF
          this.flag_register[FlagRegister.Negative] = cast(int) result_value < 0;
          this.flag_register[FlagRegister.Positive] = cast(int) result_value > 0;
          this.flag_register[FlagRegister.Zero] = result_value == 0;
          register_file.set_uint(rd, result_value);
          break;
        }
      case CMP: {
          load_reg_values();
          uint result_value = dst_value - src_value;
          this.flag_register[FlagRegister.Negative] = cast(int) result_value < 0;
          this.flag_register[FlagRegister.Positive] = cast(int) result_value > 0;
          this.flag_register[FlagRegister.Zero] = result_value == 0;
          break;
        }
      case ABS:
      case ADC:
      case SBC:
      case SHL:
      case SHR:
      case ASH:
      case ROL:
      case ROR:
        throw new UnimplementedException();
      case AND: {
          load_reg_values();
          uint result_value = dst_value && src_value;
          this.flag_register[FlagRegister.Zero] = result_value == 0;
          register_file.set_uint(rd, result_value);
          break;
        }
      case OR: {
          load_reg_values();
          uint result_value = dst_value || src_value;
          this.flag_register[FlagRegister.Zero] = result_value == 0;
          register_file.set_uint(rd, result_value);
          break;
        }
      case NOT: {
          load_reg_values();
          uint result_value = !src_value;
          register_file.set_uint(rd, result_value);
          break;
        }
      case XOR: {
          load_reg_values();
          uint result_value = (dst_value && !src_value) || (!dst_value && src_value); //dst_value ^ src_value;
          register_file.set_uint(rd, result_value);
          break;
        }
      case SETL:
      case SETH:
      case Load:
      case Store:
      case Jump: {
          load_reg_values();
          if (this.check_jump_condition(rd)) {
            pc += src_value;
            continue;
          }
          break;
        }
      case JumpA:
        load_reg_values();
        if (this.check_jump_condition(rd)) {
          pc = src_value;
          continue;
        }
        break;
      case NOP:
        throw new UnimplementedException();
      case HLT: {
          return;
        }
      }

      pc++;

    }
  }
}
