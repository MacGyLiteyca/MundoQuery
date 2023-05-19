let
    fxMyCalendario = (TablaEntrada as table, FechaInicial as date, FechaFinal as date) as table => let

    //Funcion de festivos
        fxFestivo =
        // Desarrollado por: Miguel Caballero & Fabian Torres: https://www.excelfreeblog.com/
        // La página utiliza internamente la web: https://www.cuandoenelmundo.com/
        let
            fxFestivo = let
            Funcion = (Pais as text, optional Inicio as number, optional Final as number) as table =>
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
                    FnDiasFestivos = (#"Año" as text) => 
                        let
                            ObtenerMetaDatos = Web.Page(Web.Contents("https://www.cuandoenelmundo.com/calendario/", [RelativePath = RemoverTildes(Text.Replace(Text.Trim(Text.Lower(pais)), " ", "-")) &"/" & #"Año"])), 
                            SeleccionarFestivos = Table.SelectRows(ObtenerMetaDatos, each [ClassName] = "hdays"), 
                            SeleccionarDatos = SeleccionarFestivos[Data], 
                            CombinarFilasFestivas = Table.Combine({SeleccionarDatos{0}, SeleccionarDatos{1}}), 
                            CrearColumnaDeFechasFestivas = Table.CombineColumns(CombinarFilasFestivas, {"Column1", "Column2"}, each _{0} & "/" & _{1} & "/" & #"Año", "Fecha"), 
                            CambiarTipo = Table.TransformColumnTypes(CrearColumnaDeFechasFestivas, {{"Fecha", type date}})
                        in
                            CambiarTipo,
                // Función interna #2.
                    RemoverTildes = (Texto as text) => 
                        let 
                            VocalesConAcentos = {"á", "é", "í", "ó", "ú"}, 
                            VocalesSinAcentos = {"a", "e", "i", "o", "u"}, 
                            PalabraSinAcentos = CicloDeSustitucion(Texto, 0), 
                            CicloDeSustitucion = (Palabra as text, x as number) => 
                                if x > 4 then Palabra else 
                                    let 
                                        s0 = Text.Replace(Palabra, VocalesConAcentos{x}, VocalesSinAcentos{x})
                                    in 
                                        @CicloDeSustitucion(s0, x + 1)
                        in
                            PalabraSinAcentos 
        in
            #"FINAL: Asginación de Tipo de Dato",
    
        //Documentacion de fxFestivo
        Documentacion = 
            type function (
                Pais as 
                    (type text meta[Documentation.AllowedValues = 
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
                optional Final as number
            ) 
        as 
            list meta[
                Documentation.Name = "Table.GenerateHoliDays", 
                Documentation.LongDescription = "Esta función genera una tabla con los días feriados o festivos para un país de iberoamérica, dado y un rango de años determinado, sino no se proprociona año de incio se generan los festivos para el año actual, si sólo se proporciona el año de inicio entonces se deuelven sólo los días fetivos para el año de inicio. La tabla de resultado cuenta con dos columnas: fecha y descripción. Creado por: | EXCELFREEBLOG.COM | para POWERQUERY.ZONE, Miguel Caballero & Fabian Torres.", 
                Documentation.Examples = 
                    {[
                        Description = "Generar las fechas festivas para el país Colombia y año en curso ", 
                        Code = "Table.GenerateHoliDays ( ""Colombia"" )", 
                        Result = "" 
                    ],
                    [
                        Description = "Generar las fechas festivas para el país panamá y año 2017 ", 
                        Code = "Table.GenerateHoliDays ( ""panamá"" , 2017 )", 
                        Result = "" 
                    ],
                    [
                        Description = "Generar las fechas festivas para el país México y del ano 2016 al 2021 ", 
                        Code = "Table.GenerateHoliDays ( ""México"" , 2016, 2021 )", 
                        Result = "" 
                    ],            
                    [
                        Description = "Para más ejemplos, visita:", 
                        Code = " POWERQUERY.ZONE/GENERAR-FESTIVOS ", 
                        Result = "" 
                    ]             
                },
                Documentation.Category = "Table", 
                Documentation.Source = "Local", 
                Documentation.Version = " 1.0 ", 
                Documentation.Author = "Miguel Caballero & Fabian Torres de: www.ExcelFreeBlog.Com"
            ]
        in
            Value.ReplaceType(Funcion, Documentacion)
        in
            fxFestivo,
    //Otros Pasos    
        
        FestivosExistentes = fxFestivo("Colombia", Date.Year(FechaInicial), Date.Year(FechaFinal)),
        Duracion = Duration.TotalDays(FechaFinal-FechaInicial)+1,
        ListaFechas = List.Dates(FechaInicial, Duracion, #duration(1,0,0,0)),
        ConvertedToTable = Table.FromList(ListaFechas, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        RenamedColumns = Table.RenameColumns(ConvertedToTable,{{"Column1", "Fecha"}}),
        ChangedTypeFecha = Table.TransformColumnTypes(RenamedColumns,{{"Fecha", type date}}),
        InsertedYear = Table.AddColumn(ChangedTypeFecha, "Año", each Date.Year([Fecha]), Int64.Type),
        InsertedMonth = Table.AddColumn(InsertedYear, "Mes", each Date.Month([Fecha]), Int64.Type),
        InsertedDayName = Table.AddColumn(InsertedMonth, "Nombre del día", each Date.DayOfWeekName([Fecha]), type text),
        MergedFestivos = Table.NestedJoin(InsertedDayName, {"Fecha"}, FestivosExistentes, {"Fecha"}, "Festivos", JoinKind.LeftOuter),
        ExpandedFestivos = Table.ExpandTableColumn(MergedFestivos, "Festivos", {"Descripción"}, {"Descripción"}),
        AddedHabil = Table.AddColumn(ExpandedFestivos, "Habil", each if([Nombre del día]="domingo")then("Festivo")else(if([Descripción]=null)then("Habil")else("Festivo")), type text)
    in
        AddedHabil
in
    fxMyCalendario