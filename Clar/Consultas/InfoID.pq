// InfoID
let
    TransformarInfoID =
    let
        Origen = (ParámetroInfoID as binary) => let
            Source = Excel.Workbook(ParámetroInfoID, null, true),
            Indicadores_Table = Source{[Item="Indicadores",Kind="Table"]}[Data],
            #"Removed Other Columns" = Table.SelectColumns(Indicadores_Table,{"Fecha", "External ID", "Departamento", "EECC Colaboradora"}),
            #"Changed Type" = Table.TransformColumnTypes(#"Removed Other Columns",{{"Fecha", type date}, {"External ID", type text}, {"Departamento", type text}, {"EECC Colaboradora", type text}}),
            #"Grouped Rows" = Table.Group(#"Changed Type", {"External ID", "Departamento", "EECC Colaboradora"}, {{"FechaMin", each List.Min([Fecha]), type nullable date}, {"FechaMax", each List.Max([Fecha]), type nullable date}})
        in
            #"Grouped Rows"
    in
        Origen,
    EjemploInfoID =
    let
        Source = Folder.Files("C:\Users\MacLiteyca\Nextcloud\CLARO\TablasBase\ResultadosPrevios\Indicadores"),
        Navigation1 = Source{0}[Content]
    in
        Navigation1,
    Source = Folder.Files("C:\Users\MacLiteyca\Nextcloud\CLARO\TablasBase\ResultadosPrevios\Indicadores"),
    MesAgregado = Table.TransformColumnTypes(Table.AddColumn(Source, "Mes", each Text.BetweenDelimiters([Name], ".", "."), type text),{{"Mes", type number}}),
    AnAgregado = Table.TransformColumnTypes(Table.AddColumn(MesAgregado, "Año", each Text.BetweenDelimiters([Name], ".", " ", 1, 0), type text),{{"Año", type number}}),
    MergedFilterMesACT = Table.NestedJoin(AnAgregado, {"Año", "Mes"}, MesAct, {"Año", "Mes"}, "MesAct", JoinKind.RightOuter),
    FilteredName = Table.SelectRows(MergedFilterMesACT, each [Name] <> null and [Name] <> ""),
    FilteredHiddenFiles1 = Table.SelectRows(FilteredName, each [Attributes]?[Hidden]? <> true),
    InvokeCustomFunction1 = Table.AddColumn(FilteredHiddenFiles1, "Transformar archivo", each TransformarInfoID([Content])),
    RemovedOtherColumns1 = Table.SelectColumns(InvokeCustomFunction1,{"Transformar archivo"}),
    RemovedErrors1 = Table.RemoveRowsWithErrors(RemovedOtherColumns1, {"Transformar archivo"}),
    ExpandedTableColumn1 = Table.ExpandTableColumn(RemovedErrors1, "Transformar archivo", Table.ColumnNames(TransformarInfoID(EjemploInfoID))),
    ChangedType = Table.TransformColumnTypes(ExpandedTableColumn1,{{"External ID", type text}, {"Departamento", type text}, {"EECC Colaboradora", type text}, {"FechaMin", type date}, {"FechaMax", type date}})
in
    ChangedType