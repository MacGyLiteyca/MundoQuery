// Empresas
let
    Source = Excel.Workbook(File.Contents("C:\Users\MacLiteyca\Nextcloud\CLARO\TablasBase\ResultadosPrevios\ConfiguracionTablero\Utilidades.xlsx"), null, true),
    Estado_Table = Source{[Item="Estado",Kind="Table"]}[Data],
    ChangedType = Table.TransformColumnTypes(Estado_Table,{{"Compañia", type text}, {"Estado", type text}, {"EECC Colaboradora", type text}}),
    FilteredNull = Table.SelectRows(ChangedType, each [EECC Colaboradora] <> null and [EECC Colaboradora] <> ""),
    EECCColaboradora = FilteredNull[EECC Colaboradora],
    RemovedDuplicates = List.Distinct(EECCColaboradora)
in
    RemovedDuplicates