import pandas as pd
import os

def format_cma_input(input_file, name, header, pval_col, beta_col, se_col):
    """
    Formats the input file for CMA analysis
    args
        @input_file: input file with p-values
        @name: name of output file
        @header: header exists (1) or not (0)
        @pval_col: column name or number of p-value
        @beta_col: column name or number of beta value
        @se_col: column name or number of SE value
    """
    _, ext = os.path.splitext(input_file)
    sep = ","
    if ext == ".tsv":
        sep = "\t"

    if header == 1:
        df = pd.read_csv(input_file, sep=sep)
        print(df)
        print(df.columns)
        df['n'] = 0

        df['markname'] = df.iloc[:, 0]

        df['pval'] = df[pval_col]

        if beta_col == "[]":
            df['beta'] = 0
        else:
            df['beta'] = df[beta_col]

        if se_col == "[]":
            df['se'] = 0
        else:
            df['se'] = df[se_col]
    else:
        df = pd.read_csv(input_file, sep=sep, header=None)

        df['n'] = 0
        df['markname'] = df.iloc[:, 0]

        df['pval'] = df.iloc[:, int(pval_col)]

        if beta_col == "[]":
            df['beta'] = 0
        else:
            df['beta'] = df.iloc[:, int(beta_col)]

        if se_col == "[]":
            df['se'] = 0
        else:
            df['se'] = df.iloc[:, int(se_col)]

    df = df[['markname','beta','se','pval','n']]
    df.to_csv(f'{name}.csv', index=False)

if __name__ == "__main__":
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument('--input_file', help = "input file")
    parser.add_argument("--name", help = "name of output csv file")
    parser.add_argument("--header", type=int, help = "header exists (1) or not (0)")
    parser.add_argument("--pval_col", help = "column name or number (0-based) of p-value (default=1)")
    parser.add_argument("--beta_col", help = "column name or number (0-based) of beta value")
    parser.add_argument("--se_col", help = "column name or number (0-based) of SE value")
    args = parser.parse_args()

    format_cma_input(args.input_file, args.name, args.header, args.pval_col, args.beta_col, args.se_col)
