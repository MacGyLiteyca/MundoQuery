import csv
from dataclasses import dataclass, asdict


@dataclass
class Alumno:
    nombre: str
    apellido: str
    edad: int
    
    
Tom = Alumno('Tom', 'Algo', 10)
Pablo = Alumno('Pablo', 'Cosa', 15)


ruta_archivo = r"C:\Users\User\OneDrive - LITEYCA DE COLOMBIA S.A.S\Escritorio\Proyecto Servidor\Prueba_Archivos_CSV"
nombre_archivo = ruta_archivo + r"\\" + "archivoprueba.csv" 
 
with open(nombre_archivo, 'w', newline='')    as archivo:
        
    cursor = csv.DictWriter(archivo, fieldnames=asdict(Tom).keys())
    
    cursor.writeheader(    )
    cursor.writerow(asdict(Tom))
    cursor.writerow(asdict(Pablo))
    