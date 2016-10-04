# coding: utf-8

import psyutils as pu
import os
import pandas as pd
import numpy as np
from itertools import product


""" Script to do data munging.


Tom Wallis wrote it.
"""

experiment_num = 1

#---------------------------------------------------------------
# Do stuff
#---------------------------------------------------------------

top_dir = pu.files.project_directory('letter-distortion-detection')

raw_dir = os.path.join(top_dir, 'raw-data')

out_dir = os.path.join(top_dir, 'results', 'experiment_{}'.
                       format(experiment_num))

if not os.path.exists(out_dir):
    os.makedirs(out_dir)

# enumerate files for this experiment:
subjs = ['2', '5', '7', '8', '9']
conds = ['flanked', 'unflanked']
distortion = ['rf', 'bex']

dat = pd.DataFrame()

for s, c, d in product(subjs, conds, distortion):
    this_session = 1
    finished = False

    while not finished:
        fname = 'distortionData_{}_{}_sub_{}_session_{}.csv'.format(
                c, d, s, this_session)
        fname = os.path.join(raw_dir, fname)

        if os.path.exists(fname):
            this_dat = pd.read_csv(fname, sep='\t')
            dat = dat.append(this_dat, ignore_index=True)
            this_session += 1
        else:
            finished = True


def new_col(col):
    # rename columns containing leading space:
    col = col.rstrip()
    return col.lstrip()

dat.rename(columns=new_col, inplace=True)

# create a "correct" column by comparing target and response:
dat.targ_pos = dat.targ_pos.apply(str)
dat.response = dat.response.apply(str)
dat['correct'] = 0
dat.loc[dat['targ_pos'] == dat['response'], 'correct'] = 1
# nans for missed responses:
dat.loc[dat['response'] == 'na', 'correct'] = np.nan

# re-sort:
dat.sort_values(by=['subject', 'session', 'trial'], inplace=True)

# save data:
fname = os.path.join(out_dir, 'all_data.csv')
dat.to_csv(fname, index=False)

print('Success!')
