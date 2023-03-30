// Empresas
let
    MyRuta = Ruta&"\ResultadosPrevios\ConfiguracionTablero\Utilidades.xlsx", 
    Source = Excel.Workbook(File.Contents(MyRuta), null, true),
    Estado_Table = Source{[Item="Estado",Kind="Table"]}[Data],
    ChangedType = Table.TransformColumnTypes(Estado_Table,{{"Compañia", type text}, {"Estado", type text}, {"EECC Colaboradora", type text}}),
    FilteredNull = Table.SelectRows(ChangedType, each [EECC Colaboradora] <> null and [EECC Colaboradora] <> ""),
    EECCColaboradora = FilteredNull[EECC Colaboradora],
    RemovedDuplicates = List.Distinct(EECCColaboradora)
in
    RemovedDuplicates