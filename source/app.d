import std.stdio;
import kinseivm.vm;

void main(string[] args) {
	args = args[1 .. $];

	if (!args.length) {
		writeln("Arguments required");
		return;
	}

	VM vm = new VM();

	vm.loadMemoryFile(args[0]);
	vm.run;
}
