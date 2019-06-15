all: trafficlight-control trafficlight-control-slave

# Linker optimizations
SMALL = 1

# Includes the project-conf configuration file
CFLAGS += -DPROJECT_CONF_H=\"../project-conf.h\"

CONTIKI=/home/aghiles/Aghiles/Program/boards/contiki/bin/contiki-os

# This flag includes the IPv6 libraries
CONTIKI_WITH_IPV6 = 1

include $(CONTIKI)/Makefile.include
