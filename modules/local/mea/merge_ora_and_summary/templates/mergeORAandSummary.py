#!/usr/bin/env python3

import os
from typing import List
import pandas as pd

def countGOterms(DIRPATH:str)-> int:
    df = pd.read_csv(DIRPATH)
    moduleIndex = DIRPATH.split("/")[-1].split("_")[-1].replace(".csv","")
    maxEnrichmentRatio = -1
    enrichMentRatio = -1
    if len(df) > 0:
        minTermPval = df["FDR"].min()
        maxEnrichmentRatio = df["enrichmentRatio"].max()
        enrichMentRatio = df[df["FDR"] == df["FDR"].min()]["enrichmentRatio"].max()
    else:
        minTermPval = -1
        maxEnrichmentRatio = -1
        enrichMentRatio = -1
    return int(moduleIndex), len(df), minTermPval, enrichMentRatio, maxEnrichmentRatio


def outputMergableORA_df(module_ora_file:str, study:str, trait:str, network:str, moduleIndex:int):
    
    dict_ora = {'study':[], 'trait':[], 'network':[], 'moduleIndex':[],
                'geneontology_Biological_Process':[], 'BPminCorrectedPval':[],
                'BPminFDREnrichmentRatio':[], 'BPmaxEnrichmentRatio':[]}
    GOtype = 'geneontology_Biological_Process'
    moduleIndex, GOcount, minPval, enrichmentRatio_minFDR, enrichmentRatio_max = countGOterms(module_ora_file)
    dict_ora['study'].append(study)
    dict_ora["trait"].append(trait)
    dict_ora["network"].append(network)
    dict_ora["moduleIndex"].append(moduleIndex)
    dict_ora['BPminCorrectedPval'].append(minPval)
    dict_ora["BPminFDREnrichmentRatio"].append(enrichmentRatio_minFDR)
    dict_ora["BPmaxEnrichmentRatio"].append(enrichmentRatio_max)
    dict_ora[GOtype].append(GOcount)

    return pd.DataFrame(dict_ora)
    

def main():
    
    # parse nextflow parameters
    masterSummaryPiece = '$masterSummaryPiece'
    oraResultsDir = '$oraSummaryDir'
    output_directory = "summary/"
    goFile = '$goFile'
    
    # Check if the output directory exists, if not create it
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)
        
    df_summary_piece = pd.read_csv(masterSummaryPiece)
    df_summary_piece[['study', 'trait', 'network', 'moduleIndex']] = df_summary_piece[['study', 'trait', 'network', 'moduleIndex']].astype(str)
    study, trait, network = os.path.basename(goFile).split(".")[0].split("_")[1:4]

    
    ora_dfs = []
    if len(os.listdir(oraResultsDir)) == 0: # if there are no significant module from ORA result
        ora_dfs.append(pd.DataFrame({'study':[study], 'trait':[trait], 'network':[network], 'moduleIndex':[0],
                                    'geneontology_Biological_Process':["NA"], 'BPminCorrectedPval':["NA"],
                                    "BPminFDREnrichmentRatio":["NA"], 'BPmaxEnrichmentRatio':["NA"]}))
    else:
        for file in os.listdir(oraResultsDir):
            file = os.path.join(oraResultsDir, file)
            moduleIndex = os.path.basename(file).split(".")[0].split("_")[4]
            df_ora = outputMergableORA_df(file, study, trait, network, moduleIndex)
            ora_dfs.append(df_ora)
            
    df_ora_merged = pd.concat(ora_dfs, ignore_index=True)
    df_ora_merged[['study', 'trait', 'network', 'moduleIndex']] = df_ora_merged[['study', 'trait', 'network', 'moduleIndex']].astype(str)
    df_merge = pd.merge(df_summary_piece, df_ora_merged, how='left', on=['study','trait','network', 'moduleIndex'])
    df_merge.fillna("NA", inplace=True)
    mergedFileName = f"{study}_{trait}_{network}.csv"
    df_merge.to_csv(os.path.join(output_directory, mergedFileName), index=False)
    
def print_versions():
    import sys
    with open("versions.yml", "w") as file:
      file.write('"${task.process}"\\n')
      file.write(f'  python: {sys.version}\\n')
      file.write(f'  pandas: {pd.__version__}\\n')

if __name__ == "__main__":
    main()
    print_versions()
