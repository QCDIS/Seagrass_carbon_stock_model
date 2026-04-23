# Template cell

## <a name='paramcell'></a>param cell

```python
# DO NOT CONTAINERISE
# =====
# Dependency
# -----
# ! pip install -r requirements.txt
# ! pip list
# ! conda list

# !conda install -y requests
# !conda install -y nest_asyncio

# !conda install -y geopandas=0.10.2
# !conda install -y rdflib=6.1.1

# !pip show requests
# !pip show nest_asyncio

# !pip show geopandas
# !pip show rdflib

import os
import sys
import glob
from datetime import datetime
import importlib.util as importlib_util

import shutil
from pathlib import Path

from io import StringIO
import zipfile
import asyncio
import requests
from urllib import parse
import json.decoder

import csv
import pandas as pd

# import nest_asyncio

# base settings
# -----
conf_vlab_name     = "DNA"
# conf_workflow_name = "PEMA"

# conf_workflow_id   = f"wid-{datetime.now().strftime('%Y%m%d_%H%M%S%f')}"
param_workflow_name = "workflow name"

# dev
# -----
# library: --volume="//c/DockerShare/DNA:/home/jovyan" naavre-fl-dna-jupyter:local
# NaaVRE: /home/jovyan/Virtual Labs/DNA/Git public
# conf_dir_code = os.path.join("/", "home", "jovyan", "Virtual Labs", conf_vlab_name, "Git public", "library")
# if not os.path.exists(conf_dir_code):
#     os.makedirs(conf_dir_code)

# conf_dir_data  = os.path.join("/", "home", "jovyan", "Cloud Storage", "naa-vre-user-data", conf_vlab_name, param_workflow_name)
# if not os.path.exists(conf_dir_data):
#     os.makedirs(conf_dir_data)

# local
# -----
conf_dir_workspace = os.path.join("/", "home", "jovyan", "Cloud Storage")

conf_dir_data_local_tmp = os.path.join("/", "tmp", "data")

# MINIO
# -----
conf_minio_public_bucket      = "naa-vre-public"
conf_minio_public_bucket_root = f"vl-{conf_vlab_name.lower()}"
conf_minio_public_local_root  = os.path.join(conf_dir_workspace, conf_minio_public_bucket, conf_minio_public_bucket_root)
conf_minio_public_local_code  = os.path.join(conf_dir_workspace, conf_minio_public_bucket, conf_minio_public_bucket_root, "code")
conf_minio_public_local_data  = os.path.join(conf_dir_workspace, conf_minio_public_bucket, conf_minio_public_bucket_root, "data")

conf_minio_user_bucket        = "naa-vre-user-data"
# conf_minio_user_bucket_root   = param_user_email
conf_minio_user_bucket_root   = conf_vlab_name
conf_minio_user_local_root    = os.path.join(conf_dir_workspace, conf_minio_user_bucket,   conf_minio_user_bucket_root)
conf_minio_user_local_code    = os.path.join(conf_dir_workspace, conf_minio_user_bucket,   conf_minio_user_bucket_root,   "library")
conf_minio_user_local_data    = os.path.join(conf_dir_workspace, conf_minio_user_bucket,   conf_minio_user_bucket_root,   param_workflow_name)
conf_minio_user_local_flog    = os.path.join(conf_minio_user_local_data, "log.md")

# for workflow step
# .....
# if os.path.exists(conf_minio_user_local_flog):
#     with open(conf_minio_user_local_flog, "a+") as fp_log:
#         fp_log.write(f"\n## {workflow_step}\n") 
# else:
#     if not os.path.exists(conf_minio_user_local_data):
#         os.makedirs(conf_minio_user_local_data)
#     with open(conf_minio_user_local_flog, "w+") as fp_log:
#         fp_log.write(f"\n## {workflow_step}\n") 

# API key
# -----
# If running under NaaVRE, input `your api key` with the correct value and input in the GUI:
# secret_SERVICE_KEY = "d18e08911c964d45912eb1e954adf994"
# secret_SERVICE_KEY = SecretsProvider().set_secret("secret_SERVICE_KEY")
# secret_SERVICE_KEY = SecretsProvider().get_secret("secret_SERVICE_KEY")

# Input param
# -----
# workflow: 01, 02
# .....

# PEMA-SequenceRetriever
# .....
conf_fname_seq_zip = "mydata.zip"
conf_fpath_seq_zip = "mydata"                                                  # path in zip file

param_gene_sequences = "SRR3231901"
# param_gene_sequences = "ERR3460470,ERR4018451,ERR4018452"                    # user input, sep=","

# PEMA-Runner
# .....
# return: case_id
conf_fname_par_tsv  = "parameters.tsv"

param_fname_par_tsv = "Template-parameters.tsv"                                # upload file to conf_minio_user_local_root
# add param_ for allowed settings in pema parameters.tsv

# OTU
# .....
# pema_otu_delimiter = "\t"
# bold_otu_delimiter = ","
conf_delimiter_tsv = "\t"
conf_delimiter_csv = ","

print("Finish: NaaVRE parameters")
print(f"Workspace public:")
print(f"  Root: {conf_minio_public_local_root}")
print(f"  Code: {conf_minio_public_local_code}")
print(f"  Data: {conf_minio_public_local_data}")

print(f"Workspace user:")
print(f"  Root: {conf_minio_user_local_root}")
print(f"  Code: {conf_minio_user_local_code}")
print(f"  Data: {conf_minio_user_local_data}")
print(f"  Log:  {conf_minio_user_local_flog}")

```

## <a name='execcell'></a>exec cell

```python
# ECVs, workflow start
# ---
# NaaVRE:
#  cell:
#   outputs:
#    - dummy_cell_arg_o: String
# ...

import os
import sys
from datetime import datetime

# sys.path.append(conf_minio_public_local_code)
# sys.path.append(conf_minio_user_local_code)

# prepare folders
# .....
if not os.path.exists(conf_dir_data_local_tmp):
    os.makedirs(conf_dir_data_local_tmp)

# if not os.path.exists(conf_minio_public_local_root):
#     os.makedirs(conf_minio_public_local_root)

if not os.path.exists(conf_minio_user_local_root):
    os.makedirs(conf_minio_user_local_root)

if not os.path.exists(conf_minio_user_local_data):
    os.makedirs(conf_minio_user_local_data)
    
with open(conf_minio_user_local_flog, "w+") as fp_log:
    fp_log.write(f"# {param_workflow_name}\n")

# create log
# .....
print(param_workflow_name)
workflow_step = f"{conf_vlab_name}-Start"

if os.path.exists(conf_minio_user_local_flog):
    with open(conf_minio_user_local_flog, "a+") as fp_log:
        fp_log.write(f"\n## {workflow_step}\n") 
else:
    if not os.path.exists(conf_minio_user_local_data):
        os.makedirs(conf_minio_user_local_data)
    with open(conf_minio_user_local_flog, "w+") as fp_log:
        fp_log.write(f"\n## {workflow_step}\n") 

# lib, minio_public
# -----
# sys.path.append(conf_minio_public_local_code)
# print("sys.path minio_public")
# for tmp_path in sys.path: print(f"* {tmp_path}")

# py_module_name = 'classify_invasiveness'
# if py_module_name in sys.modules:
#     print(f"{py_module_name} already in sys.modules")
# elif (spec := importlib_util.find_spec(py_module_name)) is not None:
#     # If you chose to perform the actual import ...
#     py_module_obj = importlib_util.module_from_spec(spec)
#     sys.modules[py_module_name] = py_module_obj
#     spec.loader.exec_module(py_module_obj)
#     print(f"{py_module_name} has been imported")
# else:
#     print(f"can't find the {py_module_name} module")

# lib, minio_user
# -----
# sys.path.append(conf_minio_user_local_code)
# print("sys.path minio_user")
# for tmp_path in sys.path: print(f"* {tmp_path}")

# input
# -----
dummy_cell_arg_i = "dummy input"

# output
# -----
dummy_cell_arg_o = "dummy output"

# func
# -----

# start
# -----

# -----
with open(conf_minio_user_local_flog, "a+") as fp_log:
    fp_log.write(f"\nFinish: {workflow_step}\n")
    fp_log.write(f"\nOutput: {conf_minio_user_local_data}\n")

print(f"Finish: {workflow_step}")

```

# BlueCarbon, Seagrass

