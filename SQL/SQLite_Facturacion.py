import os
import sqlite3
from datetime import datetime
import pandas as pd  # Usado para leer archivos Excel


# Clase para manejar la base de datos
class DatabaseManager:
    def __init__(self, db_file):
        self.conn = sqlite3.connect(db_file)
        self.cursor = self.conn.cursor()

    def create_tables(self):
        # Crear tablas necesarias en la base de datos
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS archivos (
                ID INTEGER PRIMARY KEY AUTOINCREMENT,
                NombreArchivo TEXT UNIQUE,
                FechaCreacion TEXT,
                FechaModificacion TEXT,
                Estado TEXT,
                FechaProceso TEXT
            )
        ''')

        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS Facturado (
                FECHA TEXT,
                NOMBRE TEXT,
                CEDULA_1 TEXT,
                CUENTA TEXT,
                IDORDEN_DE_TRABAJO TEXT,
                SUBTIPO_TRABAJO TEXT,
                EMPRESA TEXT,
                TIPO_CUADRILLAS TEXT,
                ArchivoID INTEGER,
                FOREIGN KEY (ArchivoID) REFERENCES archivos (ID) ON DELETE CASCADE
            )
        ''')

        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS Cuadrillas (
                CEDULA_1 TEXT,
                NOMBRE TEXT
            )
        ''')

        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS Ordenes (
                FECHA TEXT,
                CUENTA TEXT,
                IDORDEN_DE_TRABAJO TEXT
            )
        ''')

        # Activar claves foráneas
        self.cursor.execute('PRAGMA foreign_keys = ON;')

    def anexar_cuadrillas(self):
        self.cursor.execute('''
            INSERT INTO Cuadrillas (CEDULA_1, NOMBRE)
            SELECT DISTINCT COALESCE(CEDULA_1, NOMBRE), COALESCE(NOMBRE, CEDULA_1)
            FROM Facturado
        ''')

    def anexar_ordenes(self):
        self.cursor.execute('''
            INSERT INTO Ordenes (FECHA, CUENTA, IDORDEN_DE_TRABAJO)
            SELECT DISTINCT FECHA, CUENTA, IDORDEN_DE_TRABAJO
            FROM Facturado
        ''')

    def insert_file_record(self, file_name, creation_date, modification_date):
        self.cursor.execute('''
            INSERT OR IGNORE INTO archivos (NombreArchivo, FechaCreacion, FechaModificacion, Estado)
            VALUES (?, ?, ?, 'Sin procesar')
        ''', (file_name, creation_date, modification_date))

    def update_file_status(self, file_name, status, process_date):
        self.cursor.execute('''
            UPDATE archivos SET Estado=?, FechaProceso=? WHERE NombreArchivo=?
        ''', (status, process_date, file_name))

    def insert_data_into_facturado(self, data):
        if not data:
            print("No se pudo obtener datos del archivo Excel.")
            return False

        for row in data:
            if len(row) != 8:  # Validar número correcto de columnas
                print(f"Error: Fila con número incorrecto de elementos: {len(row)}")
                continue

            sql = '''
                INSERT INTO Facturado (FECHA, NOMBRE, CEDULA_1, CUENTA, IDORDEN_DE_TRABAJO, SUBTIPO_TRABAJO, EMPRESA, TIPO_CUADRILLAS)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            '''
            try:
                self.cursor.execute(sql, row)
            except Exception as e:
                print(f"Error al insertar datos en Facturado: {e}")
                continue

        return True

    def commit(self):
        self.conn.commit()

    def close(self):
        self.conn.close()


# Clase para manejar la lectura de archivos Excel
class ExcelReader:
    def __init__(self, directory_path):
        self.directory_path = directory_path

    def get_all_excel_files(self):
        excel_files = []
        for root, _, files in os.walk(self.directory_path):
            for file in files:
                if file.endswith('.xlsx'):
                    excel_files.append(os.path.join(root, file))
        return excel_files

    def read_excel_sheet(self, file_path, sheet_name):
        required_columns = [
            "FECHA", "NOMBRE", "CEDULA_1", "CUENTA",
            "IDORDEN_DE_TRABAJO", "SUBTIPO_TRABAJO",
            "CONFORMACION DE CUADRILLAS.EMPRESA", "TIPO CUADRILLAS"
        ]
        
        try:
            df = pd.read_excel(file_path, sheet_name=sheet_name)
            data = [
                [str(row[col]) if col in df.columns else None for col in required_columns]
                for _, row in df.iterrows()
            ]
            return data
        except Exception as e:
            print(f"Error al leer {file_path}, hoja {sheet_name}: {e}")
            return None


# Función principal
if __name__ == "__main__":
    db = DatabaseManager('D:\\SQLite\\Facturacion_Claro.db')
    db.create_tables()

    excel_reader = ExcelReader(
        'C:\\Users\\User\\OneDrive - LITEYCA DE COLOMBIA S.A.S\\Compartido\\ProyectoClaroAnt\\Claro Bot\\Facturacion'
    )

    archivos_excel = excel_reader.get_all_excel_files()

    for file in archivos_excel:
        if os.path.isfile(file):
            file_name, _ = os.path.splitext(os.path.basename(file))
            creation_date = datetime.fromtimestamp(os.path.getctime(file)).strftime('%Y-%m-%d %H:%M:%S')
            modification_date = datetime.fromtimestamp(os.path.getmtime(file)).strftime('%Y-%m-%d %H:%M:%S')

            db.insert_file_record(file_name, creation_date, modification_date)

            data = excel_reader.read_excel_sheet(file, 'FINAL DE FACT')
            if db.insert_data_into_facturado(data):
                db.update_file_status(file_name, 'Procesado', datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            else:
                db.update_file_status(file_name, 'Error', datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    db.anexar_ordenes()
    db.anexar_cuadrillas()

    db.commit()
    db.close()