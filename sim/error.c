/*
 * error.c -- error handler
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "common.h"
#include "console.h"
#include "error.h"
#include "cpu.h"
#include "mmu.h"
#include "memory.h"
#include "timer.h"
#include "dspkbd.h"
#include "term.h"
#include "disk.h"
#include "output.h"
#include "graph.h"


void error(char *fmt, ...) {
  va_list ap;

  cpuExit();
  mmuExit();
  memoryExit();
  timerExit();
  displayExit();
  keyboardExit();
  termExit();
  diskExit();
  outputExit();
  graphExit();
  cExit();
  va_start(ap, fmt);
  fprintf(stderr, "Error: ");
  vfprintf(stderr, fmt, ap);
  fprintf(stderr, "\n");
  va_end(ap);
  exit(1);
}
