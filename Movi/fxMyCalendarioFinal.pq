//fxMiCalendarioFinal
let
    fxFestivo =
    // Desarrollado por: Miguel Caballero & Fabian Torres: https://www.excelfreeblog.com/
// La página utiliza internamente la web: https://www.cuandoenelmundo.com/
let
    fxFestivo = let
    Funcion =
    ( 
        Pais as text, 
        optional Inicio as number, 
        optional Final as number
    ) as table =>
    let
        AnActual = Date.Year(DateTime.LocalNow()), 
        AnInicio = if Inicio = null then AnActual else Inicio, 
        AnFinal = if Inicio <> null and Final = null then Inicio else if Final = null then AnActual else Final, 
        pais = if Pais = "Puerto Rico" then "estados-unidos" else if Pais = "España" then "espana" else Pais, 
        #"Lista de Años" = Table.FromValue({AnInicio .. AnFinal}), 
        #"Años con Festivos en Tablas" = Table.AddColumn(#"Lista de Años", "Tablas Año", each FnDiasFestivos(Text.From([Value]))), 
        #"Expasión de Columnas Festivas" = Table.ExpandTableColumn(#"Años con Festivos en Tablas", "Tablas Año", {"Fecha", "Column3"}, {"Fecha", "Descripción"}), 
        #"Selección de Columnas Fecha y Descripción" = Table.SelectColumns(#"Expasión de Columnas Festivas", {"Fecha", "Descripción"}), 
        #"FINAL: Asginación de Tipo de Dato" = Table.TransformColumnTypes(#"Selección de Columnas Fecha y Descripción", {{"Fecha", type date}, {"Descripción", type text}}),
    // Función interna #1.
        FnDiasFestivos = (#"Año" as text) => let
            ObtenerMetaDatos = Web.Page(Web.Contents("https://www.cuandoenelmundo.com/calendario/", [RelativePath = RemoverTildes(Text.Replace(Text.Trim(Text.Lower(pais)), " ", "-")) & "/" & #"Año"])),
            SeleccionarFestivos = Table.SelectRows(ObtenerMetaDatos, each [ClassName] = "hdays"), 
            SeleccionarDatos = SeleccionarFestivos[Data], 
            CombinarFilasFestivas = Table.Combine({SeleccionarDatos{0}, SeleccionarDatos{1}}), 
            CrearColumnaDeFechasFestivas = Table.CombineColumns(CombinarFilasFestivas, {"Column1", "Column2"}, each _{0} & "/" & _{1} & "/" & #"Año", "Fecha"), 
            CambiarTipo = Table.TransformColumnTypes(CrearColumnaDeFechasFestivas, {{"Fecha", type date}}) 
        in
            CambiarTipo,
    // Función interna #2.
        RemoverTildes = (Texto as text) => let
            VocalesConAcentos = {"á", "é", "í", "ó", "ú"}, 
            VocalesSinAcentos = {"a", "e", "i", "o", "u"}, 
            PalabraSinAcentos = CicloDeSustitucion(Texto, 0), 
            CicloDeSustitucion = (Palabra as text, x as number) => if x > 4 then Palabra else let
                s0 = Text.Replace(Palabra, VocalesConAcentos{x}, VocalesSinAcentos{x})
            in
                @CicloDeSustitucion(s0, x+1) 
        in
            PalabraSinAcentos 
    in
        #"FINAL: Asginación de Tipo de Dato",

    Documentacion = type function(
        Pais as (type text meta[Documentation.AllowedValues =
            {
                "Argentina", 
                "Bolivia",
                "Brasil",
                "Chile",
                "Colombia",
                "Costa Rica",
                "Costa Rica",
                "Ecuador",
                "España",
                "El Salvador",
                "Guatemala",
                "Honduras",
                "México",
                "Nicaragua",
                "Panamá",
                "Paraguay",
                "Perú",
                "Puerto Rico",
                "República Dominicana",
                "Uruguay",
                "Venezuela"
            }]), 
        optional Inicio as number, 
        optional Final as number ) as list 
    meta[
        Documentation.Name = "Table.GenerateHoliDays", 
        Documentation.LongDescription = 
        "Esta función genera una tabla con los días feriados o festivos para un país de iberoamérica, dado y un rango de años determinado, sino no se proprociona año de incio se generan los festivos para el año actual, si sólo se proporciona el año de inicio entonces se deuelven sólo los días fetivos para el año de inicio. La tabla de resultado cuenta con dos columnas: fecha y descripción. Creado por: | EXCELFREEBLOG.COM | para POWERQUERY.ZONE, Miguel Caballero & Fabian Torres.", 
        Documentation.Examples = {
        //Ejemplo 1
            [Description = "Generar las fechas festivas para el país Colombia y año en curso ", 
            Code = "Table.GenerateHoliDays ( ""Colombia"" )", 
            Result = ""],
        //Ejemplo 2
            [Description = "Generar las fechas festivas para el país panamá y año 2017 ", 
            Code = "Table.GenerateHoliDays ( ""panamá"" , 2017 )", 
            Result = ""],
        //Ejemplo 3
            [Description = "Generar las fechas festivas para el país México y del ano 2016 al 2021 ", 
            Code = "Table.GenerateHoliDays ( ""México"" , 2016, 2021 )", 
            Result = ""], 
        //Ejemplo 4
            [Description = "Para más ejemplos, visita:", 
            Code = "POWERQUERY.ZONE/GENERAR-FESTIVOS",
            Result = ""]},
        Documentation.Category = "Table", 
        Documentation.Source = "Local", 
        Documentation.Version = "1.0", 
        Documentation.Author = "Miguel Caballero & Fabian Torres de: www.ExcelFreeBlog.Com"]
    in
        Value.ReplaceType(Funcion, Documentacion)
in
    fxFestivo, 
    fxMiCalendarioFinal = (TablaReferencia as table, NombreColumnaInicial as text, NombreColumnaFinal as text) => let
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
    //Se obtiene la tabla de festivos
        TBLFestivos = fxFestivo("Colombia", Date.Year(FechaInicial), Date.Year(FechaFinal)),
    //Se agrupa para obtener las fechas inicial y final en una tabla
        Grouped_Rows_Lim_Fechas = Table.Group(Duplicated_Final, {}, {{"Menor Fecha", each List.Min([Fecha_Minima_Duplicada]), type nullable date}, {"Mayor Fecha", each List.Max([Fecha_Maxima_Duplicada]), type nullable date}}),
    //Se saca la primera fecha del año para la fecha minima
        Calculated_Start_Year = Table.TransformColumns(Grouped_Rows_Lim_Fechas,{{"Menor Fecha", Date.StartOfYear, type date}}),
    //Se saca la ultima fecha del año para la fecha maxima
        Calculated_End_Year = Table.TransformColumns(Calculated_Start_Year,{{"Mayor Fecha", Date.EndOfYear, type date}}),
    //Se fecha la columna de fechas entre las fechas maxima y minima
        Added_Fechas_Lim = Table.AddColumn(Calculated_End_Year, "Fechas_Lim", each {Number.From([Menor Fecha])..Number.From([Mayor Fecha])}),
    //Se expande el listado
        Expanded_Fechas_Lim = Table.ExpandListColumn(Added_Fechas_Lim, "Fechas_Lim"),
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
    fxMiCalendarioFinal