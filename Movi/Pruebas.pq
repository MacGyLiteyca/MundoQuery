[
ProduccionTecnicos = let
    Source = Folder.Files("C:\Users\MacLiteyca\OneDrive - liteyca.es\ProduccionTecnicos")
    in
        Source,
Mes_Actualizar = let
    Source = Excel.CurrentWorkbook(){[Name="Mes_Actualizar"]}[Content],
    Changed_Type = Table.TransformColumnTypes(Source,{{"Mes", Int64.Type}, {"Año", Int64.Type}})
    in
        Changed_Type,
fxMiCalendarioFinal= 
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
        fxMiCalendarioFinal,
fxMiCalendarioMes = let 
    fxMiCalendarioMes = (TablaReferencia as table, NombreColumnaInicial as text, NombreColumnaFinal as text) => let
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
        Removed_Columns_Fechas = Table.RemoveColumns(Inserted_Month,{FechaMenor, FechaMayor, "Fecha_Minima_Duplicada", "Fecha_Maxima_Duplicada", "Fecha"}),
        Removed_Duplicates = Table.Distinct(Removed_Columns_Fechas)
    in
        Removed_Duplicates
    in
        fxMiCalendarioMes,
fxMiCalendarioDia = let 
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
        fxMiCalendarioDia,
fxMiCalendarioDesconectada = let
    fxMiCalendarioDesconectada = (TablaReferencia as table, NombreColumnaInicial as text, NombreColumnaFinal as text, Tabla_Festivos as table) => let
        Source = TablaReferencia,
        FechaMenor = NombreColumnaInicial,
        FechaMayor= NombreColumnaFinal,
        Duplicated_Inicial = Table.DuplicateColumn(Source, FechaMenor, "FechaMin"),
        FechaInicial = List.Min(Duplicated_Inicial[FechaMin]),
        Duplicated_Final = Table.DuplicateColumn(Duplicated_Inicial, FechaMayor, "FechaMax"),
        FechaFinal = List.Max(Duplicated_Final[FechaMax]),
        TBLFestivos = Tabla_Festivos,
        Grouped_Rows_Lim_Fechas = Table.Group(Duplicated_Final, {}, {{"Menor Fecha", each List.Min([FechaMin]), type nullable date}, {"Mayor Fecha", each List.Max([FechaMax]), type nullable date}}),
        Calculated_Start_Year = Table.TransformColumns(Grouped_Rows_Lim_Fechas,{{"Menor Fecha", Date.StartOfYear, type date}}),
        Calculated_End_Year = Table.TransformColumns(Calculated_Start_Year,{{"Mayor Fecha", Date.EndOfYear, type date}}),
        Added_Fechas_Lim = Table.AddColumn(Calculated_End_Year, "Fechas_Lim", each {Number.From([Menor Fecha])..Number.From([Mayor Fecha])}),
        Expanded_Fechas_Lim = Table.ExpandListColumn(Added_Fechas_Lim, "Fechas_Lim"),
        Changed_Type_Fechas_Lim = Table.TransformColumnTypes(Expanded_Fechas_Lim,{{"Fechas_Lim", type date}}),
        Inserted_Year = Table.AddColumn(Changed_Type_Fechas_Lim, "Año", each Date.Year([Fechas_Lim]), Int64.Type),
        Inserted_Month = Table.AddColumn(Inserted_Year, "Mes", each Date.Month([Fechas_Lim]), Int64.Type),
        Inserted_Day_Name = Table.AddColumn(Inserted_Month, "Nombre del día", each Date.DayOfWeekName([Fechas_Lim]), type text),
        Merged_Festivos = Table.NestedJoin(Inserted_Day_Name, {"Fechas_Lim"}, TBLFestivos, {"Fecha"}, "Festivos_Invocados", JoinKind.LeftOuter),
        Expanded_Festivos = Table.ExpandTableColumn(Merged_Festivos, "Festivos_Invocados", {"Descripción"}, {"Descripción"}),
        Added_Habil = Table.AddColumn(Expanded_Festivos, "Habil", each if [Nombre del día] = "domingo" then "Festivo" else if [Descripción] <> null then "Festivo" else "Habil", type text),
        Added_Festivos = Table.AddColumn(Added_Habil, "Festivo", each if [Habil] = "Festivo" then 1 else 0, Int64.Type),
        Added_Habiles = Table.AddColumn(Added_Festivos, "Habiles", each if [Habil] = "Habil" then 1 else 0, Int64.Type),
        Grouped_Rows = Table.Group(Added_Habiles, {"Año", "Mes"}, {{"Dias Mes", each Table.RowCount(_), Int64.Type}, {"Habiles", each List.Sum([Habiles]), type number}, {"Festivos", each List.Sum([Festivo]), type number}, {"All", each _, type table [Menor Fecha=date, Mayor Fecha=date, Fechas_Lim=nullable date, Año=number, Mes=number, Nombre del día=text, Descripción=nullable text, Habil=text, Festivo=number, Habiles=number]}}),
        Expanded_All = Table.ExpandTableColumn(Grouped_Rows, "All", {"Fechas_Lim", "Nombre del día", "Descripción", "Habil"}, {"Fechas_Lim", "Nombre del día", "Descripción", "Habil"}),
        Added_Fecha = Table.AddColumn(Duplicated_Final, "Fecha", each if([FechaMin]<[FechaMax])then({Number.From([FechaMin])..Number.From([FechaMax])})else({Number.From([FechaMax])..Number.From([FechaMin])})),
        Expanded_Fecha = Table.ExpandListColumn(Added_Fecha, "Fecha"),
        Changed_Type_Fecha = Table.TransformColumnTypes(Expanded_Fecha,{{"Fecha", type date}}),
        Merged_Year_All = Table.NestedJoin(Changed_Type_Fecha, {"Fecha"}, Expanded_All, {"Fechas_Lim"}, "CalendarioFinal", JoinKind.LeftOuter),
        Expanded_Year_All = Table.ExpandTableColumn(Merged_Year_All, "CalendarioFinal", {"Año", "Mes", "Dias Mes", "Habiles", "Festivos", "Nombre del día", "Descripción", "Habil"}, {"Año", "Mes", "Dias Mes", "Habiles", "Festivos", "Nombre del día", "Descripción", "Habil"}),
        Removed_Columns_Fechas = Table.RemoveColumns(Expanded_Year_All,{FechaMenor, FechaMayor, "FechaMin", "FechaMax"})
    in
        Removed_Columns_Fechas
    in
        fxMiCalendarioDesconectada,
Tablas_Base = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each [Extension] = ".xlsx"),
    Filtered_Folder = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\VersionesBI\V12 Mac\")),
    Filtered_Name = Table.SelectRows(Filtered_Folder, each Text.StartsWith([Name], "Tablas Base")),
    Removed_Other_Columns = Table.SelectColumns(Filtered_Name,{"Content"}),
    Transform_Content = Table.TransformColumns(Removed_Other_Columns, {"Content", each Excel.Workbook(_)}),
    Expanded_Content = Table.ExpandTableColumn(Transform_Content, "Content", {"Name", "Data", "Item", "Kind", "Hidden"}, {"Name", "Data", "Item", "Kind", "Hidden"}),
    Filtered_Kind_Table = Table.SelectRows(Expanded_Content, each [Kind] = "Table")
    in
        Filtered_Kind_Table,
Tbl_Departamentos = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="TblDepartamentos"]}[Data],
    Trimmed_Departamento = Table.TransformColumns(Filtered_Rows,{{"Departamento", Text.Trim, type text}}),
    Cleaned_Departamento = Table.TransformColumns(Trimmed_Departamento,{{"Departamento", Text.Clean, type text}}),
    Capitalized_Departamento = Table.TransformColumns(Cleaned_Departamento,{{"Departamento", Text.Proper, type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Capitalized_Departamento, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Departamento = Table.SelectRows(Merged_Mes_Act, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Departamento,{"Mes_Actualizar"})
    in
        Removed_Column_Mes_Act,
AccesosCuadrillas_2 = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="AccesosCuadrillas_2"]}[Data],
    Trimmed_Text = Table.TransformColumns(Filtered_Rows,{{"Area Cuadri", Text.Trim, type text}, {"Nom Super", Text.Trim, type text}, {"Nom Gestor", Text.Trim, type text}, {"Nom Tec", Text.Trim, type text}, {"Contrata", Text.Trim, type text}, {"Departamento", Text.Trim, type text}, {"Cargo", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Area Cuadri", Text.Clean, type text}, {"Nom Super", Text.Clean, type text}, {"Nom Gestor", Text.Clean, type text}, {"Nom Tec", Text.Clean, type text}, {"Contrata", Text.Clean, type text}, {"Departamento", Text.Clean, type text}, {"Cargo", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Area Cuadri", Text.Proper, type text}, {"Nom Super", Text.Proper, type text}, {"Nom Gestor", Text.Proper, type text}, {"Nom Tec", Text.Proper, type text}, {"Contrata", Text.Proper, type text}, {"Departamento", Text.Proper, type text}, {"Cargo", Text.Proper, type text}}),
    Invoke_fxCalendario_Dia = fxMiCalendarioDia(Capitalized_Each_Word, "FechaMin", "FechaMax"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Dia, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Departamento = Table.SelectRows(Merged_Mes_Act, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Departamento,{"Mes_Actualizar"})
    in
        Removed_Column_Mes_Act,
Tbl_Bonos = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="TblBonos"]}[Data],
    Trimmed_Text = Table.TransformColumns(Filtered_Rows,{{"Cargo", Text.Trim, type text}, {"CuadrillaArea", Text.Trim, type text}, {"TipoCuadrilla", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Cargo", Text.Clean, type text}, {"CuadrillaArea", Text.Clean, type text}, {"TipoCuadrilla", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Cargo", Text.Proper, type text}, {"CuadrillaArea", Text.Proper, type text}, {"TipoCuadrilla", Text.Proper, type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Capitalized_Each_Word, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Cargo = Table.SelectRows(Merged_Mes_Act, each [Cargo] <> null and [Cargo] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Cargo,{"Mes_Actualizar"}),
    Added_Cargo_2 = Table.AddColumn(Removed_Column_Mes_Act, "Personalizado", each if [Cargo] = "Admin" then "Aux Tec" else if [Cargo] = "TECNICO" then "Aux Tec" else null, type text),
    Merged_Tbl_Bonos = Table.NestedJoin(Added_Cargo_2, {"Personalizado", "CuadrillaArea", "TipoCuadrilla", "Año", "Mes"}, Added_Cargo_2, {"Cargo", "CuadrillaArea", "TipoCuadrilla", "Año", "Mes"}, "Added Conditional Column", JoinKind.LeftOuter),
    Expanded_Tbl_Bonos = Table.ExpandTableColumn(Merged_Tbl_Bonos, "Added Conditional Column", {"Salario", "Max Porc Bono", "Parte Presta", "Parte Cuadri 2 Per"}, {"Aux.Salario", "Aux.Max Porc Bono", "Aux.Parte Presta", "Aux.Parte Cuadri 2 Per"})
    in
        Expanded_Tbl_Bonos,
Tbl_Meta_Mostrar = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="TblMetaMostrar"]}[Data],
    Trimmed_Text = Table.TransformColumns(Filtered_Rows,{{"Departamento", Text.Trim, type text}, {"CuadrillaArea", Text.Trim, type text}, {"Tipo", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Departamento", Text.Clean, type text}, {"CuadrillaArea", Text.Clean, type text}, {"Tipo", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Departamento", Text.Proper, type text}, {"CuadrillaArea", Text.Proper, type text}, {"Tipo", Text.Proper, type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Capitalized_Each_Word, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Departamento = Table.SelectRows(Merged_Mes_Act, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Departamento,{"Mes_Actualizar"})
    in
        Removed_Column_Mes_Act,
Hom_Area_Valor = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="HomAreaVal"]}[Data],
    Trimmed_Text = Table.TransformColumns(Filtered_Rows,{{"Area", Text.Trim, type text}, {"AreaHom", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Area", Text.Clean, type text}, {"AreaHom", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Area", Text.Proper, type text}, {"AreaHom", Text.Proper, type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Capitalized_Each_Word, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Area = Table.SelectRows(Merged_Mes_Act, each [Area] <> null and [Area] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Area,{"Mes_Actualizar"})
    in
        Removed_Column_Mes_Act,
Causales_Excluir_Reitero = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="CausalesExcluirReitero"]}[Data],
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Filtered_Rows, "Fecha Inicio", "Fecha Fin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Area = Table.SelectRows(Merged_Mes_Act, each [Acceso] <> null and [Acceso] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Area,{"Mes_Actualizar"})
    in
        Removed_Column_Mes_Act,
Tabla_Indicadores = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="TblFD"]}[Data],
    Trimmed_Text = Table.TransformColumns(Filtered_Rows,{{"Aperturas", Text.Trim, type text}, {"Productos", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Aperturas", Text.Clean, type text}, {"Productos", Text.Clean, type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Cleaned_Text, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Corto = Table.SelectRows(Merged_Mes_Act, each [Corto] <> null and [Corto] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Corto,{"Mes_Actualizar"})
    in
        Removed_Column_Mes_Act,
Parametro_Nota = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="ParametroNota"]}[Data],
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Filtered_Rows, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Removed_Column_Mes_Act = Table.RemoveColumns(Merged_Mes_Act,{"Mes_Actualizar"}),
    Removed_Duplicates = Table.Distinct(Removed_Column_Mes_Act)
    in
        Removed_Duplicates,
Tecnicos_Localidad = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="TecLocal"]}[Data],
    Changed_Type = Table.TransformColumnTypes(Filtered_Rows,{{"CEDULA", type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Changed_Type, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Removed_Column_Mes_Act = Table.RemoveColumns(Merged_Mes_Act,{"Mes_Actualizar"}),
    Removed_Duplicates = Table.Distinct(Removed_Column_Mes_Act),
    Added_Tipo_Tecnico = Table.AddColumn(Removed_Duplicates, "Tipo Tecnico", each "Localidad", type text)
    in
        Added_Tipo_Tecnico,
Valor_Materiales = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="ValMatLog"]}[Data],
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Filtered_Rows, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Removed_Column_Mes_Act = Table.RemoveColumns(Merged_Mes_Act,{"Mes_Actualizar"}),
    Grouped_Rows = Table.Group(Removed_Column_Mes_Act, {"codigo_material", "descriocion_material", "Año", "Mes"}, {{"Valor", each List.Average([VALOR]), type nullable number}}),
    Removed_Duplicates = Table.Distinct(Grouped_Rows)
    in
        Removed_Duplicates,
Tiempos = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="TiemLog"]}[Data],
    Trimmed_Text = Table.TransformColumns(Filtered_Rows,{{"Tipo Tecnico", Text.Trim, type text}, {"Tipo", Text.Trim, type text}, {"Lapso", Text.Trim, type text}, {"Rango", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Tipo Tecnico", Text.Clean, type text}, {"Tipo", Text.Clean, type text}, {"Lapso", Text.Clean, type text}, {"Rango", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Tipo Tecnico", Text.Proper, type text}, {"Tipo", Text.Proper, type text}, {"Lapso", Text.Proper, type text}, {"Rango", Text.Proper, type text}}),
    Added_Dias = Table.AddColumn(Capitalized_Each_Word, "Días", each try List.Numbers([Días menor],1+[Días Mayor]-[Días menor]) otherwise List.Numbers([Días menor],1000)),
    Expanded_Dias = Table.ExpandListColumn(Added_Dias, "Días"),
    Changed_Type = Table.TransformColumnTypes(Expanded_Dias,{{"Días", type number}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Changed_Type, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Removed_Column_Mes_Act = Table.RemoveColumns(Merged_Mes_Act,{"Mes_Actualizar", "Días Mayor", "Días menor"}),
    Removed_Duplicates = Table.Distinct(Removed_Column_Mes_Act)
    in
        Removed_Duplicates,
Limites_Rangos_Tesa = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="Limites_Rangos_Tesa"]}[Data],
    Trimmed = Table.TransformColumns(Filtered_Rows,{{"Area", Text.Trim, type text}}),
    Cleaned = Table.TransformColumns(Trimmed,{{"Area", Text.Clean, type text}}),
    Capitalized = Table.TransformColumns(Cleaned,{{"Area", Text.Proper, type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Capitalized, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Area = Table.SelectRows(Merged_Mes_Act, each [Area] <> null and [Area] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Area,{"Mes_Actualizar"})
    in
        Removed_Column_Mes_Act,
Produccion_Altas = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".xlsb")),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\DatasProduccion\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], " ", "_", 2, 0), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", " "), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Excel.Workbook(_)}),
    Expanded_Content = Table.ExpandTableColumn(Transform_Content, "Content", {"Name", "Data"}, {"Content.Name", "Content.Data"}),
    Expanded_Produccion = Expanded_Content{[Content.Name="Produccion"]}[Content.Data],
    Promoted_Headers = Table.PromoteHeaders(Expanded_Produccion, [PromoteAllScalars=true]),
    Filtered_Null_Fecha = Table.SelectRows(Promoted_Headers, each [Fecha de cierre] <> null and [Fecha de cierre] <> ""),
    Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha de cierre", each try(Date.From(Value.FromText(Text.Start(_, 10))))otherwise(Date.From(Value.FromText(_))), type date}}),
    Removed_Other_Columns = Table.SelectColumns(Transform_Fecha,{"id_actuacion", "pedido_atis", "Tipo Actuacion", "Tipo Tarea", "Departamento", "Num Empleado", "Fecha de cierre", "TIPO DE RED", "TOTAL BAREMOS"}),
    Changed_Type = Table.TransformColumnTypes(Removed_Other_Columns,{{"id_actuacion", type text}, {"pedido_atis", type text}, {"Tipo Actuacion", type text}, {"Tipo Tarea", type text}, {"Departamento", type text}, {"Num Empleado", type text}, {"Fecha de cierre", type date}, {"TIPO DE RED", type text}, {"TOTAL BAREMOS", type number}}),
    Trimmed_Text = Table.TransformColumns(Changed_Type,{{"Tipo Tarea", Text.Trim, type text}, {"Departamento", Text.Trim, type text}, {"TIPO DE RED", Text.Trim, type text}, {"Tipo Actuacion", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Tipo Tarea", Text.Clean, type text}, {"Departamento", Text.Clean, type text}, {"TIPO DE RED", Text.Clean, type text}, {"Tipo Actuacion", Text.Clean, type text}}),
    Capitalized_Departamento = Table.TransformColumns(Cleaned_Text,{{"Departamento", Text.Proper, type text}}),
    Renamed_Columns = Table.RenameColumns(Capitalized_Departamento,{{"pedido_atis", "Atis"}, {"id_actuacion", "Atiempo"}, {"Num Empleado", "CC Tec"}, {"Fecha de cierre", "Fecha"}, {"Tipo Actuacion", "Tipo Orden"}, {"TOTAL BAREMOS", "Baremos"}, {"TIPO DE RED", "Medio de Acceso"}}),
    Filtered_Null_Atis = Table.SelectRows(Renamed_Columns, each [Atis] <> null and [Atis] <> ""),
    Filtered_Null_CC_Tec = Table.SelectRows(Filtered_Null_Atis, each [CC Tec] <> null and [CC Tec] <> ""),
    Added_Area_Cuadri = Table.AddColumn(Filtered_Null_CC_Tec, "AreaCuadri", each "Instalaciones", type text),
    Merged_Tbl_Departamentos = Table.NestedJoin(Added_Area_Cuadri, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
    Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
    Removed_Duplicates = Table.Distinct(Removed_Columns)
    in
        Removed_Duplicates,
Produccion_Mantenimiento = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".xlsb")),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\DatasProduccionMantenimiento\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], " ", "_", 2, 0), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", " "), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Excel.Workbook(_)}),
    Expanded_Content = Table.ExpandTableColumn(Transform_Content, "Content", {"Name", "Data"}, {"Content.Name", "Content.Data"}),
    Expanded_Base = Expanded_Content{[Content.Name="BASE"]}[Content.Data],
    Promoted_Headers = Table.PromoteHeaders(Expanded_Base, [PromoteAllScalars=true]),
    Filtered_Null_Fecha = Table.SelectRows(Promoted_Headers, each [Fecha_de_cierre_final] <> null and [Fecha_de_cierre_final] <> ""),
    Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha_de_cierre_final", each try(Date.From(Value.FromText(Text.Start(_, 10))))otherwise(Date.From(Value.FromText(_))), type date}}),
    Removed_Other_Columns = Table.SelectColumns(Transform_Fecha,{"Tipo_de_orden", "Subtipo_de_orden", "Pet_atis", "Identificador_PC_Linea", "Departamento", "external_id", "Fecha_de_cierre_final"}),
    Changed_Type = Table.TransformColumnTypes(Removed_Other_Columns,{{"Tipo_de_orden", type text}, {"Subtipo_de_orden", type text}, {"Pet_atis", type text}, {"Identificador_PC_Linea", type text}, {"Departamento", type text}, {"external_id", type text}, {"Fecha_de_cierre_final", type date}}),
    Trimmed_Text = Table.TransformColumns(Changed_Type,{{"Tipo_de_orden", Text.Trim, type text}, {"Subtipo_de_orden", Text.Trim, type text}, {"Departamento", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Tipo_de_orden", Text.Clean, type text}, {"Subtipo_de_orden", Text.Clean, type text}, {"Departamento", Text.Clean, type text}}),
    Capitalized_Departamento = Table.TransformColumns(Cleaned_Text,{{"Departamento", Text.Proper, type text}}),
    Renamed_Columns = Table.RenameColumns(Capitalized_Departamento,{{"Pet_atis", "Atis"}, {"Identificador_PC_Linea", "Atiempo"}, {"Tipo_de_orden", "Tipo Orden"}, {"external_id", "CC Tec"}, {"Fecha_de_cierre_final", "Fecha"}, {"Subtipo_de_orden", "Tipo Tarea"}}),
    Filtered_Null_Atis = Table.SelectRows(Renamed_Columns, each [Atis] <> null and [Atis] <> ""),
    Filtered_Null_CC_Tec = Table.SelectRows(Filtered_Null_Atis, each [CC Tec] <> null and [CC Tec] <> ""),
    Added_Area_Cuadri = Table.AddColumn(Filtered_Null_CC_Tec, "AreaCuadri", each "Mantenimiento", type text),
    Merged_Tbl_Departamentos = Table.NestedJoin(Added_Area_Cuadri, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
    Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
    Removed_Duplicates = Table.Distinct(Removed_Columns),
    Added_Actividades = Table.AddColumn(Removed_Duplicates, "Actividades", each 1, type number)
    in
        Added_Actividades,
Consolidado_Cuadrillas = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".xlsb")),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\DatasProduccion\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], " ", "_", 2, 0), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", " "), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Excel.Workbook(_)}),
    Expanded_Content = Table.ExpandTableColumn(Transform_Content, "Content", {"Name", "Data"}, {"Content.Name", "Content.Data"}),
    Expanded_Cuadrillas = Expanded_Content{[Content.Name="Cuadrillas"]}[Content.Data],
    Promoted_Headers = Table.PromoteHeaders(Expanded_Cuadrillas, [PromoteAllScalars=true]),
    Filtered_Null_Fecha = Table.SelectRows(Promoted_Headers, each [Fecha Inicial] <> null and [Fecha Inicial] <> ""),
    Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha Inicial", each Date.From(Value.FromText(_)), type date}, {"Fecha Final", each Date.From(Value.FromText(_)), type date}}),
    Removed_Other_Columns = Table.SelectColumns(Transform_Fecha,{"EMPRESA", "DEPARTAMENTO", "AREA", "AREA DE COBERTURA", "CEDULA TECNICO", "NOMBRE TECNICO", "TIPO CUADRILLA", "ID RECURSO TOA", "CEDULA AUXILIAR", "NOMBRE AUXILIAR", "PROYECTO", "HABILIDAD", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "CEDULA LIDER ", "LIDER DE GESTION", "CEDULA PROFESIONAL", "PROFESIONAL", "Fecha Inicial", "Fecha Final"}),
    Changed_Type = Table.TransformColumnTypes(Removed_Other_Columns,{{"EMPRESA", type text}, {"DEPARTAMENTO", type text}, {"AREA", type text}, {"AREA DE COBERTURA", type text}, {"CEDULA TECNICO", type text}, {"NOMBRE TECNICO", type text}, {"TIPO CUADRILLA", type text}, {"ID RECURSO TOA", type text}, {"CEDULA AUXILIAR", type text}, {"NOMBRE AUXILIAR", type text}, {"PROYECTO", type text}, {"HABILIDAD", type text}, {"CEDULA AUX GESTION", type text}, {"AUXILIAR DE GESTION", type text}, {"CEDULA SUPERVISOR", type text}, {"SUPERVISOR", type text}, {"CEDULA LIDER ", type text}, {"LIDER DE GESTION", type text}, {"CEDULA PROFESIONAL", type text}, {"PROFESIONAL", type text}, {"Fecha Inicial", type date}, {"Fecha Final", type date}}),
    Replaced_To_Null_1 = Table.ReplaceValue(Changed_Type,"NO TIENE",null,Replacer.ReplaceValue,{"EMPRESA", "DEPARTAMENTO", "AREA", "AREA DE COBERTURA", "CEDULA TECNICO", "NOMBRE TECNICO", "CEDULA AUXILIAR", "NOMBRE AUXILIAR", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "CEDULA LIDER ", "LIDER DE GESTION", "CEDULA PROFESIONAL", "PROFESIONAL"}),
    Replaced_To_Null_2 = Table.ReplaceValue(Replaced_To_Null_1,"0",null,Replacer.ReplaceValue,{"EMPRESA", "DEPARTAMENTO", "AREA", "AREA DE COBERTURA", "CEDULA TECNICO", "NOMBRE TECNICO", "CEDULA AUXILIAR", "NOMBRE AUXILIAR", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "CEDULA LIDER ", "LIDER DE GESTION", "CEDULA PROFESIONAL", "PROFESIONAL"}),
    Replaced_To_Null_3 = Table.ReplaceValue(Replaced_To_Null_2,"NA",null,Replacer.ReplaceValue,{"EMPRESA", "DEPARTAMENTO", "AREA", "AREA DE COBERTURA", "CEDULA TECNICO", "NOMBRE TECNICO", "CEDULA AUXILIAR", "NOMBRE AUXILIAR", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "CEDULA LIDER ", "LIDER DE GESTION", "CEDULA PROFESIONAL", "PROFESIONAL"}),
    Replaced_To_Null_4 = Table.ReplaceValue(Replaced_To_Null_3,"",null,Replacer.ReplaceValue,{"EMPRESA", "DEPARTAMENTO", "AREA", "AREA DE COBERTURA", "CEDULA TECNICO", "NOMBRE TECNICO", "CEDULA AUXILIAR", "NOMBRE AUXILIAR", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "CEDULA LIDER ", "LIDER DE GESTION", "CEDULA PROFESIONAL", "PROFESIONAL"}),
    Replaced_To_Null_5 = Table.ReplaceValue(Replaced_To_Null_4,"NO APLICA",null,Replacer.ReplaceValue,{"EMPRESA", "DEPARTAMENTO", "AREA", "AREA DE COBERTURA", "CEDULA TECNICO", "NOMBRE TECNICO", "CEDULA AUXILIAR", "NOMBRE AUXILIAR", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "CEDULA LIDER ", "LIDER DE GESTION", "CEDULA PROFESIONAL", "PROFESIONAL"}),
    Replaced_Null_Name_Liteyca = Table.ReplaceValue(Replaced_To_Null_5,null,"Liteyca",Replacer.ReplaceValue,{"NOMBRE TECNICO", "AUXILIAR DE GESTION", "SUPERVISOR", "LIDER DE GESTION", "PROFESIONAL"}),
    Trimmed_Text = Table.TransformColumns(Replaced_Null_Name_Liteyca,{{"EMPRESA", Text.Trim, type text}, {"DEPARTAMENTO", Text.Trim, type text}, {"AREA", Text.Trim, type text}, {"AREA DE COBERTURA", Text.Trim, type text}, {"NOMBRE TECNICO", Text.Trim, type text}, {"TIPO CUADRILLA", Text.Trim, type text}, {"NOMBRE AUXILIAR", Text.Trim, type text}, {"PROYECTO", Text.Trim, type text}, {"HABILIDAD", Text.Trim, type text}, {"AUXILIAR DE GESTION", Text.Trim, type text}, {"SUPERVISOR", Text.Trim, type text}, {"LIDER DE GESTION", Text.Trim, type text}, {"PROFESIONAL", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"EMPRESA", Text.Clean, type text}, {"DEPARTAMENTO", Text.Clean, type text}, {"AREA", Text.Clean, type text}, {"AREA DE COBERTURA", Text.Clean, type text}, {"NOMBRE TECNICO", Text.Clean, type text}, {"TIPO CUADRILLA", Text.Clean, type text}, {"NOMBRE AUXILIAR", Text.Clean, type text}, {"PROYECTO", Text.Clean, type text}, {"HABILIDAD", Text.Clean, type text}, {"AUXILIAR DE GESTION", Text.Clean, type text}, {"SUPERVISOR", Text.Clean, type text}, {"LIDER DE GESTION", Text.Clean, type text}, {"PROFESIONAL", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"EMPRESA", Text.Proper, type text}, {"DEPARTAMENTO", Text.Proper, type text}, {"AREA", Text.Proper, type text}, {"AREA DE COBERTURA", Text.Proper, type text}, {"NOMBRE TECNICO", Text.Proper, type text}, {"TIPO CUADRILLA", Text.Proper, type text}, {"NOMBRE AUXILIAR", Text.Proper, type text}, {"PROYECTO", Text.Proper, type text}, {"HABILIDAD", Text.Proper, type text}, {"AUXILIAR DE GESTION", Text.Proper, type text}, {"SUPERVISOR", Text.Proper, type text}, {"LIDER DE GESTION", Text.Proper, type text}, {"PROFESIONAL", Text.Proper, type text}}),
    Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"EMPRESA", "Contrata"}, {"DEPARTAMENTO", "Dep Cuadri"}, {"AREA", "AreaCuadri"}, {"CEDULA TECNICO", "CC Tec"}, {"NOMBRE TECNICO", "Nom Tec"}, {"AREA DE COBERTURA", "Cobertura"}, {"TIPO CUADRILLA", "Tipo Cuadrilla"}, {"ID RECURSO TOA", "Id TOA"}, {"CEDULA AUXILIAR", "CC Aux"}, {"NOMBRE AUXILIAR", "Nom Aux"}, {"PROYECTO", "Proyecto"}, {"HABILIDAD", "Habilidad"}, {"CEDULA AUX GESTION", "CC Gestor"}, {"AUXILIAR DE GESTION", "Nom Gestor"}, {"CEDULA SUPERVISOR", "CC Super"}, {"SUPERVISOR", "Nom Super"}, {"CEDULA LIDER ", "CC Lider"}, {"LIDER DE GESTION", "Nom Lider"}, {"CEDULA PROFESIONAL", "CC Profesional"}, {"PROFESIONAL", "Nom Profesional"}}),
    Filtered_Null_CC_Tec = Table.SelectRows(Renamed_Columns, each [CC Tec] <> null and [CC Tec] <> ""),
    Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_CC_Tec, {"Dep Cuadri"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
    Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Dep Cuadri] <> null and [Dep Cuadri] <> ""),
    Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
    Removed_Duplicates = Table.Distinct(Removed_Columns)
    in
        Removed_Duplicates,
Personal_Sin_Cuadrillas = let
    My_Conformacion_Cuadrillas = Table.SelectColumns(Consolidado_Cuadrillas,{"Contrata", "Dep Cuadri", "AreaCuadri", "CC Tec", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Fecha Inicial", "Fecha Final", "Nom Aux", "CC Aux"}),
    Cuadrillas_Completas = fxMiCalendarioDia(My_Conformacion_Cuadrillas, "Fecha Inicial", "Fecha Final"),
    Consolidado_Produccion = Table.Combine({Produccion_Altas, Produccion_Mantenimiento}),
    Removed_Other_Columns = Table.SelectColumns(Consolidado_Produccion,{"Departamento", "CC Tec", "Fecha", "Baremos", "AreaCuadri", "Actividades"}),
    Replaced_Null_Bar_Act = Table.ReplaceValue(Removed_Other_Columns,null,0,Replacer.ReplaceValue,{"Baremos", "Actividades"}),
    Grouped_Rows_Produccion = Table.Group(Replaced_Null_Bar_Act, {"Departamento", "CC Tec", "Fecha"}, {{"Bar", each List.Sum([Baremos]), type nullable number}, {"Act", each List.Sum([Actividades]), type nullable number}}),
    Added_AreaCuadri = Table.AddColumn(Grouped_Rows_Produccion, "AreaCuadri", each if [Bar] >= [Act] then "INSTALACIONES" else "MANTENIMIENTO", type text),
    Merged_Cuadrillas = Table.NestedJoin(Added_AreaCuadri, {"Departamento", "CC Tec", "Fecha"}, Cuadrillas_Completas, {"Dep Cuadri", "CC Tec", "Fecha"}, "ConsolidadoCuadrillas", JoinKind.LeftAnti),
    Expanded_Cuadrillas = Table.ExpandTableColumn(Merged_Cuadrillas, "ConsolidadoCuadrillas", {"Contrata", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Nom Aux", "CC Aux"}, {"Contrata", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Nom Aux", "CC Aux"}),
    Replaced_Null_1 = Table.ReplaceValue(Expanded_Cuadrillas,null,"Liteyca",Replacer.ReplaceValue,{"Contrata", "Nom Tec", "Nom Gestor", "Nom Super", "Nom Aux"}),
    Replaced_Null_Tipo_Cuadrilla = Table.ReplaceValue(Replaced_Null_1,null,"M1",Replacer.ReplaceValue,{"Tipo Cuadrilla"}),
    Grouped_Rows = Table.Group(Replaced_Null_Tipo_Cuadrilla, {"Departamento", "CC Tec"}, {{"Fecha Inicial", each List.Min([Fecha]), type nullable date}, {"Fecha Final", each List.Max([Fecha]), type nullable date}, {"All", each _, type table [Departamento=text, CC Tec=nullable text, Fecha=nullable date, Bar=nullable number, Act=nullable number, AreaCuadri=text, Contrata=nullable text, Nom Tec=nullable text, Tipo Cuadrilla=nullable text, CC Gestor=nullable text, Nom Gestor=nullable text, CC Super=nullable text, Nom Super=nullable text, Nom Aux=nullable text, CC Aux=nullable text]}}),
    Expanded_All = Table.ExpandTableColumn(Grouped_Rows, "All", {"AreaCuadri", "Contrata", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Nom Aux", "CC Aux"}, {"AreaCuadri", "Contrata", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Nom Aux", "CC Aux"}),
    Renamed_Dep = Table.RenameColumns(Expanded_All,{{"Departamento", "Dep Cuadri"}}),
    Removed_Duplicates = Table.Distinct(Renamed_Dep)
    in
        Removed_Duplicates,
Cuadrillas = let
    Source = Consolidado_Cuadrillas,
    Removed_Other_Columns = Table.SelectColumns(Source,{"Contrata", "Dep Cuadri", "AreaCuadri", "CC Tec", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Fecha Inicial", "Fecha Final", "Nom Aux", "CC Aux"}),
    Appended_Personal_Sin_Cuadrillas = Table.Combine({Removed_Other_Columns, Personal_Sin_Cuadrillas}),
    fxMyCalendario = fxMiCalendarioFinal(Appended_Personal_Sin_Cuadrillas, "Fecha Inicial", "Fecha Final"),
    Added_Tipo_Empresa = Table.AddColumn(fxMyCalendario, "Tipo Empresa", each if [Contrata] = "Liteyca" then "Propio" else "Contratista", type text),
    Merged_Acceso_Cuadrillas = Table.NestedJoin(Added_Tipo_Empresa, {"CC Tec", "Dep Cuadri", "Fecha"}, AccesosCuadrillas_2, {"CCTec", "Departamento", "Fecha"}, "AccesosCuadrillas_2", JoinKind.LeftOuter),
    Expanded_Acceso_Cuadrillas = Table.ExpandTableColumn(Merged_Acceso_Cuadrillas, "AccesosCuadrillas_2", {"Acceso", "Cargo", "ApuCuadrilla"}, {"Acceso", "Cargo", "ApuCuadrilla"}),
    Replaced_Cargo = Table.ReplaceValue(Expanded_Acceso_Cuadrillas,null,"Admin",Replacer.ReplaceValue,{"Cargo"}),
    Replaced_Acceso = Table.ReplaceValue(Replaced_Cargo,null,"9999999999",Replacer.ReplaceValue,{"Acceso"}),
    Replaced_Apu_Cuadrilla = Table.ReplaceValue(Replaced_Acceso,null,0,Replacer.ReplaceValue,{"ApuCuadrilla"}),
    Merged_Tbl_Bonos = Table.NestedJoin(Replaced_Apu_Cuadrilla, {"Cargo", "AreaCuadri", "Tipo Cuadrilla", "Año", "Mes"}, Tbl_Bonos, {"Cargo", "CuadrillaArea", "TipoCuadrilla", "Año", "Mes"}, "TblBonos", JoinKind.LeftOuter),
    Expanded_Tbl_Bonos = Table.ExpandTableColumn(Merged_Tbl_Bonos, "TblBonos", {"BonoCuadrilla", "IncrementoBono", "MetaMes", "Salario", "Max Porc Bono", "Parte Presta", "Parte Cuadri 2 Per", "Aux.Salario", "Aux.Max Porc Bono", "Aux.Parte Presta", "Aux.Parte Cuadri 2 Per"}, {"BonoCuadrilla", "IncrementoBono", "MetaMes", "Salario", "Max Porc Bono", "Parte Presta", "Parte Cuadri 2 Per", "Aux.Salario", "Aux.Max Porc Bono", "Aux.Parte Presta", "Aux.Parte Cuadri 2 Per"}),
    Merged_Meta_Mostrar = Table.NestedJoin(Expanded_Tbl_Bonos, {"Dep Cuadri", "AreaCuadri", "Tipo Cuadrilla", "Año", "Mes"}, Tbl_Meta_Mostrar, {"Departamento", "CuadrillaArea", "Tipo", "Año", "Mes"}, "TblMetaMostrar", JoinKind.LeftOuter),
    Expanded_Meta_Mostrar = Table.ExpandTableColumn(Merged_Meta_Mostrar, "TblMetaMostrar", {"MetaMostrar"}, {"Pre.MetaMostrar"}),
    Filtered_Null_Fecha = Table.SelectRows(Expanded_Meta_Mostrar , each [Fecha] <> null and [Fecha] <> "")
    in
        Filtered_Null_Fecha,
Cant_Producion_Dia = let
    Source = Table.Combine({Produccion_Altas, Produccion_Mantenimiento}),
    Grouped_Rows = Table.Group(Source, {"CC Tec", "Fecha"}, {{"Recuento", each Table.RowCount(_), Int64.Type}}),
    Added_Dia_Trabajado = Table.AddColumn(Grouped_Rows, "DiaTrabajado", each 1/[Recuento], type number)
    in
        Added_Dia_Trabajado,
Cuadrillas_Sin_Produccion = let
    My_Produccion = Table.Combine({Produccion_Altas, Produccion_Mantenimiento}),
    Source = let
        Source = Consolidado_Cuadrillas,
        Removed_Other_Columns = Table.SelectColumns(Source,{"Contrata", "Dep Cuadri", "AreaCuadri", "CC Tec", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Fecha Inicial", "Fecha Final", "Nom Aux", "CC Aux"}),
        Appended_Query = Table.Combine({Removed_Other_Columns, Personal_Sin_Cuadrillas}),
        fxMyCalendario = fxMiCalendarioDia(Appended_Query, "Fecha Inicial", "Fecha Final"),
        Removed_Duplicates = Table.Distinct(fxMyCalendario)
    in
        Removed_Duplicates,
    Selected_Columns = Table.SelectColumns(Source,{"Dep Cuadri", "CC Tec", "Fecha"}),
    Merged_Produccion = Table.NestedJoin(Selected_Columns, {"Dep Cuadri", "CC Tec", "Fecha"}, My_Produccion, {"Departamento", "CC Tec", "Fecha"}, "Produccion", JoinKind.LeftAnti),
    Expanded_Produccion = Table.ExpandTableColumn(Merged_Produccion, "Produccion", {"Atiempo", "Atis", "Tipo Orden", "Tipo Tarea", "Medio de Acceso", "Baremos", "AreaCuadri", "Actividades"}, {"Atiempo", "Atis", "Tipo Orden", "Tipo Tarea", "Medio de Acceso", "Baremos", "AreaCuadri", "Actividades"}),
    Filtered_Null_Dep = Table.SelectRows(Expanded_Produccion, each [Dep Cuadri] <> null and [Dep Cuadri] <> ""),
    Renamed_Departamento = Table.RenameColumns(Filtered_Null_Dep,{{"Dep Cuadri", "Departamento"}}),
    Replaced_Null_Bar_Act = Table.ReplaceValue(Renamed_Departamento,null,0,Replacer.ReplaceValue,{"Baremos", "Actividades"}),
    Added_Recuento = Table.AddColumn(Replaced_Null_Bar_Act, "Recuento", each 1, Int64.Type),
    Added_Dia_Trabajado = Table.AddColumn(Added_Recuento, "DiaTrabajado", each 1, type number),
    Removed_Duplicates = Table.Distinct(Added_Dia_Trabajado)
    in
        Removed_Duplicates,
Produccion = let
    Source = Table.Combine({Produccion_Altas, Produccion_Mantenimiento}),
    Filtered_Null_Dep = Table.SelectRows(Source, each [Departamento] <> null and [Departamento] <> ""),
    Replaced_Null_Bar_Act = Table.ReplaceValue(Filtered_Null_Dep,null,0,Replacer.ReplaceValue,{"Baremos", "Actividades"}),
    Merged_Cant_Por_Dia = Table.NestedJoin(Replaced_Null_Bar_Act, {"CC Tec", "Fecha"}, Cant_Producion_Dia, {"CC Tec", "Fecha"}, "CantProducionDia", JoinKind.LeftOuter),
    Expanded_Recuento = Table.ExpandTableColumn(Merged_Cant_Por_Dia, "CantProducionDia", {"Recuento", "DiaTrabajado"}, {"Recuento", "DiaTrabajado"}),
    Appended_Cuadrillas_Sin_Produccion = Table.Combine({Expanded_Recuento, Cuadrillas_Sin_Produccion})
    in
        Appended_Cuadrillas_Sin_Produccion,
Infancias_Calidad = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each [Extension] = ".txt"),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\Infancia\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], "_", ".", 1, 0), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", "_"), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Csv.Document(_,[Delimiter="Õ", Columns=43, Encoding=1252, QuoteStyle=QuoteStyle.None])}),
    Expanded_Content = Transform_Content{0}[Content],
    Filtered_Separador = Table.SelectRows(Expanded_Content, each not Text.Contains([Column1], "-")),
    Filtered_Null_Column2 = Table.SelectRows(Filtered_Separador, each [Column2] <> null and [Column2] <> ""),
    Promoted_Headers = Table.PromoteHeaders(Filtered_Null_Column2, [PromoteAllScalars=true]),
    Renamed_Actuacion_Alta = try(Table.RenameColumns(Promoted_Headers,{{"XA_ACTUACION ALTA", "XA_ACTUACION_ALTA"}}))otherwise(Promoted_Headers),
    Renamed_Atis_Alta = try(Table.RenameColumns(Renamed_Actuacion_Alta,{{"Pet atis ALTA", "Pet_atis_ALTA"}}))otherwise(Renamed_Actuacion_Alta),
    Renamed_Medio_Alta = try(Table.RenameColumns(Renamed_Atis_Alta,{{"Medio de Acceso ALTA", "Medio_de_Acceso_ALTA"}}))otherwise(Renamed_Atis_Alta),
    Renamed_Fecha_Final_Alta = try(Table.RenameColumns(Renamed_Medio_Alta,{{"Fecha de cierre final ALTA", "Fecha_de_cierre_final_ALTA"}}))otherwise(Renamed_Medio_Alta),
    Filtered_Null_Fecha = Table.SelectRows(Renamed_Fecha_Final_Alta, each [Fecha_de_cierre_final_ALTA] <> null and [Fecha_de_cierre_final_ALTA] <> ""),
    Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha_de_cierre_final_ALTA", each Date.From(Value.FromText(_)), type date}}),
    Removed_Other_Columns = Table.SelectColumns(Transform_Fecha,{"Pet_atis_ALTA", "CIERRE_AV", "APERTURA_AV"}),
    Replaced_NULL_Null = Table.ReplaceValue(Removed_Other_Columns,"NULL",null,Replacer.ReplaceValue,{"Pet_atis_ALTA", "CIERRE_AV", "APERTURA_AV"}),
    Changed_Type = Table.TransformColumnTypes(Replaced_NULL_Null,{{"Pet_atis_ALTA", type text}, {"CIERRE_AV", type text}, {"APERTURA_AV", type text}}),
    Trimmed_Text = Table.TransformColumns(Changed_Type,{{"Pet_atis_ALTA", Text.Trim, type text}, {"CIERRE_AV", Text.Trim, type text}, {"APERTURA_AV", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Pet_atis_ALTA", Text.Clean, type text}, {"CIERRE_AV", Text.Clean, type text}, {"APERTURA_AV", Text.Clean, type text}}),
    Renamed_Columns = Table.RenameColumns(Cleaned_Text,{{"Pet_atis_ALTA", "Pet_atis"}}),
    Filtered_Null_Atis = Table.SelectRows(Renamed_Columns, each [Pet_atis] <> null and [Pet_atis] <> ""),
    Added_Excluir = Table.AddColumn(Filtered_Null_Atis, "Excluir", each "NO", type text),
    Removed_Duplicates = Table.Distinct(Added_Excluir)
    in
        Removed_Duplicates,
Reitero_Calidad = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each [Extension] = ".txt"),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\Reitero\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], "_", ".", 1, 0), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", "_"), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Csv.Document(_,[Delimiter="Õ", Columns=73, Encoding=1252, QuoteStyle=QuoteStyle.None])}),
    Expanded_Content = Transform_Content{0}[Content],
    Filtered_Separador = Table.SelectRows(Expanded_Content, each not Text.Contains([Column1], "-")),
    Filtered_Null_Column2 = Table.SelectRows(Filtered_Separador, each [Column2] <> null and [Column2] <> ""),
    Promoted_Headers = Table.PromoteHeaders(Filtered_Null_Column2, [PromoteAllScalars=true]),
    Renamed_Medio_Acceso = try(Table.RenameColumns(Promoted_Headers,{{"Medio de Acceso", "Medio_de_Acceso"}}))otherwise(Promoted_Headers),
    Renamed_Atis = try(Table.RenameColumns(Renamed_Medio_Acceso,{{"Pet atis", "Pet_atis"}}))otherwise(Renamed_Medio_Acceso),
    Renamed_Identificador_Linea = try(Table.RenameColumns(Renamed_Atis,{{"Identificador PC Linea", "Identificador_PC_Linea"}}))otherwise(Renamed_Atis),
    Renamed_Fecha_Final = try(Table.RenameColumns(Renamed_Identificador_Linea,{{"Fecha de cierre final", "Fecha_de_cierre_final"}}))otherwise(Renamed_Identificador_Linea),
    Filtered_Null_Fecha = Table.SelectRows(Renamed_Fecha_Final, each [Fecha_de_cierre_final] <> null and [Fecha_de_cierre_final] <> ""),
    Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha_de_cierre_final", each Date.From(Value.FromText(_)), type date}}),
    Removed_Other_Columns = Table.SelectColumns(Transform_Fecha,{"Pet_atis", "AÑO_CIERRE", "MES_CIERRE", "Medio_de_Acceso", "APERTURA_AV", "CIERRE_AV"}),
    Replaced_NULL_Null = Table.ReplaceValue(Removed_Other_Columns,"NULL",null,Replacer.ReplaceValue,{"Pet_atis", "APERTURA_AV", "CIERRE_AV", "Medio_de_Acceso"}),
    Changed_Type = Table.TransformColumnTypes(Replaced_NULL_Null,{{"Pet_atis", type text}, {"APERTURA_AV", type text}, {"CIERRE_AV", type text}, {"Medio_de_Acceso", type text}, {"AÑO_CIERRE", Int64.Type}, {"MES_CIERRE", Int64.Type}}),
    Trimmed_Text = Table.TransformColumns(Changed_Type,{{"Pet_atis", Text.Trim, type text}, {"APERTURA_AV", Text.Trim, type text}, {"CIERRE_AV", Text.Trim, type text}, {"Medio_de_Acceso", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Pet_atis", Text.Clean, type text}, {"APERTURA_AV", Text.Clean, type text}, {"CIERRE_AV", Text.Clean, type text}, {"Medio_de_Acceso", Text.Clean, type text}}),
    Filtered_Null_Atis = Table.SelectRows(Cleaned_Text, each [Pet_atis] <> null and [Pet_atis] <> ""),
    Merged_Causales_Reitero = Table.NestedJoin(Filtered_Null_Atis, {"Medio_de_Acceso", "APERTURA_AV", "AÑO_CIERRE", "MES_CIERRE"}, Causales_Excluir_Reitero, {"Acceso", "Causal", "Año", "Mes"}, "Causales_Excluir_Reitero", JoinKind.LeftOuter),
    Expanded_Causales = Table.ExpandTableColumn(Merged_Causales_Reitero, "Causales_Excluir_Reitero", {"Excluir"}, {"Excluir"}),
    Replaced_Null_Excluir = Table.ReplaceValue(Expanded_Causales,null,"NO",Replacer.ReplaceValue,{"Excluir"}),
    Removed_Other_Columns_Final = Table.SelectColumns(Replaced_Null_Excluir,{"Pet_atis", "APERTURA_AV", "CIERRE_AV", "Excluir"}),
    Removed_Duplicates = Table.Distinct(Removed_Other_Columns_Final)
    in
        Removed_Duplicates,
Calidad_I_M = let
    Source = Table.Combine({Reitero_Calidad, Infancias_Calidad}),
    RemovedDuplicates = Table.Distinct(Source)
    in
        RemovedDuplicates,
Gestion_Odisea = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".xlsx")),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\Logistica\GestionODISEA\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], ".", " "), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BeforeDelimiter([Name], "."), type text),
    Added_Fecha = Table.AddColumn(Added_Mes, "Fecha", each Text.Combine({[Mes], [Año]}, "/"), type text),
    Parsed_Date_Fecha = Table.TransformColumns(Added_Fecha,{{"Fecha", each Date.EndOfMonth(Date.From(DateTimeZone.From(_))), type date}}),
    Changed_Type_Date = Table.TransformColumnTypes(Parsed_Date_Fecha,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Excel.Workbook(_)}),
    Expanded_Content = Table.ExpandTableColumn(Transform_Content, "Content", {"Name", "Data", "Kind"}, {"Content.Name", "Content.Data", "Content.Kind"}),
    Filtered_Kind = Table.SelectRows(Expanded_Content, each ([Content.Kind] = "Table")),
    Removed_Other_Columns = Table.SelectColumns(Filtered_Kind,{"Content.Data", "Año", "Mes", "Fecha"}),
    Expanded_Content_data = Table.ExpandTableColumn(Removed_Other_Columns, "Content.Data", {"Fecha_Cierre", "Identificacion", "Departamento", "Actuacion", "Pedido_Atis", "ESTADO ORDEN"}, {"Fecha_Cierre", "Identificacion", "Departamento", "Actuacion", "Pedido_Atis", "ESTADO ORDEN"}),
    Filtered_Null_Fecha = Table.SelectRows(Expanded_Content_data, each [Fecha_Cierre] <> null and [Fecha_Cierre] <> ""),
    Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha_Cierre", each Date.From(Value.FromText(_)), type date}}),
    Changed_Type = Table.TransformColumnTypes(Transform_Fecha,{{"Fecha_Cierre", type date}, {"Identificacion", type text}, {"Departamento", type text}, {"Actuacion", type text}, {"Pedido_Atis", type text}, {"ESTADO ORDEN", type text}}),
    Trimmed_Text = Table.TransformColumns(Changed_Type,{{"Identificacion", Text.Trim, type text}, {"Departamento", Text.Trim, type text}, {"Actuacion", Text.Trim, type text}, {"Pedido_Atis", Text.Trim, type text}, {"ESTADO ORDEN", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Identificacion", Text.Clean, type text}, {"Departamento", Text.Clean, type text}, {"Actuacion", Text.Clean, type text}, {"Pedido_Atis", Text.Clean, type text}, {"ESTADO ORDEN", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Departamento", Text.Proper, type text}, {"ESTADO ORDEN", Text.Proper, type text}}),
    Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"ESTADO ORDEN", "Estado Odisea"}, {"Fecha_Cierre", "Fecha Caso"}}),
    Filtered_Null_Atis = Table.SelectRows(Renamed_Columns, each [Pedido_Atis] <> null and [Pedido_Atis] <> ""),
    Filtered_Null_CC_Tec = Table.SelectRows(Filtered_Null_Atis, each [Identificacion] <> null and [Identificacion] <> ""),
    Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_CC_Tec, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
    Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
    Removed_Duplicates = Table.Distinct(Removed_Columns),
    Added_Dias_Orden = Table.AddColumn(Removed_Duplicates, "Dias", each if(Date.Month([Fecha])=Date.Month(Date.From(DateTime.LocalNow())))and(Date.Year([Fecha])=Date.Year(Date.From(DateTime.LocalNow())))then(Date.From(DateTime.LocalNow())-Date.From([Fecha Caso]))else([Fecha]-Date.From([Fecha Caso]))),
    Extracted_Days_Orden = Table.TransformColumns(Added_Dias_Orden,{{"Dias", Duration.Days, Int64.Type}}),
    Grouped_Rows = Table.Group(Extracted_Days_Orden, {"Identificacion", "Año", "Mes"}, {{"Sin Gestion", each Table.RowCount(_), Int64.Type}, {"All", each _, type table [Fecha Caso=nullable date, Identificacion=text, Departamento=text, Actuacion=text, Pedido_Atis=text, Estado Odisea=text, Año=nullable number, Mes=nullable number, Fecha=date, Dias=number]}})
    in
        Grouped_Rows,
Indicador_Odisea = let
    Source = Table.Combine({Produccion_Altas, Produccion_Mantenimiento}),
    Inserted_Year = Table.AddColumn(Source, "Año", each Date.Year([Fecha]), Int64.Type),
    Inserted_Month = Table.AddColumn(Inserted_Year, "Mes", each Date.Month([Fecha]), Int64.Type),
    Grouped_Rows = Table.Group(Inserted_Month, {"CC Tec", "Año", "Mes"}, {{"Total", each Table.RowCount(_), Int64.Type}}),
    Merged_Gestion_Odisea = Table.NestedJoin(Grouped_Rows, {"CC Tec", "Año", "Mes"}, Gestion_Odisea, {"Identificacion", "Año", "Mes"}, "Gestion_Odisea", JoinKind.LeftOuter),
    ExpandedGestion_Odisea = Table.ExpandTableColumn(Merged_Gestion_Odisea, "Gestion_Odisea", {"Sin Gestion", "All"}, {"Sin Gestion", "All"}),
    Replaced_Null_Sin_Gestion = Table.ReplaceValue(ExpandedGestion_Odisea,null,0,Replacer.ReplaceValue,{"Sin Gestion"}),
    Merged_Parametro_Nota = Table.NestedJoin(Replaced_Null_Sin_Gestion, {"Año", "Mes"}, Parametro_Nota, {"Año", "Mes"}, "Parametro_Nota", JoinKind.LeftOuter),
    Expanded_Parametro_Nota = Table.ExpandTableColumn(Merged_Parametro_Nota, "Parametro_Nota", {"Ind Odisea"}, {"Ind Odisea"}),
    Added_Porcentaje_Cumple = Table.AddColumn(Expanded_Parametro_Nota, "% Cumple", each [Sin Gestion]/[Total], type number),
    Added_Indicador = Table.AddColumn(Added_Porcentaje_Cumple, "Indicador", each if([#"% Cumple"]<=[Ind Odisea])then("Cumple")else("No Cumple"), type text),
    Expanded_All = Table.ExpandTableColumn(Added_Indicador, "All", {"Fecha Caso", "Pedido_Atis", "Estado Odisea", "Dias"}, {"Fecha Caso", "Pedido_Atis", "Estado Odisea", "Dias"}),
    Added_Indicador_Logistica = Table.AddColumn(Expanded_All, "Indicador Log", each "Odisea", type text),
    Removed_Columns = Table.RemoveColumns(Added_Indicador_Logistica,{"Total", "Sin Gestion", "Ind Odisea"})
    in
        Removed_Columns,
Series_Siscos = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".xlsx")),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\Logistica\SeriesEnCalleSISCOS\") and not Text.Contains([Folder Path], "CuadroMando")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], ".", " "), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BeforeDelimiter([Name], "."), type text),
    Added_Fecha = Table.AddColumn(Added_Mes, "Fecha", each Text.Combine({[Mes], [Año]}, "/"), type text),
    Parsed_Date_Fecha = Table.TransformColumns(Added_Fecha,{{"Fecha", each Date.EndOfMonth(Date.From(DateTimeZone.From(_))), type date}}),
    Changed_Type_Date = Table.TransformColumnTypes(Parsed_Date_Fecha,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Excel.Workbook(_)}),
    Expanded_Content = Table.ExpandTableColumn(Transform_Content, "Content", {"Name", "Data", "Kind"}, {"Content.Name", "Content.Data", "Content.Kind"}),
    Filtered_Kind = Table.SelectRows(Expanded_Content, each ([Content.Kind] = "Table")),
    Removed_Other_Columns = Table.SelectColumns(Filtered_Kind,{"Content.Data", "Año", "Mes", "Fecha"}),
    Expanded_Content_data = Table.ExpandTableColumn(Removed_Other_Columns, "Content.Data", {"DEPARTAMENTO", "codigo_material", "descriocion_material", "tipo_material", "cedula_tecnico", "serial", "fecha_entrega"}, {"DEPARTAMENTO", "codigo_material", "descriocion_material", "tipo_material", "cedula_tecnico", "serial", "fecha_entrega"}),
    Filtered_Null_Fecha = Table.SelectRows(Expanded_Content_data, each [fecha_entrega] <> null and [fecha_entrega] <> ""),
    Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"fecha_entrega", each Date.From(Value.FromText(_)), type date}}),
    Changed_Type = Table.TransformColumnTypes(Transform_Fecha,{{"codigo_material", type text}, {"descriocion_material", type text}, {"tipo_material", type text}, {"cedula_tecnico", type text}, {"serial", type text}, {"fecha_entrega", type date}, {"DEPARTAMENTO", type text}}),
    #"Trimmed Text" = Table.TransformColumns(Changed_Type,{{"codigo_material", Text.Trim, type text}, {"descriocion_material", Text.Trim, type text}, {"tipo_material", Text.Trim, type text}, {"cedula_tecnico", Text.Trim, type text}, {"serial", Text.Trim, type text}, {"DEPARTAMENTO", Text.Trim, type text}}),
    #"Cleaned Text" = Table.TransformColumns(#"Trimmed Text",{{"codigo_material", Text.Clean, type text}, {"descriocion_material", Text.Clean, type text}, {"tipo_material", Text.Clean, type text}, {"cedula_tecnico", Text.Clean, type text}, {"serial", Text.Clean, type text}, {"DEPARTAMENTO", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(#"Cleaned Text",{{"DEPARTAMENTO", Text.Proper, type text}}),
    Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"DEPARTAMENTO", "Departamento"}, {"codigo_material", "Cod Mat"}, {"descriocion_material", "Material"}, {"cedula_tecnico", "CC Tec"}, {"serial", "Serial"}, {"fecha_entrega", "Fecha Caso"}}),
    Filtered_Null_Serial = Table.SelectRows(Renamed_Columns, each [Serial] <> null and [Serial] <> ""),
    Filtered_Null_CC_Tec = Table.SelectRows(Filtered_Null_Serial, each [CC Tec] <> null and [CC Tec] <> ""),
    Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_CC_Tec, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
    Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
    Added_Indicador_Logistica = Table.AddColumn(Filtered_Null_Dep, "Indicador Log", each if([tipo_material]="MATERIAL MOVISTAR")then("Rotacion")else("Reintegro"), type text),
    Removed_Columns = Table.RemoveColumns(Added_Indicador_Logistica,{"TblDepartamentos", "tipo_material"}),
    Removed_Duplicates = Table.Distinct(Removed_Columns),
    Added_Dias_Calle = Table.AddColumn(Removed_Duplicates, "Dias", each if(Date.Month([Fecha])=Date.Month(Date.From(DateTime.LocalNow())))then(Date.From(DateTime.LocalNow())-Date.From([Fecha Caso]))else([Fecha]-Date.From([Fecha Caso]))),
    Extracted_Days_Calle = Table.TransformColumns(Added_Dias_Calle,{{"Dias", Duration.Days, Int64.Type}}),
    Added_Cantidad = Table.AddColumn(Extracted_Days_Calle, "Cantidad", each 1, type number),
    Merged_Tecnicos_Localidad = Table.NestedJoin(Added_Cantidad, {"CC Tec", "Año", "Mes"}, Tecnicos_Localidad, {"CEDULA", "Año", "Mes"}, "Tecnicos_Localidad", JoinKind.LeftOuter),
    Expanded_Tecnicos_Localidad = Table.ExpandTableColumn(Merged_Tecnicos_Localidad, "Tecnicos_Localidad", {"Tipo Tecnico"}, {"Tipo Tecnico"}),
    Replaced_Null_Tipo_Tecnico = Table.ReplaceValue(Expanded_Tecnicos_Localidad,null,"Bodega",Replacer.ReplaceValue,{"Tipo Tecnico"}),
    Merged_Valor_Material = Table.NestedJoin(Replaced_Null_Tipo_Tecnico, {"Cod Mat", "Año", "Mes"}, Valor_Materiales, {"codigo_material", "Año", "Mes"}, "Valor_Materiales", JoinKind.LeftOuter),
    Expanded_Valor_Material = Table.ExpandTableColumn(Merged_Valor_Material, "Valor_Materiales", {"Valor"}, {"Valor"}),
    Replaced_Null_Valor = Table.ReplaceValue(Expanded_Valor_Material,null,1,Replacer.ReplaceValue,{"Valor"}),
    Merged_Tiempos = Table.NestedJoin(Replaced_Null_Valor, {"Tipo Tecnico", "Indicador Log", "Año", "Mes", "Dias"}, Tiempos, {"Tipo Tecnico", "Tipo", "Año", "Mes", "Días"}, "Tiempos", JoinKind.LeftOuter),
    Expanded_Tiempos = Table.ExpandTableColumn(Merged_Tiempos, "Tiempos", {"Lapso", "Rango"}, {"Lapso", "Rango"}),
    Added_Cumplimiento = Table.AddColumn(Expanded_Tiempos, "Cumplimiento", each if([Lapso]="A Tiempo")then("Cumple")else("No Cumple"), type text),
    Pivoted_Cumplimiento = Table.Pivot(Added_Cumplimiento, List.Distinct(Added_Cumplimiento[Cumplimiento]), "Cumplimiento", "Cantidad", List.Sum),
    Replaced_Null_No_Cumple = try(Table.ReplaceValue(Pivoted_Cumplimiento,null,0,Replacer.ReplaceValue,{"No Cumple"}))otherwise(Table.AddColumn(Pivoted_Cumplimiento, "No Cumple", each 0, type number)),
    Replaced_Null_Cumple = try(Table.ReplaceValue(Replaced_Null_No_Cumple,null,0,Replacer.ReplaceValue,{"Cumple"}))otherwise(Table.AddColumn(Replaced_Null_No_Cumple, "Cumple", each 0, type number)),
    Grouped_Rows = Table.Group(Replaced_Null_Cumple, {"CC Tec", "Año", "Mes", "Indicador Log"}, {{"Cumple", each List.Sum([Cumple]), type nullable number}, {"No Cumple", each List.Sum([No Cumple]), type nullable number}, {"All", each _, type table [Departamento=text, Cod Mat=text, Material=text, CC Tec=text, Serial=text, Fecha Caso=nullable date, Año=nullable number, Mes=nullable number, Fecha=date, Indicador Log=text, Dias=number, Tipo Tecnico=nullable text, Valor=nullable number, Lapso=nullable text, Rango=nullable text, Cumple=nullable number, No Cumple=nullable number]}}),
    Merged_Parametro_Nota = Table.NestedJoin(Grouped_Rows, {"Año", "Mes"}, Parametro_Nota, {"Año", "Mes"}, "Parametro_Nota", JoinKind.LeftOuter),
    Expanded_Parametro_Nota = Table.ExpandTableColumn(Merged_Parametro_Nota, "Parametro_Nota", {"Rotacion", "Reintegro"}, {"Rotacion", "Reintegro"}),
    Added_Indicador = Table.AddColumn(Expanded_Parametro_Nota, "Indicador", each if([Indicador Log]="Rotacion")then(if([Rotacion]>=[No Cumple])then("Cumple")else("No Cumple"))else(if([Reintegro]>=[No Cumple])then("Cumple")else("No Cumple")), type text),
    Added_Porcentaje_Cumple = Table.AddColumn(Added_Indicador, "% Cumple", each 1-([No Cumple]/([Cumple]+[No Cumple])), type number),
    Expanded_All = Table.ExpandTableColumn(Added_Porcentaje_Cumple, "All", {"Cod Mat", "Material", "Serial", "Fecha Caso", "Dias", "Tipo Tecnico", "Valor", "Lapso", "Rango"}, {"Cod Mat", "Material", "Serial", "Fecha Caso", "Dias", "Tipo Tecnico", "Valor", "Lapso", "Rango"}),
    Removed_Columns_Final = Table.RemoveColumns(Expanded_All,{"Rotacion", "Reintegro", "Cumple", "No Cumple", "Tipo Tecnico"})
    in
        Removed_Columns_Final,
Cumplimiento_Citas = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".txt")),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\Cumplimiento de Citas\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], "_", ".", 1, 0), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", "_"), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Csv.Document(_,[Delimiter="Õ", Columns=33, Encoding=1252, QuoteStyle=QuoteStyle.None])}),
    Expanded_Content = Transform_Content{0}[Content],
    Filtered_Separador = Table.SelectRows(Expanded_Content, each not Text.Contains([Column1], "-")),
    Filtered_Null_Column2 = Table.SelectRows(Filtered_Separador, each [Column2] <> null and [Column2] <> ""),
    Promoted_Headers = Table.PromoteHeaders(Filtered_Null_Column2, [PromoteAllScalars=true]),
    Renamed_Fecha_cita_agendamiento = try(Table.RenameColumns(Promoted_Headers,{{"Fecha cita agendamiento", "Fecha_cita_agendamiento"}}))otherwise(Promoted_Headers),
    Filtered_Null_Fecha = Table.SelectRows(Renamed_Fecha_cita_agendamiento, each [Fecha_cita_agendamiento] <> null and [Fecha_cita_agendamiento] <> ""),
    Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha_cita_agendamiento", each Date.From(Value.FromText(_)), type date}}),
    Filtered_Exclusiones_Contrato = Table.SelectRows(Transform_Fecha, each [exclusiones_contrato] = "NULL"),
    Removed_Other_Columns = Table.SelectColumns(Filtered_Exclusiones_Contrato,{"SLA", "Fecha_cita_agendamiento", "AÑO_CIERRE", "MES_CIERRE", "Pet_atis", "Departamento", "Numero_de_actuacion", "external_id"}),
    Replaced_NULL_null = Table.ReplaceValue(Removed_Other_Columns,"NULL",null,Replacer.ReplaceValue,{"SLA", "Pet_atis", "Departamento", "Numero_de_actuacion", "external_id"}),
    Changed_Type = Table.TransformColumnTypes(Replaced_NULL_null,{{"SLA", type text}, {"Fecha_cita_agendamiento", type date}, {"Pet_atis", type text}, {"Departamento", type text}, {"Numero_de_actuacion", type text}, {"external_id", type text}, {"AÑO_CIERRE", Int64.Type}, {"MES_CIERRE", Int64.Type}}),
    Trimmed_Text = Table.TransformColumns(Changed_Type,{{"SLA", Text.Trim, type text}, {"Pet_atis", Text.Trim, type text}, {"Departamento", Text.Trim, type text}, {"Numero_de_actuacion", Text.Trim, type text}, {"external_id", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"SLA", Text.Clean, type text}, {"Pet_atis", Text.Clean, type text}, {"Departamento", Text.Clean, type text}, {"Numero_de_actuacion", Text.Clean, type text}, {"external_id", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"SLA", Text.Proper, type text}, {"Departamento", Text.Proper, type text}}),
    Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"Fecha_cita_agendamiento", "Fecha"}, {"Pet_atis", "Atis"}, {"Numero_de_actuacion", "ATiempo"}, {"AÑO_CIERRE", "Año"}, {"MES_CIERRE", "Mes"}}),
    Filtered_Null_Atis = Table.SelectRows(Renamed_Columns, each [Atis] <> null and [Atis] <> ""),
    Filtered_Null_CC_Tec = Table.SelectRows(Filtered_Null_Atis, each [external_id] <> null and [external_id] <> ""),
    Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_CC_Tec, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
    Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
    Added_Cantidad = Table.AddColumn(Removed_Columns, "Cantidad", each 1, type number),
    Pivoted_SLA = Table.Pivot(Added_Cantidad, List.Distinct(Added_Cantidad[SLA]), "SLA", "Cantidad", List.Sum),
    Replaced_Null__No_Cumple = try(Table.ReplaceValue(Pivoted_SLA,null,0,Replacer.ReplaceValue,{"No Cumple"})) otherwise(Table.AddColumn(Pivoted_SLA, "No Cumple", each 0, type number)),
    Replaced_Null__Cumple = try(Table.ReplaceValue(Replaced_Null__No_Cumple,null,0,Replacer.ReplaceValue,{"Cumple"})) otherwise(Table.AddColumn(Replaced_Null__No_Cumple, "Cumple", each 0, type number)),
    Added_Aperturas = Table.AddColumn(Replaced_Null__Cumple, "Aperturas", each "Cumplimiento de citas", type text),
    Added_Productos = Table.AddColumn(Added_Aperturas, "Productos", each "TOTAL", type text),
    Removed_Duplicates = Table.Distinct(Added_Productos)
    in
        Removed_Duplicates,
Plazo_3_Dias = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".txt")),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\Plazos\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], "_", ".", 1, 0), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", "_"), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Csv.Document(_,[Delimiter="Õ", Columns=45, Encoding=1252, QuoteStyle=QuoteStyle.None])}),
    Expanded_Content = Transform_Content{0}[Content],
    Filtered_Separador = Table.SelectRows(Expanded_Content, each not Text.Contains([Column1], "-")),
    Filtered_Null_Column2 = Table.SelectRows(Filtered_Separador, each [Column2] <> null and [Column2] <> ""),
    Promoted_Headers = Table.PromoteHeaders(Filtered_Null_Column2, [PromoteAllScalars=true]),
    Filtered_Null_Fecha = Table.SelectRows(Promoted_Headers, each [Fecha_de_cierre_final] <> null and [Fecha_de_cierre_final] <> ""),
    Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha_de_cierre_final", each Date.From(Value.FromText(_)), type date}}),
    Removed_Other_Columns = Table.SelectColumns(Transform_Fecha,{"CUMPLE_SLA_3D", "DEPARTAMENTO", "Pet_atis", "Identificador_PC_Linea", "Fecha_de_cierre_final", "AÑO_CIERRE", "MES_CIERRE", "external_id"}),
    Replaced_NULL_null = Table.ReplaceValue(Removed_Other_Columns,"NULL",null,Replacer.ReplaceValue,{"CUMPLE_SLA_3D", "DEPARTAMENTO", "Pet_atis", "Identificador_PC_Linea", "external_id", "AÑO_CIERRE", "MES_CIERRE"}),
    Changed_Type = Table.TransformColumnTypes(Replaced_NULL_null,{{"CUMPLE_SLA_3D", type text}, {"Pet_atis", type text}, {"Identificador_PC_Linea", type text}, {"Fecha_de_cierre_final", type date}, {"external_id", type text}, {"DEPARTAMENTO", type text}, {"AÑO_CIERRE", Int64.Type}, {"MES_CIERRE", Int64.Type}}),
    Trimmed_Text = Table.TransformColumns(Changed_Type,{{"CUMPLE_SLA_3D", Text.Trim, type text}, {"Pet_atis", Text.Trim, type text}, {"Identificador_PC_Linea", Text.Trim, type text}, {"external_id", Text.Trim, type text}, {"DEPARTAMENTO", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"CUMPLE_SLA_3D", Text.Clean, type text}, {"Pet_atis", Text.Clean, type text}, {"Identificador_PC_Linea", Text.Clean, type text}, {"external_id", Text.Clean, type text}, {"DEPARTAMENTO", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"DEPARTAMENTO", Text.Proper, type text}}),
    Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"DEPARTAMENTO", "Departamento"}, {"Pet_atis", "Atis"}, {"Identificador_PC_Linea", "ATiempo"}, {"Fecha_de_cierre_final", "Fecha"}, {"AÑO_CIERRE", "Año"}, {"MES_CIERRE", "Mes"}}),
    Filtered_Null_Atis = Table.SelectRows(Renamed_Columns, each [Atis] <> null and [Atis] <> ""),
    Filtered_Null_CC_Tec = Table.SelectRows(Filtered_Null_Atis, each [external_id] <> null and [external_id] <> ""),
    Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_CC_Tec, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
    Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
    Added_Cantidad = Table.AddColumn(Removed_Columns, "Cantidad", each 1, type number),
    Replaced_No_Cumple_SLA = Table.ReplaceValue(Added_Cantidad,"NO","No Cumple",Replacer.ReplaceText,{"CUMPLE_SLA_3D"}),
    Replaced_Cumple_SLA = Table.ReplaceValue(Replaced_No_Cumple_SLA,"SI","Cumple",Replacer.ReplaceText,{"CUMPLE_SLA_3D"}),
    Pivoted_SLA = Table.Pivot(Replaced_Cumple_SLA, List.Distinct(Replaced_Cumple_SLA[CUMPLE_SLA_3D]), "CUMPLE_SLA_3D", "Cantidad", List.Sum),
    Replaced_Null__No_Cumple = try(Table.ReplaceValue(Pivoted_SLA,null,0,Replacer.ReplaceValue,{"No Cumple"})) otherwise(Table.AddColumn(Pivoted_SLA, "No Cumple", each 0, type number)),
    Replaced_Null__Cumple = try(Table.ReplaceValue(Replaced_Null__No_Cumple,null,0,Replacer.ReplaceValue,{"Cumple"})) otherwise(Table.AddColumn(Replaced_Null__No_Cumple, "Cumple", each 0, type number)),
    Added_Aperturas = Table.AddColumn(Replaced_Null__Cumple, "Aperturas", each "Plazos de Mtto (3 días)", type text),
    Added_Productos = Table.AddColumn(Added_Aperturas, "Productos", each "Todos", type text),
    Removed_Duplicates = Table.Distinct(Added_Productos)
    in
        Removed_Duplicates,
Plazos = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".txt")),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\Plazos\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], "_", ".", 1, 0), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", "_"), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Csv.Document(_,[Delimiter="Õ", Columns=45, Encoding=1252, QuoteStyle=QuoteStyle.None])}),
    Expanded_Content = Transform_Content{0}[Content],
    Filtered_Separador = Table.SelectRows(Expanded_Content, each not Text.Contains([Column1], "-")),
    Filtered_Null_Column2 = Table.SelectRows(Filtered_Separador, each [Column2] <> null and [Column2] <> ""),
    Promoted_Headers = Table.PromoteHeaders(Filtered_Null_Column2, [PromoteAllScalars=true]),
    Filtered_Null_Fecha = Table.SelectRows(Promoted_Headers, each [Fecha_de_cierre_final] <> null and [Fecha_de_cierre_final] <> ""),
    Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha_de_cierre_final", each Date.From(Value.FromText(_)), type date}}),
    Removed_Other_Columns = Table.SelectColumns(Transform_Fecha,{"CUMPLE_SLA", "ALTO_VALOR", "DEPARTAMENTO", "Pet_atis", "Identificador_PC_Linea", "Fecha_de_cierre_final", "AÑO_CIERRE", "MES_CIERRE", "external_id"}),
    Replaced_NULL_null = Table.ReplaceValue(Removed_Other_Columns,"NULL",null,Replacer.ReplaceValue,{"CUMPLE_SLA", "ALTO_VALOR", "DEPARTAMENTO", "Pet_atis", "Identificador_PC_Linea", "external_id"}),
    Changed_Type = Table.TransformColumnTypes(Replaced_NULL_null,{{"CUMPLE_SLA", type text}, {"ALTO_VALOR", type text}, {"Pet_atis", type text}, {"Identificador_PC_Linea", type text}, {"Fecha_de_cierre_final", type date}, {"external_id", type text}, {"DEPARTAMENTO", type text}, {"AÑO_CIERRE", Int64.Type}, {"MES_CIERRE", Int64.Type}}),
    Trimmed_Text = Table.TransformColumns(Changed_Type,{{"CUMPLE_SLA", Text.Trim, type text}, {"ALTO_VALOR", Text.Trim, type text}, {"Pet_atis", Text.Trim, type text}, {"Identificador_PC_Linea", Text.Trim, type text}, {"external_id", Text.Trim, type text}, {"DEPARTAMENTO", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"CUMPLE_SLA", Text.Clean, type text}, {"ALTO_VALOR", Text.Clean, type text}, {"Pet_atis", Text.Clean, type text}, {"Identificador_PC_Linea", Text.Clean, type text}, {"external_id", Text.Clean, type text}, {"DEPARTAMENTO", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"DEPARTAMENTO", Text.Proper, type text}}),
    Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"DEPARTAMENTO", "Departamento"}, {"Pet_atis", "Atis"}, {"Identificador_PC_Linea", "ATiempo"}, {"Fecha_de_cierre_final", "Fecha"}, {"AÑO_CIERRE", "Año"}, {"MES_CIERRE", "Mes"}}),
    Filtered_Null_Atis = Table.SelectRows(Renamed_Columns, each [Atis] <> null and [Atis] <> ""),
    Filtered_Null_CC_Tec = Table.SelectRows(Filtered_Null_Atis, each [external_id] <> null and [external_id] <> ""),
    Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_CC_Tec, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
    Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
    Added_Cantidad = Table.AddColumn(Removed_Columns, "Cantidad", each 1, type number),
    Replaced_No_Cumple_SLA = Table.ReplaceValue(Added_Cantidad,"NO","No Cumple",Replacer.ReplaceText,{"CUMPLE_SLA"}),
    Replaced_Cumple_SLA = Table.ReplaceValue(Replaced_No_Cumple_SLA,"SI","Cumple",Replacer.ReplaceText,{"CUMPLE_SLA"}),
    Pivoted_SLA = Table.Pivot(Replaced_Cumple_SLA, List.Distinct(Replaced_Cumple_SLA[CUMPLE_SLA]), "CUMPLE_SLA", "Cantidad", List.Sum),
    Replaced_Null__No_Cumple = try(Table.ReplaceValue(Pivoted_SLA,null,0,Replacer.ReplaceValue,{"No Cumple"})) otherwise(Table.AddColumn(Pivoted_SLA, "No Cumple", each 0, type number)),
    Replaced_Null__Cumple = try(Table.ReplaceValue(Replaced_Null__No_Cumple,null,0,Replacer.ReplaceValue,{"Cumple"})) otherwise(Table.AddColumn(Replaced_Null__No_Cumple, "Cumple", each 0, type number)),
    Added_Aperturas = Table.AddColumn(Replaced_Null__Cumple, "Aperturas", each "Plazos de Mtto (3 días)", type text),
    Added_Productos = Table.AddColumn(Added_Aperturas, "Productos", each if([ALTO_VALOR]="SI")then("FTTH y/o Alto valor(AM-PM)")else("Masivos (1día)"), type text),
    Removed_Duplicates = Table.Distinct(Added_Productos),
    Removed_Alto_valor = Table.RemoveColumns(Removed_Duplicates,{"ALTO_VALOR"})
    in
        Removed_Alto_valor,
Reitero = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each [Extension] = ".txt"),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\Reitero\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], "_", ".", 1, 0), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", "_"), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Csv.Document(_,[Delimiter="Õ", Columns=73, Encoding=1252, QuoteStyle=QuoteStyle.None])}),
    Expanded_Content = Transform_Content{0}[Content],
    Filtered_Separador = Table.SelectRows(Expanded_Content, each not Text.Contains([Column1], "-")),
    Filtered_Null_Column2 = Table.SelectRows(Filtered_Separador, each [Column2] <> null and [Column2] <> ""),
    Promoted_Headers = Table.PromoteHeaders(Filtered_Null_Column2, [PromoteAllScalars=true]),
    Renamed_Medio_Acceso = try(Table.RenameColumns(Promoted_Headers,{{"Medio de Acceso", "Medio_de_Acceso"}}))otherwise(Promoted_Headers),
    Renamed_Atis = try(Table.RenameColumns(Renamed_Medio_Acceso,{{"Pet atis", "Pet_atis"}}))otherwise(Renamed_Medio_Acceso),
    Renamed_Identificador_Linea = try(Table.RenameColumns(Renamed_Atis,{{"Identificador PC Linea", "Identificador_PC_Linea"}}))otherwise(Renamed_Atis),
    Renamed_Fecha_Final = try(Table.RenameColumns(Renamed_Identificador_Linea,{{"Fecha de cierre final", "Fecha_de_cierre_final"}}))otherwise(Renamed_Identificador_Linea),
    Filtered_Null_Fecha = Table.SelectRows(Renamed_Fecha_Final, each [Fecha_de_cierre_final] <> null and [Fecha_de_cierre_final] <> ""),
    Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha_de_cierre_final", each Date.From(Value.FromText(_)), type date}}),
    Removed_Other_Columns = Table.SelectColumns(Transform_Fecha,{"Pet_atis", "Identificador_PC_Linea", "Fecha_de_cierre_final", "AÑO_CIERRE", "MES_CIERRE", "Familia", "Medio_de_Acceso", "DEPARTAMENTO", "external_id", "APERTURA_AV", "CIERRE_AV", "external_id_MTTOA"}),
    Replaced_NULL_Null = Table.ReplaceValue(Removed_Other_Columns,"NULL",null,Replacer.ReplaceValue,{"Pet_atis", "Identificador_PC_Linea", "Familia", "Medio_de_Acceso", "DEPARTAMENTO", "external_id", "APERTURA_AV", "CIERRE_AV", "external_id_MTTOA"}),
    Changed_Type = Table.TransformColumnTypes(Replaced_NULL_Null,{{"Pet_atis", type text}, {"APERTURA_AV", type text}, {"CIERRE_AV", type text}, {"Medio_de_Acceso", type text}, {"AÑO_CIERRE", Int64.Type}, {"MES_CIERRE", Int64.Type}, {"Identificador_PC_Linea", type text}, {"Fecha_de_cierre_final", type date}, {"Familia", type text}, {"DEPARTAMENTO", type text}, {"external_id", type text}, {"external_id_MTTOA", type text}}),
    Trimmed_Text = Table.TransformColumns(Changed_Type,{{"Pet_atis", Text.Trim, type text}, {"Identificador_PC_Linea", Text.Trim, type text}, {"Familia", Text.Trim, type text}, {"Medio_de_Acceso", Text.Trim, type text}, {"DEPARTAMENTO", Text.Trim, type text}, {"external_id", Text.Trim, type text}, {"APERTURA_AV", Text.Trim, type text}, {"CIERRE_AV", Text.Trim, type text}, {"external_id_MTTOA", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Pet_atis", Text.Clean, type text}, {"Identificador_PC_Linea", Text.Clean, type text}, {"Familia", Text.Clean, type text}, {"Medio_de_Acceso", Text.Clean, type text}, {"DEPARTAMENTO", Text.Clean, type text}, {"external_id", Text.Clean, type text}, {"APERTURA_AV", Text.Clean, type text}, {"CIERRE_AV", Text.Clean, type text}, {"external_id_MTTOA", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"DEPARTAMENTO", Text.Proper, type text}}),
    Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"Pet_atis", "Atis"}, {"Identificador_PC_Linea", "ATiempo"}, {"Fecha_de_cierre_final", "Fecha"}, {"AÑO_CIERRE", "Año"}, {"MES_CIERRE", "Mes"}, {"DEPARTAMENTO", "Departamento"}}),
    Filtered_Null_Atis = Table.SelectRows(Renamed_Columns, each [Atis] <> null and [Atis] <> ""),
    Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_Atis, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
    Filtered_Null_Departamento = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Tbl_Departamentos = Table.RemoveColumns(Filtered_Null_Departamento,{"TblDepartamentos"}),
    Added_Aperturas = Table.AddColumn(Removed_Tbl_Departamentos, "Aperturas", each "Averías reiteradas", type text),
    Added_Productos = Table.AddColumn(Added_Aperturas, "Productos", each if(([Medio_de_Acceso]="COBRE")and(([Familia]="DTH")or([Familia]="TV")))then("TV-DTH")else(if(([Medio_de_Acceso]="COBRE")and(([Familia]="DUO")or([Familia]="DUOS")))then("LB BA")else(if(([Medio_de_Acceso]="FIBRA") and ([Familia]="TV"))then("TV-IPTV")else(if(([Medio_de_Acceso]="FIBRA")and([Familia]="DUOS"))then("FTTH")else(if(([Medio_de_Acceso]="FIBRA")and([Familia]="TRIO"))then("FIBRA")else("LB"))))), type text),
    Added_No_Cumple = Table.AddColumn(Added_Productos, "No Cumple", each if([external_id_MTTOA]=null)then(0)else(1), type number),
    Selected_Columns_No_Cumple = Table.SelectColumns(Added_No_Cumple,{"Atis", "ATiempo", "Fecha", "Año", "Mes", "Departamento", "external_id_MTTOA", "Aperturas", "Productos", "No Cumple"}),
    Filtered_External_Mtto = Table.SelectRows(Selected_Columns_No_Cumple, each [external_id_MTTOA] <> null and [external_id_MTTOA] <> ""),
    Renamed_Columns_No_Cumple = Table.RenameColumns(Filtered_External_Mtto,{{"external_id_MTTOA", "external_id"}}),
    Added_Cumple = Table.AddColumn(Added_Productos, "Cumple", each if([external_id]=null)then(0)else(1), type number),
    Filtered_Null_External_Id_Mtto = Table.SelectRows(Added_Cumple, each [external_id_MTTOA] = null),
    Selected_Columns_Cumple = Table.SelectColumns(Filtered_Null_External_Id_Mtto,{"Atis", "ATiempo", "Fecha", "Año", "Mes", "Departamento", "external_id", "Aperturas", "Productos", "Cumple"}),
    Filtered_External = Table.SelectRows(Selected_Columns_Cumple, each [external_id] <> null and [external_id] <> ""),
    Appended_Query = Table.Combine({Filtered_External, Renamed_Columns_No_Cumple}),
    Replaced_Null = Table.ReplaceValue(Appended_Query,null,0,Replacer.ReplaceValue,{"Cumple", "No Cumple"})
    in
        Replaced_Null,
Altas_Mes_Anterior = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".txt")),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\Altas Mes Anterior\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], "_", ".", 1, 0), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", "_"), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Csv.Document(_,[Delimiter="Õ", Columns=26, Encoding=1252, QuoteStyle=QuoteStyle.None])}),
    Expanded_Content = Transform_Content{0}[Content],
    Filtered_Separador = Table.SelectRows(Expanded_Content, each not Text.Contains([Column1], "-")),
    Filtered_Null_Column2 = Table.SelectRows(Filtered_Separador, each [Column2] <> null and [Column2] <> ""),
    Promoted_Headers = Table.PromoteHeaders(Filtered_Null_Column2, [PromoteAllScalars=true]),
    Filtered_Null_Fecha = Table.SelectRows(Promoted_Headers, each [Fecha_de_cierre_final] <> null and [Fecha_de_cierre_final] <> ""),
    Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha_de_cierre_final", each Date.From(Value.FromText(_)), type date}}),
    Removed_Other_Columns = Table.SelectColumns(Transform_Fecha,{"Numero_de_actuacion", "Subtipo_de_orden", "Pet_atis", "Departamento", "Fecha_de_cierre_final", "BA", "IP_TV", "external_id", "Medio_de_Acceso"}),
    Added_Year_2 = Table.AddColumn(Removed_Other_Columns, "Año", each Date.Year(Date.AddMonths(DateTime.From([Fecha_de_cierre_final]), 1)), Int64.Type),
    Added_Mes_2 = Table.AddColumn(Added_Year_2, "Mes", each Date.Month(Date.AddMonths(DateTime.From([Fecha_de_cierre_final]), 1)), Int64.Type),
    Replaced_NULL_null = Table.ReplaceValue(Added_Mes_2,"NULL",null,Replacer.ReplaceValue,{"Numero_de_actuacion", "Subtipo_de_orden", "Pet_atis", "Departamento", "BA", "IP_TV", "external_id", "Medio_de_Acceso"}),
    Changed_Type = Table.TransformColumnTypes(Replaced_NULL_null,{{"Numero_de_actuacion", type text}, {"Subtipo_de_orden", type text}, {"Pet_atis", type text}, {"Departamento", type text}, {"Fecha_de_cierre_final", type date}, {"BA", type text}, {"IP_TV", type text}, {"external_id", type text}, {"Medio_de_Acceso", type text}}),
    Trimmed_Text = Table.TransformColumns(Changed_Type,{{"Medio_de_Acceso", Text.Trim, type text}, {"external_id", Text.Trim, type text}, {"IP_TV", Text.Trim, type text}, {"BA", Text.Trim, type text}, {"Departamento", Text.Trim, type text}, {"Pet_atis", Text.Trim, type text}, {"Subtipo_de_orden", Text.Trim, type text}, {"Numero_de_actuacion", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Medio_de_Acceso", Text.Clean, type text}, {"external_id", Text.Clean, type text}, {"IP_TV", Text.Clean, type text}, {"BA", Text.Clean, type text}, {"Departamento", Text.Clean, type text}, {"Pet_atis", Text.Clean, type text}, {"Subtipo_de_orden", Text.Clean, type text}, {"Numero_de_actuacion", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Departamento", Text.Proper, type text}}),
    Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"Numero_de_actuacion", "ATiempo"}, {"Pet_atis", "Atis"}, {"Fecha_de_cierre_final", "Fecha"}}),
    Filtered_Null_Atis = Table.SelectRows(Renamed_Columns, each [Atis] <> null and [Atis] <> ""),
    Filtered_Null_CC_Tec = Table.SelectRows(Filtered_Null_Atis, each [external_id] <> null and [external_id] <> ""),
    Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_CC_Tec, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
    Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
    Added_LB_BA = Table.AddColumn(Removed_Columns, "LB+BA", each if([Subtipo_de_orden]="ALTALB") or ([Subtipo_de_orden]="TRASLADOLB")then(1)else(if([BA]="BA") and ([Medio_de_Acceso]="COBRE")then(1)else(0)), type number),
    Added_IPTV = Table.AddColumn(Added_LB_BA, "TV (IPTV)", each if([IP_TV]="IP_TV")then(1)else(0), type number),
    Added_FTTH = Table.AddColumn(Added_IPTV, "FTTH", each if([BA]="BA") and ([Medio_de_Acceso]="FIBRA") then(1)else(0), type number),
    Unpivoted_Productos = Table.Unpivot(Added_FTTH, {"LB+BA", "TV (IPTV)", "FTTH"}, "Productos", "Cumple"),
    Removed_Duplicates = Table.Distinct(Unpivoted_Productos),
    Removed_Other_Columns_Fin = Table.SelectColumns(Removed_Duplicates,{"ATiempo", "Atis", "Departamento", "Fecha", "external_id", "Año", "Mes", "Productos", "Cumple"})
    in
        Removed_Other_Columns_Fin,
Infancia = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".txt")),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\Infancia\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], "_", ".", 1, 0), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", "_"), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Csv.Document(_,[Delimiter="Õ", Columns=43, Encoding=1252, QuoteStyle=QuoteStyle.None])}),
    Expanded_Content = Transform_Content{0}[Content],
    Filtered_Separador = Table.SelectRows(Expanded_Content, each not Text.Contains([Column1], "-")),
    Filtered_Null_Column2 = Table.SelectRows(Filtered_Separador, each [Column2] <> null and [Column2] <> ""),
    Promoted_Headers = Table.PromoteHeaders(Filtered_Null_Column2, [PromoteAllScalars=true]),
    Renamed_Actuacion_Alta = try(Table.RenameColumns(Promoted_Headers,{{"XA_ACTUACION ALTA", "XA_ACTUACION_ALTA"}}))otherwise(Promoted_Headers),
    Renamed_Atis_Alta = try(Table.RenameColumns(Renamed_Actuacion_Alta,{{"Pet atis ALTA", "Pet_atis_ALTA"}}))otherwise(Renamed_Actuacion_Alta),
    Renamed_Medio_Alta = try(Table.RenameColumns(Renamed_Atis_Alta,{{"Medio de Acceso ALTA", "Medio_de_Acceso_ALTA"}}))otherwise(Renamed_Atis_Alta),
    Renamed_Fecha_Final_Alta = try(Table.RenameColumns(Renamed_Medio_Alta,{{"Fecha de cierre final ALTA", "Fecha_de_cierre_final_ALTA"}}))otherwise(Renamed_Medio_Alta),
    Filtered_Null_Fecha = Table.SelectRows(Renamed_Fecha_Final_Alta, each [Fecha_de_cierre_final_ALTA] <> null and [Fecha_de_cierre_final_ALTA] <> ""),
    Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha_de_cierre_final_ALTA", each Date.From(Value.FromText(_)), type date}}),
    Removed_Other_Columns = Table.SelectColumns(Transform_Fecha,{"XA_ACTUACION_ALTA", "Pet_atis_ALTA", "PRODUCTO", "Medio_de_Acceso_ALTA", "Departamento_ALTA", "Fecha_de_cierre_final_ALTA", "external_id", "CIERRE_AV", "APERTURA_AV"}),
    Added_Year_2 = Table.AddColumn(Removed_Other_Columns, "Año", each Date.Year(Date.AddMonths(DateTime.From([Fecha_de_cierre_final_ALTA]), 1)), Int64.Type),
    Added_Mes_2 = Table.AddColumn(Added_Year_2, "Mes", each Date.Month(Date.AddMonths(DateTime.From([Fecha_de_cierre_final_ALTA]), 1)), Int64.Type),
    Replaced_NULL_null = Table.ReplaceValue(Added_Mes_2,"NULL",null,Replacer.ReplaceValue,{"XA_ACTUACION_ALTA", "Pet_atis_ALTA", "PRODUCTO", "Medio_de_Acceso_ALTA", "Departamento_ALTA", "external_id", "CIERRE_AV", "APERTURA_AV"}),
    Changed_Type = Table.TransformColumnTypes(Replaced_NULL_null,{{"XA_ACTUACION_ALTA", type text}, {"Pet_atis_ALTA", type text}, {"PRODUCTO", type text}, {"Medio_de_Acceso_ALTA", type text}, {"Departamento_ALTA", type text}, {"Fecha_de_cierre_final_ALTA", type date}, {"external_id", type text}, {"CIERRE_AV", type text}, {"APERTURA_AV", type text}}),
    Trimmed_Text = Table.TransformColumns(Changed_Type,{{"XA_ACTUACION_ALTA", Text.Trim, type text}, {"Pet_atis_ALTA", Text.Trim, type text}, {"PRODUCTO", Text.Trim, type text}, {"Medio_de_Acceso_ALTA", Text.Trim, type text}, {"Departamento_ALTA", Text.Trim, type text}, {"external_id", Text.Trim, type text}, {"CIERRE_AV", Text.Trim, type text}, {"APERTURA_AV", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"XA_ACTUACION_ALTA", Text.Clean, type text}, {"Pet_atis_ALTA", Text.Clean, type text}, {"PRODUCTO", Text.Clean, type text}, {"Medio_de_Acceso_ALTA", Text.Clean, type text}, {"Departamento_ALTA", Text.Clean, type text}, {"external_id", Text.Clean, type text}, {"CIERRE_AV", Text.Clean, type text}, {"APERTURA_AV", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Departamento_ALTA", Text.Proper, type text}}),
    Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"Departamento_ALTA", "Departamento"}, {"XA_ACTUACION_ALTA", "ATiempo"}, {"Pet_atis_ALTA", "Atis"}, {"Fecha_de_cierre_final_ALTA", "Fecha"}}),
    Filtered_Null_Atis = Table.SelectRows(Renamed_Columns, each [Atis] <> null and [Atis] <> ""),
    Filtered_Null_CC_Tec = Table.SelectRows(Filtered_Null_Atis, each [external_id] <> null and [external_id] <> ""),
    Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_CC_Tec, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
    Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
    Added_No_Cumple = Table.AddColumn(Removed_Columns, "No Cumple", each 1, type number),
    Added_Productos = Table.AddColumn(Added_No_Cumple, "Productos", each if([PRODUCTO]="DUO") and ([Medio_de_Acceso_ALTA]="FIBRA") then("FTTH") else(if([Medio_de_Acceso_ALTA]="COBRE") and (([PRODUCTO]="DUO") or ([PRODUCTO]="LB"))then("LB+BA")else([PRODUCTO])), type text),
    Replaced_IPTV = Table.ReplaceValue(Added_Productos,"IP_TV","TV (IPTV)",Replacer.ReplaceText,{"Productos"}),
    Removed_Duplicates = Table.Distinct(Replaced_IPTV),
    Removed_Other_Columns_Fin = Table.SelectColumns(Removed_Duplicates,{"ATiempo", "Atis", "Departamento", "Fecha", "external_id", "Año", "Mes", "No Cumple", "Productos"}),
    Appended_Altas_Mes_Ant = Table.Combine({Removed_Other_Columns_Fin, Altas_Mes_Anterior}),
    Replaced_Null_Cumple_No_Cumple = Table.ReplaceValue(Appended_Altas_Mes_Ant,null,0,Replacer.ReplaceValue,{"No Cumple", "Cumple"}),
    Added_Aperturas = Table.AddColumn(Replaced_Null_Cumple_No_Cumple, "Aperturas", each "Cumplimiento de averías de infancia", type text)
    in
        Added_Aperturas,
ISN_Alta = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".txt")),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\ISN_Altas\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], "_", ".", 1, 0), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", "_"), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Csv.Document(_,[Delimiter="Õ", Columns=11, Encoding=1252, QuoteStyle=QuoteStyle.None])}),
    Expanded_Content = Transform_Content{0}[Content],
    Filtered_Separador = Table.SelectRows(Expanded_Content, each not Text.Contains([Column1], "-")),
    Filtered_Null_Column2 = Table.SelectRows(Filtered_Separador, each [Column2] <> null and [Column2] <> ""),
    Promoted_Headers = Table.PromoteHeaders(Filtered_Null_Column2, [PromoteAllScalars=true]),
    Removed_Other_Columns = Table.SelectColumns(Promoted_Headers,{"Departamento", "Num Empleado", "Pregunta3", "conteo", "MES_ENCUESTA", "AÑO_ENCUESTA"}),
    Changed_Type = Table.TransformColumnTypes(Removed_Other_Columns,{{"Departamento", type text}, {"Num Empleado", type text}, {"Pregunta3", type text}, {"conteo", Int64.Type}, {"MES_ENCUESTA", Int64.Type}, {"AÑO_ENCUESTA", Int64.Type}}),
    Trimmed_Text = Table.TransformColumns(Changed_Type,{{"Departamento", Text.Trim, type text}, {"Num Empleado", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Departamento", Text.Clean, type text}, {"Num Empleado", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Departamento", Text.Proper, type text}}),
    Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"Num Empleado", "external_id"}, {"conteo", "Cantidad"}, {"MES_ENCUESTA", "Mes"}, {"AÑO_ENCUESTA", "Año"}}),
    Filtered_Null_CC_Tec = Table.SelectRows(Renamed_Columns, each [external_id] <> null and [external_id] <> ""),
    Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_CC_Tec, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
    Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
    Pivoted_Pregunta3 = Table.Pivot(Removed_Columns, List.Distinct(Removed_Columns[Pregunta3]), "Pregunta3", "Cantidad", List.Sum),
    Replaced_Null_01 = try(Table.ReplaceValue(Pivoted_Pregunta3,null,0,Replacer.ReplaceValue,{"1"})) otherwise (Table.AddColumn(Pivoted_Pregunta3, "1", each 0, type number)),
    Replaced_Null_02 = try(Table.ReplaceValue(Replaced_Null_01,null,0,Replacer.ReplaceValue,{"2"})) otherwise (Table.AddColumn(Replaced_Null_01, "2", each 0, type number)),
    Replaced_Null_03 = try(Table.ReplaceValue(Replaced_Null_02,null,0,Replacer.ReplaceValue,{"3"})) otherwise (Table.AddColumn(Replaced_Null_02, "3", each 0, type number)),
    Replaced_Null_04 = try(Table.ReplaceValue(Replaced_Null_03,null,0,Replacer.ReplaceValue,{"4"})) otherwise (Table.AddColumn(Replaced_Null_03, "4", each 0, type number)),
    Replaced_Null_05 = try(Table.ReplaceValue(Replaced_Null_04,null,0,Replacer.ReplaceValue,{"5"})) otherwise (Table.AddColumn(Replaced_Null_04, "5", each 0, type number)),
    Added_Cumple = Table.AddColumn(Replaced_Null_05, "Cumple", each [4] + [5], type number),
    Added_No_Cumple = Table.AddColumn(Added_Cumple, "No Cumple", each [1] + [2], type number),
    Added_Total = Table.AddColumn(Added_No_Cumple, "Total", each List.Sum({[1], [2], [3], [4], [5]}), type number),
    Added_Aperturas = Table.AddColumn(Added_Total, "Aperturas", each "ISN", type text),
    Added_Productos = Table.AddColumn(Added_Aperturas, "Productos", each "TOTAL", type text),
    Removed_Duplicates = Table.Distinct(Added_Productos),
    Removed_Columns_Numero = Table.RemoveColumns(Removed_Duplicates,{"3", "5", "2", "4", "1"})
    in
        Removed_Columns_Numero,
ISN_Mtto = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".txt")),
    Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\ISN_Mtto\")),
    Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], "_", ".", 1, 0), type text),
    Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", "_"), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
    Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Csv.Document(_,[Delimiter="Õ", Columns=10, Encoding=1252, QuoteStyle=QuoteStyle.None])}),
    Expanded_Content = Transform_Content{0}[Content],
    Filtered_Separador = Table.SelectRows(Expanded_Content, each not Text.Contains([Column1], "-")),
    Filtered_Null_Column2 = Table.SelectRows(Filtered_Separador, each [Column2] <> null and [Column2] <> ""),
    Promoted_Headers = Table.PromoteHeaders(Filtered_Null_Column2, [PromoteAllScalars=true]),
    Removed_Other_Columns = Table.SelectColumns(Promoted_Headers,{"Departamento", "Num Empleado", "Pregunta3", "CONTEO", "MES_ENCUESTA", "AÑO_ENCUESTA"}),
    Changed_Type = Table.TransformColumnTypes(Removed_Other_Columns,{{"Departamento", type text}, {"Num Empleado", type text}, {"Pregunta3", type text}, {"CONTEO", Int64.Type}, {"MES_ENCUESTA", Int64.Type}, {"AÑO_ENCUESTA", Int64.Type}}),
    Trimmed_Text = Table.TransformColumns(Changed_Type,{{"Departamento", Text.Trim, type text}, {"Num Empleado", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Departamento", Text.Clean, type text}, {"Num Empleado", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Departamento", Text.Proper, type text}}),
    Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"Num Empleado", "external_id"}, {"CONTEO", "Cantidad"}, {"MES_ENCUESTA", "Mes"}, {"AÑO_ENCUESTA", "Año"}}),
    Filtered_Null_CC_Tec = Table.SelectRows(Renamed_Columns, each [external_id] <> null and [external_id] <> ""),
    Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_CC_Tec, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
    Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
    Pivoted_Pregunta3 = Table.Pivot(Removed_Columns, List.Distinct(Removed_Columns[Pregunta3]), "Pregunta3", "Cantidad", List.Sum),
    Replaced_Null_01 = try(Table.ReplaceValue(Pivoted_Pregunta3,null,0,Replacer.ReplaceValue,{"1"})) otherwise (Table.AddColumn(Pivoted_Pregunta3, "1", each 0, type number)),
    Replaced_Null_02 = try(Table.ReplaceValue(Replaced_Null_01,null,0,Replacer.ReplaceValue,{"2"})) otherwise (Table.AddColumn(Replaced_Null_01, "2", each 0, type number)),
    Replaced_Null_03 = try(Table.ReplaceValue(Replaced_Null_02,null,0,Replacer.ReplaceValue,{"3"})) otherwise (Table.AddColumn(Replaced_Null_02, "3", each 0, type number)),
    Replaced_Null_04 = try(Table.ReplaceValue(Replaced_Null_03,null,0,Replacer.ReplaceValue,{"4"})) otherwise (Table.AddColumn(Replaced_Null_03, "4", each 0, type number)),
    Replaced_Null_05 = try(Table.ReplaceValue(Replaced_Null_04,null,0,Replacer.ReplaceValue,{"5"})) otherwise (Table.AddColumn(Replaced_Null_04, "5", each 0, type number)),
    Added_Cumple = Table.AddColumn(Replaced_Null_05, "Cumple", each [4] + [5], type number),
    Added_No_Cumple = Table.AddColumn(Added_Cumple, "No Cumple", each [1] + [2], type number),
    Added_Total = Table.AddColumn(Added_No_Cumple, "Total", each List.Sum({[1], [2], [3], [4], [5]}), type number),
    Added_Aperturas = Table.AddColumn(Added_Total, "Aperturas", each "ISN MTTO", type text),
    Added_Productos = Table.AddColumn(Added_Aperturas, "Productos", each "TOTAL", type text),
    Removed_Duplicates = Table.Distinct(Added_Productos),
    Removed_Columns_Numero = Table.RemoveColumns(Removed_Duplicates,{"3", "5", "2", "4", "1"})
    in
        Removed_Columns_Numero,
Cuadrillas_Bonificacion = let
    Source = AccesosCuadrillas_2,
    Removed_Date = Table.RemoveColumns(Source,{"Fecha"}),
    Removed_Duplicates = Table.Distinct(Removed_Date),
    Grouped_Rows = Table.Group(Removed_Duplicates, {"CCTec", "Acceso", "Cargo", "Departamento", "Año", "Mes"}, {{"Lineas", each Table.RowCount(_), Int64.Type}, {"All", each _, type table [CCTec=nullable text, Acceso=nullable text, Cargo=text, Departamento=text, Contrata=text, Nom Tec=text, Nom Gestor=text, Nom Super=text, Area Cuadri=text, ApuCuadrilla=nullable number, Año=number, Mes=number]}}),
    Expanded_All = Table.ExpandTableColumn(Grouped_Rows, "All", {"Contrata", "Nom Tec", "Nom Gestor", "Nom Super", "Area Cuadri", "ApuCuadrilla"}, {"Contrata", "Nom Tec", "Nom Gestor", "Nom Super", "Area Cuadri", "ApuCuadrilla"})
    in
        Expanded_All,
Consolidado_Produccion = let
    Source = Cuadrillas,
    Merged_Produccion = Table.NestedJoin(Source, {"Dep Cuadri", "CC Tec", "Fecha"}, Produccion, {"Departamento", "CC Tec", "Fecha"}, "Produccion", JoinKind.LeftOuter),
    Expanded_Produccion = Table.ExpandTableColumn(Merged_Produccion, "Produccion", {"Atiempo", "Atis", "Tipo Orden", "Tipo Tarea", "Departamento", "Medio de Acceso", "Baremos", "Actividades", "Recuento", "DiaTrabajado"}, {"Atiempo", "Atis", "Tipo Orden", "Tipo Tarea", "Departamento", "Medio de Acceso", "Baremos", "Actividades", "Recuento", "DiaTrabajado"}),
    Merged_Homologa_Area = Table.NestedJoin(Expanded_Produccion, {"AreaCuadri", "Año", "Mes"}, Hom_Area_Valor, {"Area", "Año", "Mes"}, "HomAreaVal", JoinKind.LeftOuter),
    Expanded_Homologado_Area = Table.ExpandTableColumn(Merged_Homologa_Area, "HomAreaVal", {"Valor", "Valor Tec", "Valor Admin"}, {"Valor", "Valor Tec", "Valor Admin"}),
    Added_Bar_Tec = Table.AddColumn(Expanded_Homologado_Area, "$Bar Tec", each [Baremos]*[Valor Tec], type number),
    Added_Bar_admin = Table.AddColumn(Added_Bar_Tec, "$Bar Admin", each [Baremos]*[Valor Admin], type number),
    Added_Trabajado = Table.AddColumn(Added_Bar_admin, "Trabajado", each if([AreaCuadri]="Instalaciones")then([Baremos]+([Actividades]*[Valor]))else([Actividades]+([Baremos]*[Valor])), type number),
    Added_Meta_Dia = Table.AddColumn(Added_Trabajado, "Meta Dia", each if([Habil]="Habil")then([MetaMes]/[Habiles]/[Recuento])else(0), type number),
    Added_Real_Meta_Dia = Table.AddColumn(Added_Meta_Dia, "RealMetaDia", each if([Habil]="Habil")then(if([Cargo]="Supervisor")then(if([AreaCuadri]="MANTENIMIENTO")then([MetaMes])else([Meta Dia]))else([Meta Dia]))else(0), type number),
    Added_Meta_Mostrar = Table.AddColumn(Added_Real_Meta_Dia, "MetaMostrar", each if([Cargo]="Tecnico")then(if([Pre.MetaMostrar]=null)then([RealMetaDia])else([Pre.MetaMostrar]))else([RealMetaDia]), type number),
    Removed_Other_Columns = Table.SelectColumns(Added_Meta_Mostrar,{"Contrata", "Dep Cuadri", "AreaCuadri", "CC Tec", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Nom Aux", "CC Aux", "Fecha", "Año", "Mes", "Habiles", "Habil", "Tipo Empresa", "Acceso", "Cargo", "ApuCuadrilla", "BonoCuadrilla", "IncrementoBono", "MetaMes", "Salario", "Max Porc Bono", "Parte Presta", "Parte Cuadri 2 Per", "Aux.Salario", "Aux.Max Porc Bono", "Aux.Parte Presta", "Aux.Parte Cuadri 2 Per", "Atiempo", "Atis", "Tipo Orden", "Tipo Tarea", "Departamento", "Medio de Acceso", "Baremos", "Actividades", "Recuento", "DiaTrabajado", "Valor Admin", "$Bar Tec", "$Bar Admin", "Trabajado", "Meta Dia", "RealMetaDia", "MetaMostrar"}),
    Merged_Calidad_IM = Table.NestedJoin(Removed_Other_Columns, {"Atis"}, Calidad_I_M, {"Pet_atis"}, "Calidad_I_M", JoinKind.LeftOuter),
    Expanded_Calidad_IM = Table.ExpandTableColumn(Merged_Calidad_IM, "Calidad_I_M", {"APERTURA_AV", "CIERRE_AV", "Excluir"}, {"Calidad_I_M.APERTURA_AV", "Calidad_I_M.CIERRE_AV", "Calidad_I_M.Excluir"}),
    Replaced_Null_Excluir = Table.ReplaceValue(Expanded_Calidad_IM,null,"Nada",Replacer.ReplaceValue,{"Calidad_I_M.Excluir"}),
    Added_Afecta_Calidad = Table.AddColumn(Replaced_Null_Excluir, "Afecta Calidad", each if([Calidad_I_M.Excluir]="NO")then("Afecta")else("No Afecta"), type text),
    Added_Puntos_Colombia = Table.AddColumn(Added_Afecta_Calidad, "Puntos Colombia", each if([Tipo Orden]="AVERIA")then([Actividades]*1.3)else([Baremos]), type number),
    Added_Dia_No_Tabaja = Table.AddColumn(Added_Puntos_Colombia, "DiaNoTrabajo", each if([Habil]="Habil")and([DiaTrabajado]=null)then(1)else(0), type number),
    Replaced_Null_Dep = Table.ReplaceValue(Added_Dia_No_Tabaja,null,each [Dep Cuadri],Replacer.ReplaceValue,{"Departamento"})
    in
        Replaced_Null_Dep,
Detalle_Bonificacion = let
    Source = Table.Combine({Cumplimiento_Citas, Plazo_3_Dias, Plazos, Reitero, Infancia, ISN_Alta, ISN_Mtto}),
    Indicadores = Tabla_Indicadores,
    Merged_Source = Table.NestedJoin(Indicadores, {"Aperturas", "Productos", "Año", "Mes"}, Source, {"Aperturas", "Productos", "Año", "Mes"}, "IndicadoresEstado", JoinKind.LeftOuter),
    Expanded_Source = Table.ExpandTableColumn(Merged_Source, "IndicadoresEstado", {"Fecha", "Atis", "Departamento", "ATiempo", "external_id", "Cumple", "No Cumple", "Total"}, {"Fecha", "Atis", "Departamento", "ATiempo", "external_id", "Cumple", "No Cumple", "Total"}),
    Replaced_No_Cumple = Table.ReplaceValue(Expanded_Source,0, each if(([Año]=2023)and([Mes]=1)and([Corto]="Inf LBBA"))then([Nota 75])else(0),Replacer.ReplaceValue,{"No Cumple"}),
    Replaced_Cumple = Table.ReplaceValue(Replaced_No_Cumple,0, each if(([Año]=2023)and([Mes]=1)and([Corto]="Inf LBBA"))then(1)else(0),Replacer.ReplaceValue,{"Cumple"}),
    Changed_Type_Cumple_Y_No = Table.TransformColumnTypes(Replaced_Cumple,{{"Cumple", type number}, {"No Cumple", type number}}),
    Merged_Parametro_Nota = Table.NestedJoin(Changed_Type_Cumple_Y_No, {"Año", "Mes"}, Parametro_Nota, {"Año", "Mes"}, "Parametro_Nota", JoinKind.LeftOuter),
    Expanded_Parametro_Nota = Table.ExpandTableColumn(Merged_Parametro_Nota, "Parametro_Nota", {"VrPenalAlta", "VrPenalMtto"}, {"VrPenalAlta", "VrPenalMtto"}),
    Added_Mes_Año = Table.AddColumn(Expanded_Parametro_Nota, "Mes Año", each Text.From([Mes]) & " " & Text.From([Año]), type text),
    Merged_Accesos = Table.NestedJoin(Added_Mes_Año, {"external_id", "Año", "Mes", "Departamento"}, Cuadrillas_Bonificacion, {"CCTec", "Año", "Mes", "Departamento"}, "AccesosCuadrillas", JoinKind.LeftOuter),
    ExpandedAccesos =  Table.ExpandTableColumn(Merged_Accesos, "AccesosCuadrillas", {"Acceso", "Cargo", "Lineas", "Contrata", "Nom Tec", "Nom Gestor", "Nom Super"}, {"Acceso", "Cargo", "Lineas", "Contrata", "Nom Tec", "Nom Gestor", "Nom Super"}),
    Replaced_Null_Lineas = Table.ReplaceValue(ExpandedAccesos,null,1,Replacer.ReplaceValue,{"Lineas"}),
    Inserted_Division_Cumple = Table.AddColumn(Replaced_Null_Lineas, "Cumple_2", each [Cumple] / [Lineas], type number),
    Inserted_Division_No_Cumple = Table.AddColumn(Inserted_Division_Cumple, "No Cumple_2", each [No Cumple] / [Lineas], type number),
    Removed_Original_Cumple_y_No = Table.RemoveColumns(Inserted_Division_No_Cumple,{"Cumple", "No Cumple", "Lineas"}),
    Renamed_Columns_Cumple_y_No = Table.RenameColumns(Removed_Original_Cumple_y_No,{{"Cumple_2", "Cumple"}, {"No Cumple_2", "No Cumple"}}),
    Replaced_Null_Cargo = Table.ReplaceValue(Renamed_Columns_Cumple_y_No,null,"Admin",Replacer.ReplaceValue,{"Cargo"}),
    Replaced_Null_Acceso = Table.ReplaceValue(Replaced_Null_Cargo,null,"9999999999",Replacer.ReplaceValue,{"Acceso"}),
    Replaced_Null_Cuadrillas = Table.ReplaceValue(Replaced_Null_Acceso,null,"Liteyca",Replacer.ReplaceValue,{"Nom Gestor", "Nom Super", "Nom Tec", "Contrata"}),
    Removed_Duplicates = Table.Distinct(Replaced_Null_Cuadrillas),
    Filtered__Null_No_Cumple = Table.SelectRows(Removed_Duplicates, each [No Cumple] <> "" or [No Cumple] <> null),
    Grouped_Rows_No_Cumple = Table.Group(Filtered__Null_No_Cumple, {"Aperturas", "Productos", "Departamento", "Acceso", "Año", "Mes"}, {{"Penaliza", each List.Average([Penaliza]), type nullable number}, {"PesoPenaliza", each List.Average([PesoPenaliza]), type nullable number}, {"Cumple", each List.Sum([Cumple]), type nullable number}, {"NoCumple", each List.Sum([No Cumple]), type nullable number}, {"Total", each List.Sum([Total]), type nullable number}, {"VrPenalAlta", each List.Average([VrPenalAlta]), type nullable number}, {"VrPenalMtto", each List.Average([VrPenalMtto]), type nullable number}, {"All", each _, type table [Aperturas=text, Productos=text, Nota 0=nullable number, Nota 75=nullable number, Nota 10=nullable number, Penaliza=nullable number, PesoPenaliza=nullable number, PESO=nullable number, Sin Nota=nullable number, Corto=nullable text, Año=nullable number, Mes=nullable number, Fecha=nullable date, Atis=nullable text, Departamento=nullable text, ATiempo=nullable text, external_id=nullable text, Cumple=nullable number, No Cumple=nullable number, Total=nullable number, VrPenalAlta=nullable number, VrPenalMtto=nullable number, Mes Año=text, Nom Gestor=nullable text, Nom Super=nullable text, Acceso=nullable text, Cargo=nullable text, Nom Tec=nullable text, Contrata=nullable text]}}),
    Added_Cumplimiento_No_Cumple = Table.AddColumn(Grouped_Rows_No_Cumple, "%Cumplimiento", each if([Aperturas]="ISN") or([Aperturas]="ISN MTTO")then(([Cumple]/[Total])-([NoCumple]/[Total]))else(if([Aperturas]="Cumplimiento de averías de infancia") or([Aperturas]="Averías reiteradas")then(if(([Cumple]+[NoCumple])=0)then(null)else(if([Cumple]=0)then(1)else([NoCumple]/[Cumple])))else([Cumple]/([Cumple]+[NoCumple]))), type number),
    Added_Cant_Penalizada = Table.AddColumn(Added_Cumplimiento_No_Cumple, "Cant Penailzada", each if([Penaliza]=null)then(0)else(if([Aperturas]="ISN")then([NoCumple]*[PesoPenaliza])else(if([Aperturas]="Cumplimiento de citas")then(if([#"%Cumplimiento"]>=[Penaliza])then(0)else([NoCumple]*[PesoPenaliza]))else(if([Aperturas]="Plazos de Mtto")then(if([#"%Cumplimiento"]>=[Penaliza])then(0)else([NoCumple]-([PesoPenaliza]*([Cumple]+[NoCumple]))))else(if([#"%Cumplimiento"]<=[Penaliza])then(0)else([NoCumple]-([PesoPenaliza]*[Cumple])))))), type number),
    Removed_Other_Columns_No_Cumple = Table.SelectColumns(Added_Cant_Penalizada,{"Aperturas", "Productos", "Departamento", "Acceso", "Año", "Mes", "Penaliza", "PesoPenaliza", "VrPenalAlta", "VrPenalMtto", "All", "%Cumplimiento", "Cant Penailzada"}),
    Expanded_All = Table.ExpandTableColumn(Removed_Other_Columns_No_Cumple, "All", {"Nota 0", "Nota 75", "Nota 10", "PESO", "Sin Nota", "Corto", "Fecha", "Atis", "ATiempo", "external_id", "Cumple", "No Cumple", "Total", "Mes Año", "Nom Gestor", "Nom Super", "Cargo", "Nom Tec", "Contrata"}, {"Nota 0", "Nota 75", "Nota 10", "PESO", "Sin Nota", "Corto", "Fecha", "Atis", "ATiempo", "external_id", "Cumple", "No Cumple", "Total", "Mes Año", "Nom Gest", "Nom Super", "Cargo", "Nom Tec", "Contrata"}),
    Filtered_Rows_No_Cumple = Table.SelectRows(Expanded_All, each [No Cumple] <> 0),
    Added_Index = Table.AddIndexColumn(Filtered_Rows_No_Cumple, "Índice", 1, 1, Int64.Type),
    Added_Es_Penalizada_No_Cumple = Table.AddColumn(Added_Index, "Es Penalizada", each if([Cant Penailzada]=null)then(false)else(if([Índice]<=[Cant Penailzada])then(true)else(false)), type logical),
    Removed_Other_Columns_No_Cumple_Final = Table.SelectColumns(Added_Es_Penalizada_No_Cumple,{"Aperturas", "Productos", "Departamento", "Acceso", "Año", "Mes", "Penaliza", "PesoPenaliza", "VrPenalAlta", "VrPenalMtto", "Nota 0", "Nota 75", "Nota 10", "PESO", "Sin Nota", "Corto", "Fecha", "Atis", "ATiempo", "external_id", "Cumple", "No Cumple", "Total", "Mes Año", "Nom Gest", "Nom Super", "Cargo", "Nom Tec", "Es Penalizada"}),
    Filtered_Rows_Cumple = Table.SelectRows(Expanded_All, each [No Cumple] = 0),
    Added_Es_Penalizada_Cumple = Table.AddColumn(Filtered_Rows_Cumple, "Es Penalizada", each false, type logical),
    Appended_Querys = Table.Combine({Added_Es_Penalizada_Cumple, Removed_Other_Columns_No_Cumple_Final}),
    Errores_Reemplazados = Table.ReplaceErrorValues(Appended_Querys, {{"Es Penalizada", false}})
    in
        Errores_Reemplazados,
Indicador_Logistica = let
    Source = Table.Combine({Indicador_Odisea, Series_Siscos}),
    Added_Cant_Cumple = Table.AddColumn(Source, "CanCumple", each if([Indicador]="Cumple")then(0)else(1), type number),
    Removed_Other_Columns = Table.SelectColumns(Added_Cant_Cumple,{"CC Tec", "Año", "Mes", "Indicador Log", "CanCumple"}),
    Removed_Duplicates = Table.Distinct(Removed_Other_Columns),
    Pivoted_Indicador_Log = Table.Pivot(Removed_Duplicates, List.Distinct(Removed_Duplicates[#"Indicador Log"]), "Indicador Log", "CanCumple", List.Sum),
    Replaced_Null_Odisea = try(Table.ReplaceValue(Pivoted_Indicador_Log,null,0,Replacer.ReplaceValue,{"Odisea"}))otherwise(Table.AddColumn(Pivoted_Indicador_Log, "Odisea", each 0, type number)),
    Replaced_Null_Rotacion = try(Table.ReplaceValue(Replaced_Null_Odisea,null,0,Replacer.ReplaceValue,{"Rotacion"}))otherwise(Table.AddColumn(Replaced_Null_Odisea, "Rotacion", each 0, type number)),
    Replaced_Null_Reintegro = try(Table.ReplaceValue(Replaced_Null_Rotacion,null,0,Replacer.ReplaceValue,{"Reintegro"}))otherwise(Table.AddColumn(Replaced_Null_Rotacion, "Reintegro", each 0, type number)),
    Added_Logistica = Table.AddColumn(Replaced_Null_Reintegro, "Logistica", each if(([Odisea]+[Rotacion]+[Reintegro])=0)then(0)else(1), type number),
    Unpivoted_Indicador_Log = Table.Unpivot(Added_Logistica, {"Odisea", "Rotacion", "Reintegro", "Logistica"}, "Indicador Log", "Estado Indicador"),
    Added_Estado = Table.AddColumn(Unpivoted_Indicador_Log, "Estado", each if [Estado Indicador] = 0 then "Cumple" else "No Cumple", type text),
    Removed_Estado_Indicador = Table.RemoveColumns(Added_Estado,{"Estado Indicador"}),
    Merged_Accesos = Table.NestedJoin(Removed_Estado_Indicador, {"CC Tec", "Año", "Mes"}, Cuadrillas_Bonificacion, {"CCTec", "Año", "Mes"}, "AccesosCuadrillas", JoinKind.LeftOuter),
    Expanded_Accesos = Table.ExpandTableColumn(Merged_Accesos, "AccesosCuadrillas", {"Acceso", "Cargo"}, {"Acceso", "Cargo"}),
    Replaced_Null_Acceso = Table.ReplaceValue(Expanded_Accesos,null,"9999999999",Replacer.ReplaceValue,{"Acceso"}),
    Replaced_Null_Cargo = Table.ReplaceValue(Replaced_Null_Acceso,null,"Admin",Replacer.ReplaceValue,{"Cargo"}),
    Removed_Duplicates_Final = Table.Distinct(Replaced_Null_Cargo),
    Removed_Other_Columns_Final = Table.SelectColumns(Removed_Duplicates_Final,{"CC Tec", "Año", "Mes", "Indicador Log", "Estado", "Acceso", "Cargo"})
    in
        Removed_Other_Columns_Final,
Detalles_Logistica = let
    Source = Table.Combine({Indicador_Odisea, Series_Siscos}),
    Filtered_Indicador_No_Cumple = Table.SelectRows(Source, each ([Indicador] = "No Cumple")),
    Merged_Accesos = Table.NestedJoin(Filtered_Indicador_No_Cumple, {"CC Tec", "Año", "Mes"}, Cuadrillas_Bonificacion, {"CCTec", "Año", "Mes"}, "AccesosCuadrillas", JoinKind.LeftOuter),
    Expanded_Accesos = Table.ExpandTableColumn(Merged_Accesos, "AccesosCuadrillas", {"Acceso", "Cargo"}, {"Acceso", "Cargo"}),
    Replaced_Null_Acceso = Table.ReplaceValue(Expanded_Accesos,null,"9999999999",Replacer.ReplaceValue,{"Acceso"}),
    Replaced_Null_Cargo = Table.ReplaceValue(Replaced_Null_Acceso,null,"Admin",Replacer.ReplaceValue,{"Cargo"}),
    Removed_Duplicates = Table.Distinct(Replaced_Null_Cargo)
    in
        Removed_Duplicates,
Rangos_Tesa = let
    Source = Produccion,
    Removed_Columns = Table.RemoveColumns(Source,{"AreaCuadri"}),
    Inserted_Year = Table.AddColumn(Removed_Columns, "Año", each Date.Year([Fecha]), Int64.Type),
    Inserted_Month = Table.AddColumn(Inserted_Year, "Mes", each Date.Month([Fecha]), Int64.Type),
    Merged_Cuadrillas = Table.NestedJoin(Inserted_Month, {"CC Tec", "Fecha"}, Cuadrillas, {"CC Tec", "Fecha"}, "Cuadrillas", JoinKind.LeftOuter),
    Expanded_Cuadrillas = Table.ExpandTableColumn(Merged_Cuadrillas, "Cuadrillas", {"AreaCuadri", "Contrata", "Dep Cuadri", "Nom Gestor", "Nom Super"}, {"AreaCuadri", "Contrata", "Dep Cuadri", "Nom Gestor", "Nom Super"}),
    Replaced_Null_Columns = Table.ReplaceValue(Expanded_Cuadrillas,null,"Liteyca",Replacer.ReplaceValue,{"Nom Gestor", "Nom Super", "AreaCuadri", "Contrata"}),
    Replaced_Null_Dep_Cuadri_to_Departamento = Table.ReplaceValue(Replaced_Null_Columns,null, each [Departamento],Replacer.ReplaceValue,{"Dep Cuadri"}),
    Added_Area = Table.AddColumn(Replaced_Null_Dep_Cuadri_to_Departamento, "Area", each if [Tipo Orden] = "AVERIA" then "Mantenimiento" else "Instalaciones", type text),
    Select_Columns = Table.SelectColumns(Added_Area,{"Departamento", "CC Tec", "Fecha", "Año", "Mes", "AreaCuadri", "Contrata", "Dep Cuadri", "Nom Gestor", "Nom Super", "Area"}),
    Removed_Duplicates = Table.Distinct(Select_Columns),
    Grouped_Rows_Dias_Tabajo = Table.Group(Removed_Duplicates, {"Departamento", "Area", "CC Tec", "Año", "Mes", "Nom Gestor", "Nom Super", "AreaCuadri", "Dep Cuadri", "Contrata"}, {{"Dias Trabajado", each Table.RowCount(_), Int64.Type}}),
    Added_Puntos_Base_Added_Area = Table.AddColumn(Added_Area, "Puntos", each if [Area] = "Instalaciones" then [Baremos] else [Actividades]* 1.3, type number),
    Grouped_Rows_Puntos = Table.Group(Added_Puntos_Base_Added_Area, {"Departamento", "Area", "CC Tec", "Año", "Mes", "Nom Gestor", "Nom Super", "AreaCuadri", "Dep Cuadri", "Contrata"}, {{"Puntos", each List.Sum([Puntos]), type number}}),
    Merged_Group_Dias_Tabajo = Table.NestedJoin(Grouped_Rows_Puntos, {"Departamento", "Area", "CC Tec", "Año", "Mes", "Nom Gestor", "Nom Super", "AreaCuadri", "Dep Cuadri", "Contrata"}, Grouped_Rows_Dias_Tabajo, {"Departamento", "Area", "CC Tec", "Año", "Mes", "Nom Gestor", "Nom Super", "AreaCuadri", "Dep Cuadri", "Contrata"}, "RangosTesa", JoinKind.LeftOuter),
    Expanded_Dias_Trabajo = Table.ExpandTableColumn(Merged_Group_Dias_Tabajo, "RangosTesa", {"Dias Trabajado"}, {"Dias Trabajado"}),
    Added_Diario_Puntos = Table.AddColumn(Expanded_Dias_Trabajo, "Diario Puntos", each [Puntos]/[Dias Trabajado], type number),
    Merged_Limites_Rangos_Tesa = Table.NestedJoin(Added_Diario_Puntos, {"AreaCuadri", "Año", "Mes"}, Limites_Rangos_Tesa, {"Area", "Año", "Mes"}, "Limites_Rangos_Tesa", JoinKind.LeftOuter),
    Expanded_Limites_Rangos_Tesa = Table.ExpandTableColumn(Merged_Limites_Rangos_Tesa, "Limites_Rangos_Tesa", {"Valor Alto", "Valor Bajo"}, {"Valor Alto", "Valor Bajo"}),
    Replaced_Null_Valor_Alto = Table.ReplaceValue(Expanded_Limites_Rangos_Tesa,null,7.5,Replacer.ReplaceValue,{"Valor Alto"}),
    Replaced_Null_Valor_Bajo = Table.ReplaceValue(Replaced_Null_Valor_Alto,null,6.5,Replacer.ReplaceValue,{"Valor Bajo"}),
    Added_Clasificacion = Table.AddColumn(Replaced_Null_Valor_Bajo, "Clasificacion", each if [Diario Puntos] >= [Valor Alto] then "Alto" else if [Diario Puntos] <= [Valor Bajo] then "Bajo" else "Medio", type text),
    Added_Clasificacion_Insta = Table.AddColumn(Added_Clasificacion, "ClasificacionInsta", each if [Diario Puntos] >= [Valor Alto] then "Alto" else if [Diario Puntos] <= [Valor Bajo] then "Bajo" else "Medio", type text),
    Added_Orden = Table.AddColumn(Added_Clasificacion_Insta, "Orden", each if [Clasificacion] = "Bajo" then 1 else if [Clasificacion] = "Medio" then 2 else if [Clasificacion] = "Alto" then 3 else 4, type number),
    Added_Mes_Año = Table.AddColumn(Added_Orden, "Mes Año", each Text.From([Año]) & " " & Text.From([Mes]), type text),
    Merged_Acceso_Cuadrillas = Table.NestedJoin(Added_Mes_Año, {"CC Tec", "Año", "Mes"}, AccesosCuadrillas_2, {"CCTec", "Año", "Mes"}, "AccesosCuadrillas", JoinKind.LeftOuter),
    Expanded_Acceso_Cuadrillas = Table.ExpandTableColumn(Merged_Acceso_Cuadrillas, "AccesosCuadrillas", {"Acceso", "Cargo"}, {"Acceso", "Cargo"}),
    Replaced_Null_Acceso = Table.ReplaceValue(Expanded_Acceso_Cuadrillas,null,"9999999999",Replacer.ReplaceValue,{"Acceso"}),
    Replaced_Null_Cargo = Table.ReplaceValue(Replaced_Null_Acceso,null,"Admin",Replacer.ReplaceValue,{"Cargo"}),
    Removed_Duplicates_Final = Table.Distinct(Replaced_Null_Cargo)
    in
        Removed_Duplicates_Final
]