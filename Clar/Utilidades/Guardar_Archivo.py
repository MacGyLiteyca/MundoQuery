import csv
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path


@dataclass
class ArchivoRegistro:
    Nombre_Unico: str
    Ruta: str
    Fecha_Ultima_Modificacion: str
    Fecha_Registro: str


class GestorArchivos:
    def __init__(self):
        self.directorio = Path(r"C:\Users\User\OneDrive - LITEYCA DE COLOMBIA S.A.S\Compartido\ProduccionTecnicos\1 Archivos Tablero Bi CSV")
        self.archivo = self.directorio / "Registro_Archivos.csv"
        self.campos = ["Nombre_Unico", "Ruta", "Fecha_Ultima_Modificacion", "Fecha_Registro"]
        
        self.directorio.mkdir(parents=True, exist_ok=True)
        
        # Crear archivo con encabezados si no existe
        if not self.archivo.exists():
            with open(self.archivo, 'w', newline='', encoding='utf-8-sig') as f:
                writer = csv.DictWriter(f, fieldnames=self.campos)
                writer.writeheader()

    def guardar_registro(self, registro: ArchivoRegistro):
        """Guarda un registro en el archivo CSV"""
        with open(self.archivo, mode='a', newline='', encoding='utf-8-sig') as f:
            writer = csv.DictWriter(f, fieldnames=self.campos)
            writer.writerow(asdict(registro))

    def leer_registros(self) -> list[ArchivoRegistro]:
        """Lee todos los registros del archivo CSV"""
        registros = []
        
        with open(self.archivo, mode='r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            
            # Verificar encabezados
            if reader.fieldnames != self.campos:
                raise ValueError("Los encabezados del archivo CSV no coinciden con los campos esperados")
            
            for fila in reader:
                registros.append(ArchivoRegistro(
                    Nombre_Unico=fila['Nombre_Unico'],
                    Ruta=fila['Ruta'],
                    Fecha_Ultima_Modificacion=fila['Fecha_Ultima_Modificacion'],
                    Fecha_Registro=fila['Fecha_Registro']
                ))
        
        return registros


# Ejemplo de uso
if __name__ == '__main__':
    gestor = GestorArchivos()
    
    # Crear un registro de ejemplo
    nuevo_registro = ArchivoRegistro(
        Nombre_Unico="archivo_001",
        Ruta="C:/ruta/ejemplo.txt",
        Fecha_Ultima_Modificacion=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        Fecha_Registro=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    )
    
    # Guardar el registro
    gestor.guardar_registro(nuevo_registro)
    
    # Leer todos los registros
    registros = gestor.leer_registros()
    for reg in registros:
        print(f"Registro: {reg.Nombre_Unico} - {reg.Ruta}")