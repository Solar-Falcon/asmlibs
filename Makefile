T = XXXXXX

help:
	@echo Available goals:
	@echo ' run   - create and run without debugging '
	@echo ' debug - create and debug '
	@echo ' help  - show this message '
$(T): $(T).asm	
	nasm -f elf32 -l out/$(T).lst -o out/$(T).o $(T).asm
	ld -o out/$(T) -m elf_i386 out/$(T).o
run: $(T)
	./out/$(T)
debug: $(T)
	edb --run out/$(T)
