let
    MyRuta = Ruta,
//Ejemplo
    EjemploProduccionMantenimiento = 
        let
            Source = Folder.Files(MyRuta&"\DatasProduccionMantenimiento"),
            Navigation1 = Source{0}[Content]
        in
            Navigation1,
//Trasnformacion
    TransformaProduccionMantenimiento = 
        let
            Origen = (ParámetroProduccionMantenimiento as binary) => let
            //Como fuente es la carpeta de Producción Mantenimiento
                Source = Excel.Workbook(ParámetroProduccionMantenimiento, null, true),
            //Selección de la hoja en el excel BASE
                Data = Source{[Name="BASE"]}[Data],
            //Selección de hojas a utilizar
                RemovedOtherColumns = Table.SelectColumns(Data,{"Column5", "Column6", "Column7", "Column8", "Column13", "Column14", "Column15", "Column23"}),
            //Utiliza la primera como titulos
                PromotedHeaders = Table.PromoteHeaders(RemovedOtherColumns, [PromoteAllScalars=true]),
            //Se valida la columna de fecha para que sin importar el formato del excel logre tomar la fecha
                ValidarFecha = Table.TransformColumns(PromotedHeaders,{{"Fecha de Cierre", each Date.From(Value.FromText(_)), type date}}),
            //Selección de tipo de dato de las columnas
                ChangedType = Table.TransformColumnTypes(ValidarFecha,{{"Tipo_de_orden", type text}, {"Subtipo_de_orden", type text}, {"Pet_atis", type text}, {"Identificador_PC_Linea", type text}, {"external_id", type text}, {"Fecha de Cierre", type date}, {"Departamento", type text}}),
            //Se agrega la columna actividades que es un 1 para todas las filas
                AddedActividades = Table.AddColumn(ChangedType, "Actividades", each 1, type number),
                    UppercasedText = Table.TransformColumns(AddedActividades,{{"Departamento", Text.Upper, type text}})
            in
                UppercasedText
        in
            Origen,
//Busca la carpeta DatasProduccionMantenimiento
    Source = Folder.Files(MyRuta&"\DatasProduccionMantenimiento"),
    FilteredExtension = Table.SelectRows(Source, each [Extension] = ".xlsb"),
    FilteredName = Table.SelectRows(FilteredExtension, each not Text.Contains([Name], "~")),
    InsertadasColumnasFechas = Table.AddColumn(Table.AddColumn(FilteredName, "Mes", each Text.BetweenDelimiters([Name], "_", " "), type text), "Año", each Text.BetweenDelimiters([Name], " ", "_", 2, 0), type text),
    InsertadoFecha = Table.TransformColumns(Table.AddColumn(InsertadasColumnasFechas, "Fecha", each Text.Combine({"01", [Mes], [Año]}, "/"), type text),{{"Fecha", each Date.From(DateTimeZone.From(_)), type date}}),
    ChangedTypeMes = Table.TransformColumnTypes(InsertadoFecha,{{"Mes", Int64.Type}, {"Año", Int64.Type}}),
    FilteredEsHistorial = if(EsHistorial)then(Table.NestedJoin(ChangedTypeMes, {"Mes", "Año"}, Mes_Actu, {"Mes", "Año"}, "Mes_Actu", JoinKind.RightOuter))else(Table.SelectRows(ChangedTypeMes, each Date.IsInCurrentMonth([Fecha]))),
//Entre los atributos busca el estado de oculto del archivo
    FilteredHiddenFiles = Table.SelectRows(FilteredEsHistorial, each [Attributes]?[Hidden]? <> true),
//Utliza la transformacion y la aplica en cada archivo encontrado
    InvokeCustomFunction = Table.AddColumn(FilteredHiddenFiles, "Transformar archivo", each TransformaProduccionMantenimiento([Content])),
//Cambia el nombre de la columna para dejar como Source.Name
    RenamedColumnName = Table.RenameColumns(InvokeCustomFunction, {"Name", "Source.Name"}),
//Selecciona las columnas a dejar
    RemovedOtherColumns = Table.SelectColumns(RenamedColumnName,{"Transformar archivo"}),
//Quita los errores del paso de transformacion
    RemovedErrors = Table.RemoveRowsWithErrors(RemovedOtherColumns, {"Transformar archivo"}),
//Expande la columna de transformacion utilizando la funcion de ejemplo
    ExpandedTableColumn = Table.ExpandTableColumn(RemovedErrors, "Transformar archivo", Table.ColumnNames(TransformaProduccionMantenimiento(EjemploProduccionMantenimiento))),
//Seleccionar el tipo de dato de cada columna
    ChangedType = Table.TransformColumnTypes(ExpandedTableColumn,{{"Tipo_de_orden", type text}, {"Subtipo_de_orden", type text}, {"Pet_atis", type text}, {"Identificador_PC_Linea", type text}, {"external_id", type text}, {"Fecha de Cierre", type date}, {"Actividades", type number}, {"Departamento", type text}, {"Medio de Acceso", type text}}),
//Renombrar columnas para combinar en Producción
    RenamedColumns = Table.RenameColumns(ChangedType,{{"Pet_atis", "Atis"}, {"Identificador_PC_Linea", "Atiempo"}, {"Tipo_de_orden", "Tipo Orden"}, {"external_id", "CC Tec"}, {"Fecha de Cierre", "Fecha"}, {"Subtipo_de_orden", "Tipo Tarea"}}),
//Se filtra la columna de CC y se quitan los null
    FilteredNullCC = Table.SelectRows(RenamedColumns, each [CC Tec] <> null and [CC Tec] <> ""),
//Se filtra la columna de Fecha y se quitan los null
    FilteredNullFecha = Table.SelectRows(FilteredNullCC, each [Fecha] <> null and [Fecha] <> ""),
//Se filtra la columna de Atis y se quitan los null
    FilteredNullAtis = Table.SelectRows(FilteredNullFecha, each [Atis] <> null and [Atis] <> ""),
    RemovedOtherColumnsFinal = Table.SelectColumns(FilteredNullAtis,{"Tipo Orden", "Tipo Tarea", "Atis", "Atiempo", "Departamento", "Medio de Acceso", "CC Tec", "Fecha", "Actividades"})
in
    RemovedOtherColumnsFinal