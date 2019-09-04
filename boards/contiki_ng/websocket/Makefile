CONTIKI_PROJECT = http-example websocket-example
all: $(CONTIKI_PROJECT)
CONTIKI=$(shell targetos)/contiki
MODULES += os/net/app-layer/http-socket

PLATFORMS_EXCLUDE = sky z1

include $(CONTIKI)/Makefile.include
