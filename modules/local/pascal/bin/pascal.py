#!/usr/bin/env python3
import matplotlib.pyplot as plt
import os
from PascalX import genescorer
from PascalX.genome import genome

def pascal(gwas_file, manhattan_plot_file, gene_annotation, ref_panel, output_file):

    print(output_file)
    print(ref_panel)
    print(gene_annotation)
    print(manhattan_plot_file)
    print(gwas_file)

    Scorer = genescorer.chi2sum(window=50000, varcutoff=0.99, MAF=0.05, genome=None, gpu=False)
    print("Gene level scoring starts...")

    #Load reference panel        
    Scorer.load_refpanel(ref_panel, qualityT = None, parallel = 1, keepfile=None)
    #Scorer.load_refpanel(ref_panel, qualityT = None, parallel = 1, keepfile=None, chrlist=[22]) ## TESTING:: CHR22 ONLY FOR TESTING
    print("Done importing reference panel")

    # import and load genome annotation
    G = genome()
    # G.get_ensembl_annotation('/llfs/PASCAL_INPUT_FINAL_ROUND/gene_annotation.tsv', genetype='protein_coding,lncRNA,ncRNA',version='GRCh38')
    Scorer.load_genome(gene_annotation)
    print("Done importing gene annotation")

    # load GWAS statistics
    Scorer.load_GWAS(gwas_file,rscol=0,pcol=1,a1col=None, delimiter= ",", a2col=None,header=True)

    # calculate gene-level score
    R = Scorer.score_all(parallel=1)
    #R = Scorer.score_chr([22], parallel=1) ## TESTING:: score only chr22 for testing
    Scorer.save_scores(output_file)
    print("Done scoring genes")
    print(R)
    print(output_file)

    # make a manhattan plot of gene-level scores
    plt.figure(figsize=(17,5))
    Scorer.plot_Manhattan(R[0],sigLine=1e-8,logsigThreshold=9,labelSig=True)
    plt.savefig(manhattan_plot_file)

if __name__ == "__main__":
    from argparse import ArgumentParser   
    parser = ArgumentParser()
    parser.add_argument('--gwas_file', '-gwas_file', help='gwas')
    parser.add_argument('--manhattan_plot_file')
    parser.add_argument('--gene_annotation')
    parser.add_argument('--ref_panel', default = "None")
    parser.add_argument('--output_file')

    args = parser.parse_args()
    #print(args)
    pascal(gwas_file = args.gwas_file, manhattan_plot_file = args.manhattan_plot_file, gene_annotation = args.gene_annotation, ref_panel = args.ref_panel, output_file = args.output_file) 

    ## test
    #output_file = args.gwas_file
    #manhattan_plot_file = os.path.splitext(args.gwas_file)[0] + "_mp.png"
    # print(args.output_file)
    # print(args.manhattan_plot_file)
    # with open(args.output_file, "w") as f:
    #   f.write("this is the output file")
    # with open(args.manhattan_plot_file, "w") as f:
    #   f.write("this is the manhattan plot file")

    print("done")
    
    


