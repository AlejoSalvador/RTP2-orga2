#!/usr/bin/python

"""
    Dado un archivo de configuracion y una base de datos, crea los graficos
    especificados

        plotter.py <database_name> <archivo_de_config>

    El archivo de configuracion debe estar en formato json y tener los sig.
    datos:

    - plot: Una lista de graficos a realizar con los siguientes valores:
        - name: Nombre del grafico
        - query: String con la query a realizar para obtener los datos
        - <axis>: Eje x e y, con el sig. formato:
            values: Nombre de la columna (extraida de la query)
            label: Etiqueta a mostrar en el eje
            min: Valor minimo
            max: Valor maximo
            step: Incremento entre los valores
        - group: Solo en caso de que se desee mas de un grafico (muestra 2 
          graficos separados con el mismo eje x). Formato:
            - value_vars: Columnas de donde toma el value
            - id_vars: Nombre de la columna a utilizar para el eje x
        - color: El nombre de la columna a variar el color.Solo si se esta 
          graficando mas de una linea.
"""

import sqlite3
import sys
import math
import json
import numpy as np
from ggplot import *
import pandas as pd

def extract_img_name(filename):
    """ Extrae el nombre de la imagen dado el nombre del archivo """
    name = filename.split('.')[0]
    return name

DB = sys.argv[1]
CONFIG_FILE = sys.argv[2]
if len(sys.argv) > 3:
    DBG = True
else:
    DBG = False

def create_breaks(axis):
    lmax = axis['max']
    lmin = axis['min']
    lstep = axis['step']

    if isinstance(lstep, int):
        return list(range(lmin, lmax + 1, lstep))
    elif isinstance(lstep, float):
        return list(np.arange(lmin, lmax + 1, lstep))
    else:
        return None

def create_limits(axis):
    lmax = axis['max']
    lmin = axis['min']
    return (lmin, lmax)


def print_plot(data, dbg):
    con = sqlite3.connect(DB)
    select = data['query']
    group = False

    if 'group' in data:
        value_vars = data['group']['value_vars']
        id_vars = data['group']['id_vars']
        group = True

    dataset = pd.read_sql_query(select, con)

    x_values = data['x']['values']
    y_values = data['y']['values']
    x_limits = create_limits(data['x'])
    y_limits = create_limits(data['y'])
    x_breaks = create_breaks(data['x'])
    y_breaks = create_breaks(data['y'])
    x_label = data['x']['label']
    y_label = data['y']['label']
    if 'log' in data['x']:
        log = lambda x: math.log(x, data['x']['log'])
        dataset[x_values] = dataset[x_values].map(log)
    if 'log' in data['y']:
        log = lambda x: math.log(x, data['y']['log'])
        dataset[y_values] = dataset[y_values].map(log)

    if group:
        dataset = pd.melt(dataset, id_vars=id_vars, value_vars=value_vars)
        plot_aes = aes(x=x_values, y=y_values, color='variable', group='variable')
    elif 'color' in data:
        plot_aes = aes(x=x_values, y=y_values, color=data['color'])
    else:
        plot_aes = aes(x=x_values, y=y_values)

    if dbg:
        print dataset
    else:
        p = ggplot(plot_aes, data=dataset)
        p = p + scale_x_continuous(name=x_label, limits=x_limits, breaks=x_breaks)
        if group:
            p = p + geom_line(size=2)
            p = p + geom_point(size=20)
            p = p + facet_grid("variable", scales="free_y")
        elif 'color' in data:
            p = p + geom_line()
            p = p + geom_point()
            p = p + scale_y_continuous(name=y_label, limits=y_limits, breaks=y_breaks)
        else:
            p = p + geom_line(color='steelblue')
            p = p + geom_point(color='steelblue')
            p = p + scale_y_continuous(name=y_label, limits=y_limits, breaks=y_breaks)
        p = p + ggtitle(data['name'])
        # p = p + theme_bw()
        print p

with open(CONFIG_FILE) as data_file:
    data = json.load(data_file)

for plot in data['plot']:
    print_plot(plot, DBG)
