import numpy as np
import pandas as pd
import collections
from os.path import exists, join
import os
import math

def generate_statistics(output_MMAP):

    # read unparsed MMAP output file
    output_file = pd.read_csv(output_MMAP, header = None)
    
    #extract relevant columns and rows from the unparsed file
    output_file_pval_genes = output_file[[4,5,6,22,23,24]]
    output_file_gene_names_to_parse = output_file_pval_genes[output_file_pval_genes[4] == "h2"]
    gene_names = [val.split("_")[1] for val in output_file_gene_names_to_parse[24]]
    output_file_p_vals_to_parse = output_file_pval_genes[output_file_pval_genes[4] != "h2"]
    p_vals = list(output_file_p_vals_to_parse[24])

    #create a new dataframe and store all relevant data and statistics to the new dataframe
    parsed_output = pd.DataFrame()
    parsed_output["Genes"] = gene_names

    parsed_output["h2"] = list(output_file_p_vals_to_parse[4])
    parsed_output["h2"] = pd.to_numeric(parsed_output["h2"])

    parsed_output["h2_pvals"] = list(output_file_p_vals_to_parse[5])
    parsed_output["h2_pvals"] = pd.to_numeric(parsed_output["h2_pvals"])

    parsed_output["h2_se"] = list(output_file_p_vals_to_parse[6])
    parsed_output["h2_se"] = pd.to_numeric(parsed_output["h2_se"])

    parsed_output["betas_genes"] = list(output_file_p_vals_to_parse[22])
    parsed_output["betas_genes"] = pd.to_numeric(parsed_output["betas_genes"])

    parsed_output["se_genes"] = list(output_file_p_vals_to_parse[23])
    parsed_output["se_genes"] = pd.to_numeric(parsed_output["se_genes"])

    parsed_output["p_vals"] = p_vals
    parsed_output["p_vals"] = pd.to_numeric(parsed_output["p_vals"])

    parsed_output = parsed_output[["Genes", "betas_genes", "se_genes", "p_vals"]]

    #include Z score in the parsed_output
    parsed_output["Z_Score"] = parsed_output["betas_genes"]/parsed_output["se_genes"]

    #write the new dataframe/parsed mmap output to the output path
    file_identifier = output_MMAP.split("/")[len(output_MMAP.split("/")) - 1].split(".")[0]
    parsed_output.to_csv(f"parsed_output_{str(file_identifier)}.csv", index = None) 

if __name__ == "__main__":
    from argparse import ArgumentParser   
    parser = ArgumentParser()
    parser.add_argument('--output_MMAP', '-output_MMAP', help='aggregated and unparsed MMAP output for different individual gene models')
    args = parser.parse_args()
    generate_statistics(output_MMAP = args.output_MMAP)


