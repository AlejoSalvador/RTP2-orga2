#!/usr/bin/python3

"""
    Dado un archivo de configuracion crea una table en la database especificada
    y almacena los resultados de los experimentos.

        dump_to_sqlite.py <database_name> <archivo_de_config>

    El archivo de configuracion debe estar en formato json y tener los sig.
    datos:

    - table_name: El nombre de la tabla dentro de la base de datos
    - table_schema: Una lista de diccionarios por cada columna con el sig. 
      formato:
        - col_name: Nombre de la columna
        - datatype: Tipo de datos a almacenar
"""

import csv
import sqlite3
import json
import sys
import re

DB = sys.argv[1]
CONFIG_FILE = sys.argv[2]
REGEX_NUM = r'[\d\,]*,\d\d\d'
re_num = re.compile(REGEX_NUM)

with open(CONFIG_FILE) as data_file:
    data = json.load(data_file)

table = data['table_name']

print('Comenzando proceso de dump...')
print('  DB: ' + DB)
print('  Tabla: ' + table)

con = sqlite3.connect(DB)
cur = con.cursor()
cur.execute("DROP TABLE IF EXISTS {}".format(table))

table_cols = ''
placeholder = ''

print('insertando filas...')

for column in data['table_schema']:
    placeholder += '?, '
    table_cols += column['col_name'] + ' ' + column['datatype'] + ', '

table_cols = table_cols[:-2]
placeholder = placeholder[:-2]

cur.execute("CREATE TABLE {}({})".format(table, table_cols))

query_insert = 'INSERT INTO {} VALUES ({})'.format(table, placeholder)
csv_file = data['nombre'] + '/' + data['nombre'] + '.csv'
with open(csv_file,'r') as file:
    csvr = csv.reader(file, delimiter='\t')
    for row in csvr:
        for idx, col in enumerate(row):
            if re_num.match(col):
                row[idx] = col.replace(',', '')

        if row[0].lower() == 'filtro':
            continue

        cur.execute(query_insert, row)


con.commit()
con.close()

print('Listo!')