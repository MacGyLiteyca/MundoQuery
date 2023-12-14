import requests
import os

class Downloader:
    def __init__(self, output_directory, file_urls):
        self.output_directory = output_directory
        self.file_urls = file_urls

    def download(self):
        for filename, url in self.file_urls.items():
            output_file_path = os.path.join(self.output_directory, filename + ".csv")
            print(f"Filename: {output_file_path}, Url {url}")
            try:
                response = requests.get(url)
                response.raise_for_status()

                with open(output_file_path, "wb") as file:
                    file.write(response.content)

                print(f"Archivo guardado exitosamente en: {output_file_path}")
            except requests.exceptions.RequestException as e:
                print(f"Error al descargar el archivo: {e}")


if __name__ == "__main__":
    output_directory = "C:/Users/jorge/Downloads/"
    file_urls = {
        "archivo_1": "https://docs.google.com/spreadsheets/d/e/2PACX-1vQnLMZnnYcfoGkJ5_Hn2WY2agpbpxn3fhIOo_6LIypu7zua7KGotSXP-ftJsV14sZcwTHak5HJnZ4FW/pub?gid=403081310&single=true&output=csv",
        "archivo_2": "https://docs.google.com/spreadsheets/d/e/2PACX-1vQnLMZnnYcfoGkJ5_Hn2WY2agpbpxn3fhIOo_6LIypu7zua7KGotSXP-ftJsV14sZcwTHak5HJnZ4FW/pub?gid=403081310&single=true&output=csv"
    }

    downloader = Downloader(output_directory, file_urls)
    downloader.download()