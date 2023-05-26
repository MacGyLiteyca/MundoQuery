//fxMiCalendarioDia
let 
    fxMiCalendarioDia = (TablaReferencia as table, NombreColumnaInicial as text, NombreColumnaFinal as text) => let
    //Tabla inicial
        Source = TablaReferencia,
    //Columna de fecha inicial
        FechaMenor = NombreColumnaInicial,
    //Columna de fecha final
        FechaMayor= NombreColumnaFinal,
    //Se duplica la columna de fecha menor
        Duplicated_Inicial = Table.DuplicateColumn(Source, FechaMenor, "FechaMin"),
    //Se obtiene la menor fecha como variable
        FechaInicial = List.Min(Duplicated_Inicial[FechaMin]),
    //Se duplica la columna de fecha mayor
        Duplicated_Final = Table.DuplicateColumn(Duplicated_Inicial, FechaMayor, "FechaMax"),
    //Se obtiene la mayor fecha como variable
        FechaFinal = List.Max(Duplicated_Final[FechaMax]),
    //Se retoma desde el paso Duplicated_Final y se le agrega la fecha
        Added_Fecha = Table.AddColumn(Duplicated_Final, "Fecha", each if([FechaMin]<[FechaMax])then({Number.From([FechaMin])..Number.From([FechaMax])})else({Number.From([FechaMax])..Number.From([FechaMin])})),
    //Se expande la fecha
        Expanded_Fecha = Table.ExpandListColumn(Added_Fecha, "Fecha"),
    //Se cambia al tipo de datos date la columna fecha
        Changed_Type_Fecha = Table.TransformColumnTypes(Expanded_Fecha,{{"Fecha", type date}}),
        Inserted_Year = Table.AddColumn(Changed_Type_Fecha, "Año", each Date.Year([Fecha]), Int64.Type),
        Inserted_Month = Table.AddColumn(Inserted_Year, "Mes", each Date.Month([Fecha]), Int64.Type),
    //Se quitan las fechas utilizadas como referencia
        Removed_Columns_Fechas = Table.RemoveColumns(Inserted_Month,{FechaMenor, FechaMayor, "FechaMin", "FechaMax", "Fecha"}),
        Removed_Duplicates = Table.Distinct(Removed_Columns_Fechas)
    in
        Removed_Duplicates
in
    fxMiCalendarioDia