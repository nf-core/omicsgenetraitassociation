#!/usr/bin/env python3

import pandas as pd
import os
import sys

def extractGeneSetFromModuleFile(MODULEPATH:str):
    """
    Read a module file and extract a set of genes in the file.
    It assumes the input file is tsv format where the gene name starts to appear from the thrid column

    Args:
        DIRPATH (str): path to the module file

    Returns:
        _type_: set of genes appear in the module file
    """
    ret = set()
    with open(MODULEPATH, "r") as f:
        lines = f.readlines()
        for line in lines:
            columns = line.split()
            for column in columns[2:]:
                ret.add(column)
    return ret

def pairwiseProcessGeneScoreAndModule(GSPATH: str, MODULEPATH: str, OUTPUTPATH: str, pipeline: str, trait: str, geneNameCol: str, pvalCol: str, sep: str = ',') -> None:
    """
    Process a pair of gene score file and module file, dropping genes that do not exist in either file.
    Write a pair of processed files with the same name. These processed files will be used as input for Pascal module enrichment.

    Args:
        GSPATH (str): Path to the gene score file.
        MODULEPATH (str): Path to the pre-defined module file.
        OUTPUTPATH (str): Path to start building a nested subdirectory for outputs. The structure will be: [pipeline > trait > output].
        GOPATH (str): Path to the directory for storing GO background set files.
        pipeline (str): Name of the pipeline, e.g., twas, gwas, staar, or cma.
        trait (str): Name of the trait.
        geneNameCol (str): Column name for gene name in the gene score file.
        pvalCol (str): Column name for the p-value in the gene score file.
        sep (str): Separator used in the gene score file. If the file is tab-separated, pass '\t'. The default is a comma (',').

    Returns:
        None. The processed gene score file, processed module file, and the GO background set file are saved to the corresponding directories.
    """

    # Read the gene score file
    df_gs = pd.read_csv(GSPATH, sep=sep)
    genesWithScore = set(df_gs[geneNameCol])
    genesInModule = extractGeneSetFromModuleFile(MODULEPATH)
    intersectingGenes = genesWithScore.intersection(genesInModule)

    moduleFileName = MODULEPATH.split("/")[-1]
    # Output processed gene score file to be used for PASCAL
    with open(os.path.join(OUTPUTPATH, f"GS_{pipeline}_{trait}_{moduleFileName[:-4]}.tsv"), "w") as f:
        for index, row in df_gs.iterrows():
            f.write(f"{row[geneNameCol]}\\t{str(row[pvalCol])}\\n")

    # Output GO background set file
    with open(os.path.join(OUTPUTPATH, f"GO_{pipeline}_{trait}_{moduleFileName[:-4]}.txt"), "w") as f:
        for index, row in df_gs.iterrows():
            if row[geneNameCol] in intersectingGenes:
                f.write(f"{row[geneNameCol]}\\n")

    # Output processed module file after intersecting with the gene score file
    with open(os.path.join(OUTPUTPATH, f"Module_{pipeline}_{trait}_{moduleFileName[:-4]}.tsv"), "w") as f:
        with open(MODULEPATH, "r") as g:
            droppedGeneCounter = 0
            lines = g.readlines()
            for line in lines:
                columns = line.split()
                f.write(columns[0])  # Write the module index
                for column in columns[2:]:  # Column[1] is always 1.0, so dropped
                    if column in intersectingGenes:
                        f.write("\\t" + column)
                    else:
                        droppedGeneCounter += 1
                f.write("\\n")

def write_versions_file():
    with open("versions.yml", "w") as f:
        f.write('"${task.process}":\\n')
        f.write(f'    python: "{sys.version}"\\n')
        f.write(f'    pandas: "{pd.__version__}"\\n')

def main():

    # parse nextflow process input variables
    scoreFile = '$gene_score_file'
    moduleFileDir = '$module_file_dir'
    outputPath = 'pascalInput/'
    pipelineName = '$pipeline'
    traitName = '$trait'
    geneColName= '$gene_col_name'
    pvalColName = '$pval_col_name'

    # write versions file
    write_versions_file()

    # Check if the output directory exists, if not create it
    if not os.path.exists(outputPath):
        os.makedirs(outputPath)

        filePath = moduleFileDir
        pairwiseProcessGeneScoreAndModule(scoreFile, filePath, outputPath, pipelineName, traitName, geneColName, pvalColName)


if __name__ == "__main__":
    main()
