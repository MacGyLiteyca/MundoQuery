import os
import glob
import pandas
from dataclasses import dataclass, asdict
import csv
from datetime import datetime
from pydoc import text


@dataclass
class registros_historial:
    nombre_unico: str
    ruta: str
    fecha_utima_modificacion: datetime
    fecha_registro: datetime


@dataclass
class FileProcessor:
    def __init__(self, ruta_base):
        """ _summary_: Constructor

        Args:
            ruta_base (text): es un texto con la ruta a un excel donde se guardan los registros de los archivos a trabajar y los archivos trabajados
        """
        
        
    def get_lista_archivos(self):
        """ _summary_: Abre el excel, toma la hoja Archivos, y retorna un dataframe de los registros de la tabla
            Las columnas en la tabla son:
                -Ruta_Carpeta: ruta de la carpeta a validar
                    ejemplo: C:\Users\ServidorLiteyca\Nextcloud\Power BI - Liteyca\Produccion\Bonificaciones
                -Extension: si es solo la extension se requieren todos los archivos en la Ruta_Carpeta, incluido las sub carpetas, 
                            si es el nombre del archivo y la extension se requiere ese unico archivo
                    ejemplo primer caso: .xlsx
                    ejemplo segundo caso: Informe combustible.xlsx
                -Hoja: Nombre de la hoja que se requiere validar en cada excel
                    ejemplo: Consolidado
                -Referencia: texto en la primera celda donde se encuentra la tabla, las opciones que puede encontrar esta en la primera celda
                    ejemplo: Fecha
                -Ruta_Destino: Ruta y nombre del archivo de destino donde se consolidan los datos de ese registro
                    ejemplo: C:\Users\ServidorLiteyca\OneDrive - liteyca.es\ProduccionTecnicos\NextCloud\Bonificaciones.csv
                -Nombre_Unico: Es el nombre clave que se relaciona en la tabla de historial para hacer referencia al archivo
                    ejemplo: Next_Bonificacion
            Args:
        
            Return:
                _type_: dataframe
        """
        return ""
        
    def get_historial_archivos(self):
        """ _summary_: Abre el excel, toma la hoja Historial_Archivos, y retorna un dataframe de los registros de la tabla
            Las columnas en la tabla son: 
                -Nombre_Unico: Nombre que sirve para filtrar y validar los archivos de un registro de los archivos a validar
                    ejemplo: Next_Bonificacion
                -Ruta: ruta del archivo exacto que se encontro
                    ejemplo: C:\Users\ServidorLiteyca\Nextcloud\Power BI - Liteyca\Consolidado Bonificaciones.xlsx
                -Fecha_Ultima_Modificacion: fecha de modificacion del archivola ultima vez que se registro
                    ejemplo: 13/06/2024 18:39
                -Fecha_Registro: fecha en que se realizo el ultimo registro
                    ejemplo: 30/01/2025 10:30
            Args: 
            Return:
                _type_: dataframe
        """
        
    def get_lista_archivos_abrir(self):
        """ _summary_: se toma lo entregado por get_lista_archivos y utilizando Ruta_Carpeta y Extension se obtiene un listado sin duplicados 
                de los archivos que se deben validar y se analiza cuales Nombre_Unico son de cada archivo (un archivo puede tener uno o varios Nombre_Unico)
                antes de agregar un registro en el diccionario se debe validar la Fecha_Ultima_Modificacion, en caso de haber cambiado se debe agregar, 
                si no cambio se omite ese archivo
            Args: 
            Return: se entrega un diccionario donde la llave son las rutas de los archivos a validar y en el valor un 
                listado de los Nombre_Unico que se deben validar en ese archivo
        """
        
    def recorrer_lista_archivos(self):
        """ _summary_: se toma lo entregado por get_lista_archivos_abrir, lee la informacion de cada archivo, 
            Args: 
            Return:
        """
    
    def escribir_registro(self, ruta, nombre_unico):
        """ _summary_: escribe o remplaza el registro, si ya existe la ruta con el nombre unico se debe reemplazar, de lo contrario solo 
            se debe escribir los datos que lee get_historial_archivos

        Args:
            ruta (_type_): _description_
            nombre_unico (_type_): _description_
        """
    
    def ejemplo(self):
        """ _summary_: 
            Args: 
            Return:
        """