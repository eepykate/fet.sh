# CONTRIBUTION BY Angel Uniminin <uniminin@zoho.com> under the terms of GPLv3

# NOTICE: Shell is written to be POSIX compatible
SHELL = /bin/sh
FILE = fet.sh

.PHONY: all clean build list

#@ Default target invoked on 'make' (outputs syntax error on this project)
all:
	@ $(error Target 'all' is not allowed, use 'make list' to list available targets or read the 'Makefile' file)
	@ exit 2

#@ List all targets
list:
	@ true \
		&& grep -A 1 "^#@.*" Makefile | sed s/--//gm | sed s/:.*//gm | sed "s/#@/#/gm" | while IFS= read -r line; do \
			case "$$line" in \
				"#"*|"") printf '%s\n' "$$line" ;; \
				*) printf '%s\n' "make $$line"; \
			esac; \
		done


#@ Install fet.sh in /usr/bin/fet.sh
install:
	@ [ -f "/usr/bin/$(FILE)" ] || cp -p $(FILE) "/usr/bin/$(FILE)"
	@ [ -x "/usr/bin/$(FILE)" ] || chmod +x "/usr/bin/$(FILE)"


#@ Uninstall fet.sh
uninstall:
	@ [ ! -f "/usr/bin/$(FILE)" ] || rm -rf "/usr/bin/$(FILE)"
