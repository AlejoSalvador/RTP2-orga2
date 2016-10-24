#!/usr/bin/python3

"""
    Dado un archivo de configuracion corre los experimentos correspondientes
    guardando los resultados en un log.

        run_tests.py <archivo_de_config>

    El archivo de configuracion debe estar en formato json y tener los sig.
    datos:

    - nombre: El nombre del experimento (Se usa para el archivo de salida)
    - filtros: Una lista de los filtros a testear con el sig. formato:
        - filtro: Nombre del filtro
        - iteraciones: Cantidad de iteraciones a correr
    - implementaciones: Una lista de las implementaciones a testear para 
      cada filtro.
    - imgs: Una lista de las imagenes de entrada a testear.
    - cache: Se utiliza para saber si se debe correr tests de cache.
"""

import subprocess
import sys
import os
import json
import re

CONFIG_FILE = sys.argv[1]
LOG_FILE = 'results.csv'
TIME_CMD = 'time'
CACHE_CMD = 'valgrind --tool=cachegrind'
TP_EXE = '../build/tp2'
IMG_DIR = 'test_imgs/'
OUT_DIR = 'out'
OUT_OPT = ' -o ' + OUT_DIR
REGEX_ITER = r'ciclos insumidos por llamada : (\d+)'
REGEX_USER = r'([\d\.]+)user'
REGEX_CPU = r'([\d]+%)CPU'
REGEX_PID = r'==(\d+)=='
REGEX_CACHE = r'''
    \s*(?P<InstR>[\d,]+)        # captura reads de instrucciones
    \s*(?P<InstL1MR>[\d,]+)     # captura misses de reads de instrucciones a L1
    \s*(?P<InstL2MR>[\d,]+)     # captura misses de reads de instrucciones a L2
    \s*(?P<DataR>[\d,]+)        # captura reads de data
    \s*(?P<DataL1MR>[\d,]+)     # captura misses de reads de data a L1
    \s*(?P<DataL2MR>[\d,]+)     # captura misses de reads de data a L2
    \s*(?P<DataW>[\d,]+)        # captura writes de data
    \s*(?P<DataL1MW>[\d,]+)     # captura misses de writes de data a L1
    \s*(?P<DataL2MW>[\d,]+)     # captura misses de writes de data a L2
    '''
INFO_EXP = '\nEjecutando experimento {}/{}:\n  filtro: {}\n  implementacion: {}\n  imagen de entrada: {}\n'
LOG_HEADER = 'filtro\timplementacion\tin_img\tancho\talto\tciclos_totales\tduracion\tuso_cpu'
CACHE_HEADER = '\tpid\tinst_reads\tinst_l1mr\tinst_l2mr\tdata_reads\tdata_l1mr\tdata_l2mr\tdata_writes\tdata_l1mw\tdata_l2mw'

re_iter = re.compile(REGEX_ITER, re.MULTILINE)
re_user = re.compile(REGEX_USER)
re_cpu = re.compile(REGEX_CPU)
re_pid = re.compile(REGEX_PID, re.MULTILINE )
re_cache = re.compile(REGEX_CACHE, re.VERBOSE)

def processTPOutput(output):
    """ Procesa el output de tp2 """
    m = re_iter.search(output)

    return m.group(1)

def processTime(output):
    """ Procesa el output de time """
    user = re_user.search(output)
    cpu = re_cpu.search(output)

    return user.group(1), cpu.group(1)

def extract_sizes(filename):
    size = filename.split('.')[1]
    ancho, alto = size.split('x')
    return ancho, alto

def writeLogLine(data, results):
    """ Escribe los resultados del test en el log """

    filename = data['nombre'] + '/' + data['nombre'] + '.csv'
    logfile = open(filename, 'a')
    log_str = '\t'.join(results) + '\n'
    header = LOG_HEADER
    if 'cache' in data:
        header += CACHE_HEADER + '\n'
    else:
        header += '\n'

    try:
        if os.stat(filename).st_size == 0:
            logfile.write(header)
        logfile.write(log_str)
    finally:
        logfile.close()

def ReadCachegrindOutput(data, filtro, pid):
    """ Lee el resultado de cachegrind y devuelve los datos parseados en una lista """
    cachefile = 'cachegrind.out.' + pid
    proc = subprocess.Popen(['cg_annotate ' + cachefile],
                stdout=subprocess.PIPE,
                shell=True,
                universal_newlines=True
                )
    cg_annotate_stdout = proc.communicate('through stdin to stdout')[0]

    for line in cg_annotate_stdout.split("\n"):
        if filtro in line:
            match = re_cache.match(line)

    out_path = data['nombre'] + '/' 'cachegrindOutputs'
    if not os.path.exists(out_path):
        os.makedirs(out_path)

    move_to = out_path + '/' + pid
    os.rename(cachefile, move_to)

    return [
        pid,
        match.group('InstR'),
        match.group('InstL1MR'),
        match.group('InstL2MR'),
        match.group('DataR'),
        match.group('DataL1MR'),
        match.group('DataL2MR'),
        match.group('DataW'),
        match.group('DataL1MW'),
        match.group('DataL2MW'),
        ]

def main(data):
    if not os.path.exists(OUT_DIR):
        os.makedirs(OUT_DIR)

    exp_name = data['nombre']
    if not os.path.exists(exp_name):
        os.makedirs(exp_name)


    print('Comenzando ejecucion de experimentos...')
    cant_exp = len(data['implementaciones']) * len(data['imgs']) * len(data['filtros'])
    curr_exp = 1
    for curr_filtro in data['filtros']:
        filtro = curr_filtro['filtro']
        if 'iteraciones' in curr_filtro:
            itter = '-t ' + str(curr_filtro['iteraciones']) + " "
        else:
            itter = ''

        for imp in data['implementaciones']:
            curr_imp = '-i ' + imp
            for img in data['imgs']:
                in_img = IMG_DIR + img

                tp_cmd = " ".join([
                    TP_EXE,
                    filtro,
                    curr_imp,
                    itter,
                    in_img
                    ])

                if filtro == 'combinar':
                    tp_cmd += " 128.0"
                if filtro == 'colorizar':
                    tp_cmd += " 0.5"

                tp_cmd += OUT_OPT

                print("-"*40 + INFO_EXP.format(
                    curr_exp, cant_exp, filtro, curr_imp, in_img))
                print('  Iniciando ejecucion...')
                proc = subprocess.Popen([" ".join([TIME_CMD, tp_cmd])],
                    stderr=subprocess.PIPE, 
                    stdout=subprocess.PIPE,
                    shell=True,
                    universal_newlines=True
                    )
                stdout_value, stderr_value = proc.communicate('through stdin to stdout')
                print('  Procesando datos de TP...')
                res_iter = processTPOutput(stdout_value)
                print('  Procesando datos de time...')
                res_user, res_cpu = processTime(stderr_value)

                ancho, alto = extract_sizes(img)

                log_vars = [
                    filtro,
                    imp,
                    img,
                    ancho,
                    alto,
                    res_iter,
                    res_user,
                    res_cpu
                    ]

                if 'cache' in data:
                    print('  Ejecutando cachegrind...')
                    cache_proc = subprocess.Popen(" ".join([CACHE_CMD, tp_cmd]),
                        stderr=subprocess.PIPE,
                        stdout=subprocess.PIPE,
                        shell=True,
                        universal_newlines=True
                        )
                    cachegrind_stderr = cache_proc.communicate()[1]

                    print('  Procesando datos de cache...')
                    pid = re_pid.search(cachegrind_stderr).group(1)
                    cache_res = ReadCachegrindOutput(data, filtro, pid)
                    log_vars += cache_res

                writeLogLine(data, log_vars)
                print('\nListo!\n')
                curr_exp += 1

with open(CONFIG_FILE) as data_file:
    data = json.load(data_file)

main(data)
