#!/usr/bin/python3

"""
    Genera imagenes para los experimentos a partir del archivo de configuracion

        make_bench_imgs.py <archivo_de_config>

    El archivo de configuracion debe estar en formato json y tener los sig.
    datos:

    - convert_imgs: Lista de imagenes source a convertir.
    - convert_sizes: Lista de tamanos de salida. El formato debe ser: 
      <ancho>x<alto>. 
"""

import subprocess
import sys
import os
import json

CONFIG_FILE = sys.argv[1]
IMG_DIR = '../img'
OUT_DIR = 'test_imgs'
CONVERT_CMD = "convert -resize {}! {} {}"

if not os.path.exists(OUT_DIR):
    os.makedirs(OUT_DIR)

with open(CONFIG_FILE) as data_file:
    data = json.load(data_file)

for filename in data['convert_imgs']:
    print(filename)

    for size in data['convert_sizes']:
        sys.stdout.write("  " + size + "\n")
        name = filename.split('.')
        file_in = IMG_DIR + "/" + filename
        file_out = OUT_DIR + "/" + name[0] + "." + size + "." + name[1]
        cmd = CONVERT_CMD.format(size, file_in, file_out)
        subprocess.call(cmd, shell=True)

print("Se finalizo la conversion")
