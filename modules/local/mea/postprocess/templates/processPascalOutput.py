#!/usr/bin/env python3

import os
import re
from typing import List
import csv
import ast
import pandas as pd
from statsmodels.sandbox.stats.multicomp import multipletests

def extractGenesBasedOnPval(DIRPATH:str, pval:float):
    """
    Given a GeneScore file in tsv file format without header and a pvalue threshold,
    output list of genes with pval less than the threshold

    Args:
        DIRPATH (str): Path to GS file in tsv format. ASSUMPTION: the first col is gene name and the second col is pval
        pval (float): pvalue threshold

    Returns:
        _type_: list of significant genes
    """
    df = pd.read_table(DIRPATH, header=None)
    return list(df[df[1] < pval][0])

def saveSignificantModules(OUTPUTPATH:str, genes:List[str]) -> None:
    with open(OUTPUTPATH, "w") as f:
        for gene in genes:
            f.write(f"{gene}\\n")

def saveDummyModule(OUTPUTPATH:str) -> None:
    with open(OUTPUTPATH, 'w') as f:
        f.write("-1")

def recordModulesFromPascalResult(result, OUTPUTPATH, sigGenesList, almostSigGenesList, sig4GenesList, sig3GenesList, sig2GenesList, study, trait, network):
    moduleIndexToSize = {}
    moduleIndexToModulePval = {}
    moduleIndexToCorrectedModulePval = {}
    moduleIndexToSigFlag = {}
    moduleIndexSigGenes = {}
    moduleIndexAlmostSigGenes = {}
    moduleIndexToSig4Genes = {}
    moduleIndexToSig3Genes = {}
    moduleIndexToSig2Genes = {}
    # each item represents a module
    for item in result:
        sigGenes = []
        almostSigGenes = []
        sig4Genes = []
        sig3Genes = []
        sig2Genes = []
        moduleSizeCounter = 0
        for gene in item[1]:
            moduleSizeCounter += 1
            if gene in sigGenesList:
                sigGenes.append(gene)
            if gene in almostSigGenesList:
                almostSigGenes.append(gene)
            if gene in sig4GenesList:
                sig4Genes.append(gene)
            if gene in sig3GenesList:
                sig3Genes.append(gene)
            if gene in sig2GenesList:
                sig2Genes.append(gene)

        # assumes index of 2 represents bool indicating significance of the module
        if item[2]:
            moduleIndexToSigFlag[item[0]] = True
            dir_out = os.path.dirname(OUTPUTPATH)
            file_out = f"sig_{os.path.basename(OUTPUTPATH).replace('.txt', f'_{item[0]}.txt')}"
            sigModuleOutName = os.path.join(dir_out, file_out)
            saveSignificantModules(sigModuleOutName, item[1])
        else:
            moduleIndexToSigFlag[item[0]] = False
            # saveDummyModule(os.path.join(os.path.dirname(OUTPUTPATH), f"dummy_{study}_{trait}_{network}_{item[0]}.txt"))
        moduleIndexToSize[item[0]] = moduleSizeCounter
        moduleIndexToModulePval[item[0]] = item[4]
        moduleIndexToCorrectedModulePval[item[0]] = item[3]
        moduleIndexSigGenes[item[0]] = sigGenes
        moduleIndexAlmostSigGenes[item[0]] = almostSigGenes
        moduleIndexToSig4Genes[item[0]] = sig4Genes
        moduleIndexToSig3Genes[item[0]] = sig3Genes
        moduleIndexToSig2Genes[item[0]] = sig2Genes

    return moduleIndexToSize, moduleIndexToModulePval, moduleIndexToCorrectedModulePval, moduleIndexToSigFlag, moduleIndexSigGenes, moduleIndexAlmostSigGenes, moduleIndexToSig4Genes, moduleIndexToSig3Genes, moduleIndexToSig2Genes

def processOnePascalOutput(DIRPATH:str, alpha:float, outputPATH:str):
    """
    Given a path to a pascal output file, extract module index, module genes, and BH-corrected module pvalue

    Args:
        DIRPATH (str): path to a pascal output file
        alpha (float): significance threshold for modules pvalue after BH correction
        outputPATH (str): path to save the whole pascal result

    Returns:
        _type_: list of processed module info, total number of significant pathways
    """
    # read file as string
    with open(DIRPATH, "r") as f:
        results = f.read()
        # flatten pval parts
        results = results.replace(",\\n", ",") # remove newline in gene pvalues
        results = results.replace(" ", "") # remove whitespaces
        results = results.strip("\\n").split("\\n") # split to each module record

    pathwayIndexList = []
    pathwayGenesList = []
    pathwayPvalList = []

    # parse per line
    for idx,module in enumerate(results):
        print(idx)
        module_split = module[1:-1].split("],array")
        module_pval = module_split[1].split("),")[1]

        # if a module lost all genes due to missing gene score, exclude it from FDR
        if module_pval != "nan":
            module_pval = float(module_pval)
            module_idx = int(module_split[0].split(",")[0].strip("'"))
            module_genes = ast.literal_eval(module_split[0].split(",[")[1])
            module_genes_pval = module_split[1].split("),")[0].split("(")[1]

            pathwayIndexList.append(module_idx)
            pathwayGenesList.append(module_genes)
            pathwayPvalList.append(module_pval)

    # FDR correction BH or Bonferroni
    correctedPathwayPvalList = multipletests(pathwayPvalList, alpha, method='bonferroni') #Bonferroni

    # output csv file
    df = pd.DataFrame(list(zip(pathwayIndexList, pathwayGenesList,pathwayPvalList, correctedPathwayPvalList[1])),
                        columns=['moduleIndex', 'moduleGenes', 'modulePval', 'correctedModulePval'])
    df.to_csv(outputPATH)

    result = []

    numSigPathway = sum(correctedPathwayPvalList[0])
    for tup in zip(pathwayIndexList, pathwayGenesList, correctedPathwayPvalList[0], correctedPathwayPvalList[1], pathwayPvalList):
        result.append(tup)

    # sort by corrected module pvalue
    result.sort(key=lambda x: x[-1])
    return result, numSigPathway

def print_versions():
    import sys
    import statsmodels
    with open("versions.yml", "w") as file:
        file.write('"${task.process}"\\n')
        file.write(f'  python: {sys.version}\\n')
        file.write(f'  pandas: {pd.__version__}\\n')
        file.write(f'  statsmodels: {statsmodels.__version__}\\n')

def main():

    # parse nextflow input variables
    pascalOutputFile = '$pascalOutputFile'
    alpha = float('$alpha')
    outputPath = 'masterSummaryPiece/'
    geneScoreFilePath = '$geneScoreFilePascalInput'
    significantModulesOutDir = 'significantModules/'
    numTests = int('$numTests')

    study = pascalOutputFile.split("_")[0]
    trait = pascalOutputFile.split("_")[1]
    network = pascalOutputFile.split("_")[2].replace(".txt", "")
    rpIndex = trait.split("-")[0]

    sigPvalThreshold = 0.05 / numTests

    # Check if the output directory exists, if not create it
    if not os.path.exists(outputPath):
        os.makedirs(outputPath)
    if not os.path.exists(significantModulesOutDir):
        os.makedirs(significantModulesOutDir)

    # master summary file columns
    summary_dict = {'study':[],
                    'trait':[],
                    'network':[],
                    'moduleIndex':[],
                    "isModuleSig":[],
                    "modulePval":[],
                    "moduleBonPval":[],
                    'size':[],
                    'numSigGenes':[],
                    'sigGenes':[],
                    'sig1Genes':[],
                    'sig2Genes':[],
                    'sig3Genes':[],
                    'sig4Genes':[]
                    }

    # create summary file for one pascal output file.
    result, numSigPathway = processOnePascalOutput(pascalOutputFile, alpha, os.path.join(outputPath, "pascalResult.csv"))
    sigGenesList = extractGenesBasedOnPval(geneScoreFilePath,sigPvalThreshold)
    sig1GenesList = extractGenesBasedOnPval(geneScoreFilePath, sigPvalThreshold*10)
    sig2GenesList = extractGenesBasedOnPval(geneScoreFilePath, sigPvalThreshold*100)
    sig3GenesList = extractGenesBasedOnPval(geneScoreFilePath, sigPvalThreshold*1000)
    sig4GenesList = extractGenesBasedOnPval(geneScoreFilePath, sigPvalThreshold*10000)
    sigModulesPath = os.path.join(significantModulesOutDir, pascalOutputFile)
    print(sigModulesPath)
    print(outputPath)
    moduleToSize, moduleToPval, moduleToCorrectedPval, isModuleSig, sigGenesDict, sig1GenesDict, sig2GenesDict, sig3GenesDict, sig4GenesDict = recordModulesFromPascalResult(result, sigModulesPath,sigGenesList, sig1GenesList, sig2GenesList, sig3GenesList, sig4GenesList, study, trait, network)
    for moduleIndex in sigGenesDict.keys():
        summary_dict['study'].append(study)
        summary_dict['trait'].append(trait)
        summary_dict['network'].append(network)
        summary_dict['moduleIndex'].append(moduleIndex)
        summary_dict['isModuleSig'].append(isModuleSig[moduleIndex])
        summary_dict['modulePval'].append(moduleToPval[moduleIndex])
        summary_dict['moduleBonPval'].append(moduleToCorrectedPval[moduleIndex])
        summary_dict['size'].append(moduleToSize[moduleIndex])
        summary_dict['numSigGenes'].append(len(sigGenesDict[moduleIndex]))
        summary_dict['sigGenes'].append(sigGenesDict[moduleIndex])
        summary_dict["sig1Genes"].append(sig1GenesDict[moduleIndex])
        summary_dict['sig2Genes'].append(sig2GenesDict[moduleIndex])
        summary_dict['sig3Genes'].append(sig3GenesDict[moduleIndex])
        summary_dict['sig4Genes'].append(sig4GenesDict[moduleIndex])

    df_summary = pd.DataFrame(summary_dict)
    #df_summary.to_csv(os.path.join(outputPath, f"master_summary_slice_{rpIndex}.csv"), index=False)
    df_summary.to_csv(os.path.join(outputPath, f"master_summary_slice_{trait}_{network}.csv"), index=False)

if __name__ == "__main__":
    main()
    print_versions()
