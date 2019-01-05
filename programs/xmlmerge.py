#!/usr/bin/env python

import sys
import os.path
from xml.etree import ElementTree

def run(files):
    first = None
    for filename in files:
        data = ElementTree.parse(filename).getroot()
        if first is None:
            first = data
        else:
            first.extend(data)
    if first is not None:
        print ElementTree.tostring(first)

if __name__ == "__main__":
    ourself = os.path.basename(sys.argv[0])
    fileargs = sys.argv[1:]
    if len(fileargs) > 0:
        run(fileargs)
    else:
        print("Usage: %s <xmlfile> [<another-xmlfile> [<and-another-one> ...]]" % ourself)