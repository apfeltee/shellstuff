#!/usr/bin/python3

"""
if you haven't already, clone/download https://github.com/Matmaus/LnkParse3
into $HOME/code/programs/
"""

import sys
import os
import argparse

def __main__():
    lp3home = os.path.expanduser("~/code/programs/LnkParse3/")
    lp3path = lp3home + "/LnkParse3"
    sys.path.append(lp3home)
    # it's not "pythonic", but idgaf. fuck python
    exec(open(lp3path+"/lnk_file.py").read(), globals())

__main__()

