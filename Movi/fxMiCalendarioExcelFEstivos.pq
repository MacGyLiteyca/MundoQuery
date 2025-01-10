//fxMiCalendarioExcelFEstivos
let
    fxMiCalendarioExcelFEstivos = (TablaReferencia as table, TablaFestivos as table, NombreColumnaInicial as text, NombreColumnaFinal as text) => let
    //Tabla inicial
        Source = try(Table.RemoveColumns(TablaReferencia,{"Año", "Mes"}))otherwise(TablaReferencia),
    //Columna de fecha inicial
        FechaMenor = NombreColumnaInicial,
    //Columna de fecha final
        FechaMayor= NombreColumnaFinal,
    //Se duplica la columna de fecha menor
        Duplicated_Inicial = Table.DuplicateColumn(Source, FechaMenor, "Fecha_Minima_Duplicada"),
    //Se duplica la columna de fecha mayor
        Duplicated_Final = Table.DuplicateColumn(Duplicated_Inicial, FechaMayor, "Fecha_Maxima_Duplicada"),
    // Se obtiene la menor fecha como variable
    FechaInicial = List.Min({List.Min(Duplicated_Final[Fecha_Minima_Duplicada]), List.Min(Duplicated_Final[Fecha_Maxima_Duplicada])}),
    //Se obtiene la mayor fecha como variable
        FechaFinal = List.Max({List.Max(Duplicated_Final[Fecha_Maxima_Duplicada]), List.Max(Duplicated_Final[Fecha_Minima_Duplicada])}),
    //Se obtiene la tabla de festivos
        TBLFestivos = TablaFestivos,
    //Se agrupa para obtener las fechas inicial y final en una tabla
        Grouped_Rows_Lim_Fechas = Table.Group(Duplicated_Final, {}, {{"Menor Fecha 1", each List.Min([Fecha_Minima_Duplicada]), type nullable date}, {"Mayor Fecha 1", each List.Max([Fecha_Maxima_Duplicada]), type nullable date}, {"Menor Fecha 2", each List.Min([Fecha_Maxima_Duplicada]), type nullable date}, {"Mayor Fecha 2", each List.Max([Fecha_Minima_Duplicada]), type nullable date}}),
    //Se Agrega la menor fecha entre las dos columnas de fecha
        Inserted_Earliest = Table.AddColumn(Grouped_Rows_Lim_Fechas, "Menor Fecha", each List.Min({[Menor Fecha 1], [Menor Fecha 2]}), type date),
    //Se Agrega la mayor fecha entre las dos columnas de fecha
        Inserted_Latest = Table.AddColumn(Inserted_Earliest, "Mayor Fecha", each List.Max({[Mayor Fecha 1], [Mayor Fecha 2]}), type date),
    //Se saca la primera fecha del año para la fecha minima
        Calculated_Start_Year = Table.TransformColumns(Inserted_Latest,{{"Menor Fecha", Date.StartOfMonth, type date}}),
    //Se saca la ultima fecha del año para la fecha maxima
        Calculated_End_Year = Table.TransformColumns(Calculated_Start_Year,{{"Mayor Fecha", Date.EndOfMonth, type date}}),
    //Se fecha la columna de fechas entre las fechas maxima y minima
        Added_Fechas_Lim = Table.AddColumn(Calculated_End_Year, "Fechas_Lim", each {Number.From([Menor Fecha])..Number.From([Mayor Fecha])}),
    //Se remueven las columnas que se agruparon        
        Removed_Columns = Table.RemoveColumns(Added_Fechas_Lim,{"Menor Fecha 1", "Mayor Fecha 1", "Menor Fecha 2", "Mayor Fecha 2"}),
    //Se expande el listado
        Expanded_Fechas_Lim = Table.ExpandListColumn(Removed_Columns, "Fechas_Lim"),
    //Se pasan los numeros a fechas
        Changed_Type_Fechas_Lim = Table.TransformColumnTypes(Expanded_Fechas_Lim,{{"Fechas_Lim", type date}}),
    //Se saca el año de cada fecha
        Inserted_Year = Table.AddColumn(Changed_Type_Fechas_Lim, "Año", each Date.Year([Fechas_Lim]), Int64.Type),
    //Se saca el mes de cada fecha
        Inserted_Month = Table.AddColumn(Inserted_Year, "Mes", each Date.Month([Fechas_Lim]), Int64.Type),
    //Se saca el nomnre del dia de cada fecha
        Inserted_Day_Name = Table.AddColumn(Inserted_Month, "Nombre del día", each Date.DayOfWeekName([Fechas_Lim]), type text),
    //Se realiza una combinacion con la tabla de festivos
        Merged_Festivos = Table.NestedJoin(Inserted_Day_Name, {"Fechas_Lim"}, TBLFestivos, {"Fecha"}, "Festivos_Invocados", JoinKind.LeftOuter),
    //Se expande la descripcion de los festivos
        Expanded_Festivos = Table.ExpandTableColumn(Merged_Festivos, "Festivos_Invocados", {"Descripción"}, {"Descripción"}),
    //Se agrega la columna de habil
        Added_Habil = Table.AddColumn(Expanded_Festivos, "Habil", each if [Nombre del día] = "domingo" then "Festivo" else if [Descripción] <> null then "Festivo" else "Habil", type text),
    //Se cuentan los festivos
        Added_Festivos = Table.AddColumn(Added_Habil, "Festivo", each if [Habil] = "Festivo" then 1 else 0, Int64.Type),
    //Se cuentan los habiles
        Added_Habiles = Table.AddColumn(Added_Festivos, "Habiles", each if [Habil] = "Habil" then 1 else 0, Int64.Type),
    //Se agrupa para totalizar los habiles y festivos
        Grouped_Rows = Table.Group(Added_Habiles, {"Año", "Mes"}, {{"Dias Mes", each Table.RowCount(_), Int64.Type}, {"Habiles", each List.Sum([Habiles]), type number}, {"Festivos", each List.Sum([Festivo]), type number}, {"All", each _, type table [Menor Fecha=date, Mayor Fecha=date, Fechas_Lim=nullable date, Año=number, Mes=number, Nombre del día=text, Descripción=nullable text, Habil=text, Festivo=number, Habiles=number]}}),
    //Se expande lo agrupado, esta es la tabla final con el calendario completo
        Expanded_All = Table.ExpandTableColumn(Grouped_Rows, "All", {"Fechas_Lim", "Nombre del día", "Descripción", "Habil"}, {"Fechas_Lim", "Nombre del día", "Descripción", "Habil"}),
    //Se retoma desde el paso Duplicated_Final y se le agrega la fecha
        Added_Fecha = Table.AddColumn(Duplicated_Final, "Fecha", each if([Fecha_Minima_Duplicada]<[Fecha_Maxima_Duplicada])then({Number.From([Fecha_Minima_Duplicada])..Number.From([Fecha_Maxima_Duplicada])})else({Number.From([Fecha_Maxima_Duplicada])..Number.From([Fecha_Minima_Duplicada])})),
    //Se expande la fecha
        Expanded_Fecha = Table.ExpandListColumn(Added_Fecha, "Fecha"),
    //Se cambia al tipo de datos date la columna fecha
        Changed_Type_Fecha = Table.TransformColumnTypes(Expanded_Fecha,{{"Fecha", type date}}),
    //Se combian con la tabla final del año ´por medio de la fecha
        Merged_Year_All = Table.NestedJoin(Changed_Type_Fecha, {"Fecha"}, Expanded_All, {"Fechas_Lim"}, "CalendarioFinal", JoinKind.LeftOuter),
    //Se expande el calendario
        Expanded_Year_All = Table.ExpandTableColumn(Merged_Year_All, "CalendarioFinal", {"Año", "Mes", "Dias Mes", "Habiles", "Festivos", "Nombre del día", "Descripción", "Habil"}, {"Año", "Mes", "Dias Mes", "Habiles", "Festivos", "Nombre del día", "Descripción", "Habil"}),
    //Se quitan las fechas utilizadas como referencia
        Removed_Columns_Fechas = Table.RemoveColumns(Expanded_Year_All,{FechaMenor, FechaMayor, "Fecha_Minima_Duplicada", "Fecha_Maxima_Duplicada"})
    in
        Removed_Columns_Fechas
in
    fxMiCalendarioExcelFEstivos