import os
import sqlite3
import csv
from datetime import datetime

class DatabaseManager:
    def __init__(self, db_file):
        self.conn = sqlite3.connect(db_file)
        self.cursor = self.conn.cursor()

    def create_tables(self):
        # Crear las tablas si no existen
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS archivos (
                NombreArchivo TEXT PRIMARY KEY,
                FechaCreacion TEXT,
                FechaModificacion TEXT,
                Estado TEXT,
                FechaProceso TEXT
            )
        ''')
        # ... (crear otras tablas si es necesario)

    def insert_file_record(self, file_name, creation_date, modification_date):
        self.cursor.execute("INSERT OR IGNORE INTO archivos VALUES (?, ?, ?, 'Sin procesar', NULL)",
                           (file_name, creation_date, modification_date))

    def update_file_status(self, file_name, status, process_date):
        self.cursor.execute("UPDATE archivos SET Estado=?, FechaProceso=? WHERE NombreArchivo=?",
                           (status, process_date, file_name))

    def get_files_to_process(self):
        self.cursor.execute("SELECT NombreArchivo FROM archivos WHERE Estado='Sin procesar'")
        return [row[0] for row in self.cursor.fetchall()]

    def insert_data_into_qryas(self, file_name, data):
        # Aquí puedes personalizar la inserción según la estructura de QRYAS
        for row in data:
            self.cursor.execute("INSERT INTO QRYAS VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", row)

    def commit(self):
        self.conn.commit()

    def close(self):
        self.conn.close()


import os
import csv
from datetime import datetime

class FileManager:
    def __init__(self, directory):
        self.directory = directory

    def get_csv_files(self):
        return [os.path.join(self.directory, f) for f in os.listdir(self.directory) if f.endswith('.txt')]

    def read_csv(self, file_path):
        with open(file_path, 'r', newline='') as csvfile:
            reader = csv.reader(csvfile, delimiter='\t')
            return list(reader)
   

if __name__ == "__main__":
    db = DatabaseManager('D:\SQLite\QRYAS_Claro.db')
    db.create_tables()

    file_manager = FileManager("C:\\Users\\User\\OneDrive - LITEYCA DE COLOMBIA S.A.S\\Compartido\\LogisticaClaroAntioquia\\Informes Logistica Compartir\\QRY Organizados")

    files = file_manager.get_csv_files()
    
    # Imprimir la cantidad de archivos encontrados
    print(f"Se encontraron {len(files)} archivos CSV.")

    for file in files:
        file_name = os.path.basename(file).split('.')[0]
        creation_date = datetime.fromtimestamp(os.path.getctime(file)).strftime('%Y-%m-%d %H:%M:%S')
        modification_date = datetime.fromtimestamp(os.path.getmtime(file)).strftime('%Y-%m-%d %H:%M:%S')

        db.insert_file_record(file_name, creation_date, modification_date)

        files_to_process = db.get_files_to_process()
        for file_to_process in files_to_process:
            data = file_manager.read_csv(os.path.join(file_manager.directory, file_to_process + '.txt'))
            db.insert_data_into_qryas(file_to_process, data)
            db.update_file_status(file_to_process, 'Procesado', datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

        db.commit()

    db.close()