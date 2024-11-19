import os
import sqlite3
from datetime import datetime
from traceback import print_exception
from click import clear

class DatabaseManager:
    def __init__(self, db_file):
        self.conn = sqlite3.connect(db_file)
        self.cursor = self.conn.cursor()

    def create_tables(self):
    # Crear las tablas si no existen
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS archivos (
                ID INTEGER PRIMARY KEY AUTOINCREMENT, -- Clave primaria autoincremental
                NombreArchivo TEXT UNIQUE,           -- Nombre de archivo como único
                FechaCreacion TEXT,
                FechaModificacion TEXT,
                Estado TEXT,
                FechaProceso TEXT
            )
        ''')
        # Crear tabla "Facturado" relacionada con "archivos"
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS Facturado (
                FECHA TEXT,
                NOMBRE TEXT,
                CEDULA_1 TEXT,
                CUENTA TEXT,
                IDORDEN_DE_TRABAJO TEXT,
                SUBTIPO_TRABAJO TEXT,
                EMPRESA TEXT, -- Simplificado el nombre para evitar problemas con caracteres especiales
                TIPO_CUADRILLAS TEXT,
                ArchivoID INTEGER, -- Clave foránea para relacionar con "archivos"
                FOREIGN KEY (ArchivoID) REFERENCES archivos (ID) ON DELETE CASCADE
            )
        ''')
        # Activar las Claves Foraneas existentes
        self.cursor.execute('PRAGMA foreign_keys = ON;')

        self.cursor.execute("""
            CREATE TABLE IF NOT EXISTS Cuadrillas (
                "CEDULA_1"	TEXT,
                "NOMBRE"	TEXT
            )
        """)
        self.cursor.execute("""
            CREATE TABLE IF NOT EXISTS Ordenes (
                FECHA TEXT,
                CUENTA TEXT,
                IDORDEN_DE_TRABAJO TEXT
            )
        """)
        # ... (crear otras tablas si es necesario)

    def anexar_cuadrillas(self):
        self.cursor.execute("""
            INSERT INTO Cuadrillas (CEDULA_1, NOMBRE)
            SELECT DISTINCT COALESCE(CEDULA_1, NOMBRE), COALESCE(NOMBRE, CEDULA_1)
            FROM Facturado
        """)

    def anexar_ordenes(self):
            self.cursor.execute("""
            INSERT INTO Ordenes (FECHA, CUENTA, IDORDEN_DE_TRABAJO)
            SELECT DISTINCT FECHA, CUENTA, IDORDEN_DE_TRABAJO
            FROM Facturado
        """)

    def insert_file_record(self, file_name, creation_date, modification_date):
        self.cursor.execute("INSERT OR IGNORE INTO archivos VALUES (?, ?, ?, 'Sin procesar', NULL)",
                           (file_name, creation_date, modification_date))

    def update_file_status(self, file_name, status, process_date):
        self.cursor.execute("UPDATE archivos SET Estado=?, FechaProceso=? WHERE NombreArchivo=?",
                           (status, process_date, file_name))

    def get_files_to_process(self):
        self.cursor.execute("SELECT NombreArchivo FROM archivos WHERE Estado<>'Procesado'")
        return [row[0] for row in self.cursor.fetchall()]

    def insert_data_into_qryas(self, file_name, data):
        # Aquí puedes personalizar la inserción según la estructura de QRYAS
        for row in data:
            self.cursor.execute("INSERT INTO QRYAS VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", row)

    def update_or_insert_file(self, file_name, creation_date, modification_date):
        """Verifica si el archivo cambió, actualiza si es necesario, o lo inserta si no existe."""
        self.cursor.execute("SELECT FechaModificacion FROM archivos WHERE NombreArchivo=?", (file_name,))
        result = self.cursor.fetchone()

        if result:  # Si el archivo ya existe
            db_modification_date = result[0]
            if db_modification_date != modification_date:
                # Si la fecha de modificación cambió, actualizar registro y estado
                self.cursor.execute(
                    "UPDATE archivos SET FechaModificacion=?, Estado='Actualizado' WHERE NombreArchivo=?",
                    (modification_date, file_name)
                )
        else:
            # Si no existe, insertar nuevo registro
            self.insert_file_record(file_name, creation_date, modification_date)

    def insert_data_into_facturado(self, data):
        if not data:
            print("No se pudo obtener datos del archivo Excel.")
            return False

        for row in data:
            # Verificar que la fila tiene 8 elementos como en la estructura de la tabla "Facturado"
            if len(row) != 8:
                print(f"Error: Row has incorrect number of elements: {len(row)}")
                continue  # Salta esta fila si tiene un número incorrecto de elementos

            # Consulta SQL para la nueva estructura de la tabla "Facturado"
            sql = """
                INSERT INTO Facturado VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """

            try:
                self.cursor.execute(sql, row)
                self.conn.commit()
            except Exception as e:
                print(f"Error inserting data into Facturado: {str(e)}")
                continue  # Continúa con la siguiente fila en caso de error

        return True

    def commit(self):
        self.conn.commit()

    def close(self):
        self.conn.close()



import os
import pandas as pd

class ExcelReader:
    def __init__(self, directory_path):
        self.directory_path = directory_path

    def get_all_excel_files(self):
        excel_files = []
        for root, _, files in os.walk(self.directory_path):
            for file in files:
                if file.endswith('.xlsx'):
                    # Combina el path del archivo y su nombre en una lista
                    full_path = os.path.join(root, file)
                    excel_files.append(full_path)
        return excel_files

    def read_excel_sheet(self, file_path, sheet_name):
        # Lista de columnas requeridas en la tabla "Facturado"
        required_columns = [
            "FECHA", "NOMBRE", "CEDULA_1", "CUENTA", 
            "IDORDEN_DE_TRABAJO", "SUBTIPO_TRABAJO", 
            "CONFORMACION DE CUADRILLAS.EMPRESA", "TIPO CUADRILLAS"
        ]
        
        try:
            # Cargar hoja de Excel
            df = pd.read_excel(file_path, sheet_name=sheet_name)
            
            # Seleccionar solo las columnas requeridas y agregar `None` donde falten
            data = []
            for _, row in df.iterrows():
                filtered_row = [str(row[col]) if col in df.columns else None for col in required_columns]
                data.append(filtered_row)
                
            return data
        except Exception as e:
            print(f"Error reading {file_path} in sheet {sheet_name}: {e}")
            return None



import os
from datetime import datetime

if __name__ == "__main__":
    db = DatabaseManager('D:\\SQLite\\Facturacion_Claro.db')
    db.create_tables()

    # Crear instancia de ExcelReader
    excel_reader = ExcelReader('C:\\Users\\User\\OneDrive - LITEYCA DE COLOMBIA S.A.S\\Compartido\\ProyectoClaroAnt\\Claro Bot\\Facturacion')

    # Obtener el listado de archivos .xlsx con sus rutas completas
    archivos_excel = excel_reader.get_all_excel_files()

    for file in archivos_excel:
        if os.path.isfile(file):  # `file` ya contiene la ruta completa, así que solo verificamos si es archivo
            file_name, _ = os.path.splitext(os.path.basename(file))
            creation_date = datetime.fromtimestamp(os.path.getctime(file)).strftime('%Y-%m-%d %H:%M:%S')
            modification_date = datetime.fromtimestamp(os.path.getmtime(file)).strftime('%Y-%m-%d %H:%M:%S')

            # Guardar la ruta completa del archivo en la base de datos, en lugar de solo el nombre
            db.insert_file_record(file_name, creation_date, modification_date)

        data = excel_reader.read_excel_sheet(file, 'FINAL DE FACT')
        # Insertar los datos en la base de datos
        success = db.insert_data_into_facturado(data)
        if success:
            db.update_file_status(file_name, 'Procesado', datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        else:
            db.update_file_status(file_name, 'Error', datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    db.anexar_ordenes()
    db.anexar_cuadrillas()
    

    db.commit()
    db.close()
