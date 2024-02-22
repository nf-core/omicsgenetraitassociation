#!/usr/bin/env python3

import argparse
import os
import glob
from typing import List

from PascalX import pathway
from PascalX import genescorer

def main():

    scoreFile = '$geneScoreFile'
    moduleFile = '$moduleFile'
    outputPath = 'pascalOutput/'

    print(scoreFile)
    print(moduleFile)
    print(outputPath)
    # Check if the output directory exists, if not create it
    if not os.path.exists(outputPath):
        print("creating outputPath")
        os.makedirs(outputPath)

    #for moduleFile, scoreFile in zip(moduleFiles, scoreFiles):
    Scorer = genescorer.chi2sum()
    Scorer.load_scores(scoreFile)
    Pscorer = pathway.chi2rank(Scorer, fuse=False)
    M = Pscorer.load_modules(moduleFile, ncol=0, fcol=1)
    RESULT = Pscorer.score(M)
    fileName = os.path.basename(scoreFile).replace("tsv", "txt").replace("GS_", "")
    file = open(os.path.join(outputPath, fileName), "w")
    for r in RESULT[0]:
        file.write(f'{r}\\n')

def print_versions():
    import sys
    import PascalX
    with open("versions.yml", "w") as file:
        file.write('"${task.process}"\\n')
        file.write(f'  python: {sys.version}\\n')
        file.write(f'  PascalX: {PascalX.__version__}\\n')


if __name__ == "__main__":
    main()
    print_versions()
