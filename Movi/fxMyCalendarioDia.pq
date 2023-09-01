//fxMiCalendarioDia
let 
    fxMiCalendarioDia = (TablaReferencia as table, NombreColumnaInicial as text, NombreColumnaFinal as text) => let
    //Tabla inicial
        Source = try(Table.RemoveColumns(TablaReferencia,{"Año", "Mes"}))otherwise(TablaReferencia),
    //Columna de fecha inicial
        FechaMenor = NombreColumnaInicial,
    //Columna de fecha final
        FechaMayor= NombreColumnaFinal,
    //Se duplica la columna de fecha menor
        Duplicated_Inicial = Table.DuplicateColumn(Source, FechaMenor, "Fecha_Minima_Duplicada"),
    //Se obtiene la menor fecha como variable
        FechaInicial = List.Min(Duplicated_Inicial[Fecha_Minima_Duplicada]),
    //Se duplica la columna de fecha mayor
        Duplicated_Final = Table.DuplicateColumn(Duplicated_Inicial, FechaMayor, "Fecha_Maxima_Duplicada"),
    //Se obtiene la mayor fecha como variable
        FechaFinal = List.Max(Duplicated_Final[Fecha_Maxima_Duplicada]),
    //Se retoma desde el paso Duplicated_Final y se le agrega la fecha
        Added_Fecha = Table.AddColumn(Duplicated_Final, "Fecha", each if([Fecha_Minima_Duplicada]<[Fecha_Maxima_Duplicada])then({Number.From([Fecha_Minima_Duplicada])..Number.From([Fecha_Maxima_Duplicada])})else({Number.From([Fecha_Maxima_Duplicada])..Number.From([Fecha_Minima_Duplicada])})),
    //Se expande la fecha
        Expanded_Fecha = Table.ExpandListColumn(Added_Fecha, "Fecha"),
    //Se cambia al tipo de datos date la columna fecha
        Changed_Type_Fecha = Table.TransformColumnTypes(Expanded_Fecha,{{"Fecha", type date}}),
        Inserted_Year = Table.AddColumn(Changed_Type_Fecha, "Año", each Date.Year([Fecha]), Int64.Type),
        Inserted_Month = Table.AddColumn(Inserted_Year, "Mes", each Date.Month([Fecha]), Int64.Type),
    //Se quitan las fechas utilizadas como referencia
        Removed_Columns_Fechas = Table.RemoveColumns(Inserted_Month,{FechaMenor, FechaMayor, "Fecha_Minima_Duplicada", "Fecha_Maxima_Duplicada"})
    in
        Removed_Columns_Fechas
in
    fxMiCalendarioDia