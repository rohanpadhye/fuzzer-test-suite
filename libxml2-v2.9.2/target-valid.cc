// Copyright 2016 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
#include <string>
#include <vector>
#include "libxml/xmlversion.h"
#include "libxml/parser.h"
#include "libxml/HTMLparser.h"
#include "libxml/tree.h"

#include "afl_valid.h"

static bool errors;

void invalid (void * ctx, const char * msg, ...) {
  va_list args;
  va_start(args, msg);
  vfprintf(stderr, msg, args);
  va_end(args);
  errors = true;
}

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  errors = false;
  xmlSetGenericErrorFunc(NULL, &invalid);
  if (auto doc = xmlReadMemory(reinterpret_cast<const char *>(data), size,
                               "noname.xml", NULL, 0))
    xmlFreeDoc(doc);
  ASSUME1(!errors);
  return 0;
}
