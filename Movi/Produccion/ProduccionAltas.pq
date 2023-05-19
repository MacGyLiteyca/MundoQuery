let
// Ruta
    LaRuta = Ruta,
//Ejemplos Archivo
    EjemploProduccionAltas = 
        let
            Source = Folder.Files(LaRuta&"\DatasProduccion"),
            Navigation1 = Source{0}[Content]
        in
            Navigation1,

    TransformaProduccionAltas = 
        let
            Origen = (ParámetroProduccionAltas as binary) => let
            //Como fuente es la carpeta de Producción Altas
                Source = Excel.Workbook(ParámetroProduccionAltas, null, true),
            //Selección de la hoja en el excel Produccion
                Produccion1 = Source{[Name="Produccion"]}[Data],
            //Selección de solo las columnas a utilizar
                RemovedOtherColumns = Table.SelectColumns(Produccion1,{"Column1", "Column2", "Column3", "Column4", "Column5", "Column6", "Column8", "Column9", "Column10"}),
            //Utiliza la primera como titulos
                PromotedHeaders = Table.PromoteHeaders(RemovedOtherColumns, [PromoteAllScalars=true]),
            //Se reemplazo el punto por la coma en la columna de total baremos
                ReplacedPuntoXComa = Table.ReplaceValue(PromotedHeaders,".",",",Replacer.ReplaceText,{"TOTAL BAREMOS"}),
            //Se valida la columna de fecha para que sin importar el formato del excel logre tomar la fecha
                ValidarFecha = Table.TransformColumns(ReplacedPuntoXComa,{{"Fecha de cierre", each Date.From(Value.FromText(_)), type date}}),
            //Selección de tipo de dato de las columnas
                ChangedType = Table.TransformColumnTypes(ValidarFecha,{{"id_actuacion", type text}, {"pedido_atis", type text}, {"Tipo Actuacion", type text}, {"Tipo Tarea", type text}, {"Num Empleado", type text}, {"Fecha de cierre", type date}, {"TOTAL BAREMOS", type number}, {"Departamento", type text}})
            in
                ChangedType
        in
            Origen,

//Busca la carpeta DatasProduccion
    Source = Folder.Files(LaRuta&"\DatasProduccion"),
    FilteredExtension = Table.SelectRows(Source, each [Extension] = ".xlsb"),
    FilteredName = Table.SelectRows(FilteredExtension, each not Text.Contains([Name], "~")),
    InsertadasColumnasFechas = Table.AddColumn(Table.AddColumn(FilteredName, "Mes", each Text.BetweenDelimiters([Name], "_", " "), type text), "Año", each Text.BetweenDelimiters([Name], " ", "_", 2, 0), type text),
    InsertadoFecha = Table.TransformColumns(Table.AddColumn(InsertadasColumnasFechas, "Fecha", each Text.Combine({"01", [Mes], [Año]}, "/"), type text),{{"Fecha", each Date.From(DateTimeZone.From(_)), type date}}),
    ChangedTypeMes = Table.TransformColumnTypes(InsertadoFecha,{{"Mes", Int64.Type}, {"Año", Int64.Type}}),
    FilteredEsHistorial = if(EsHistorial)then(Table.NestedJoin(ChangedTypeMes, {"Mes", "Año"}, Mes_Actu, {"Mes", "Año"}, "Mes_Actu", JoinKind.RightOuter))else(Table.SelectRows(ChangedTypeMes, each Date.IsInCurrentMonth([Fecha]))),
    //Entre los atributos busca el estado de oculto del archivo
    FilteredHiddenFiles = Table.SelectRows(FilteredEsHistorial, each [Attributes]?[Hidden]? <> true),
//Utliza la transformacion y la aplica en cada archivo encontrado
    InvokeCustomFunction = Table.AddColumn(FilteredHiddenFiles, "Transformar archivo", each TransformaProduccionAltas([Content])),
//Selecciona las columnas a dejar
    RemovedOtherColumns = Table.SelectColumns(InvokeCustomFunction,{"Transformar archivo"}),
//Quita los errores del paso de transformacion
    RemovedErrors = Table.RemoveRowsWithErrors(RemovedOtherColumns, {"Transformar archivo"}),
//Expande la columna de transformacion utilizando la funcion de ejemplo
    ExpandedTableColumn = Table.ExpandTableColumn(RemovedErrors, "Transformar archivo", Table.ColumnNames(TransformaProduccionAltas(EjemploProduccionAltas))),
//Seleccionar el tipo de dato de cada columna
    ChangedType = Table.TransformColumnTypes(ExpandedTableColumn,{{"id_actuacion", type text}, {"pedido_atis", type text}, {"Tipo Actuacion", type text}, {"Tipo Tarea", type text}, {"Num Empleado", type text}, {"Fecha de cierre", type date}, {"TOTAL BAREMOS", type number}, {"Departamento", type text}, {"TIPO DE RED", type text}}),
    // Cambiar nombres de columnas para poder conbinar en Producción
    RenamedColumns = Table.RenameColumns(ChangedType,{{"pedido_atis", "Atis"}, {"id_actuacion", "Atiempo"}, {"Num Empleado", "CC Tec"}, {"Fecha de cierre", "Fecha"}, {"Tipo Actuacion", "Tipo Orden"}, {"TOTAL BAREMOS", "Baremos"}, {"TIPO DE RED", "Medio de Acceso"}}),
//Se filtra la columna de CC y se quitan los null
    FilteredNullCC = Table.SelectRows(RenamedColumns, each [CC Tec] <> null and [CC Tec] <> ""),
//Se filtra la columna de Fecha y se quitan los null
    FilteredNullFecha = Table.SelectRows(FilteredNullCC, each [Fecha] <> null and [Fecha] <> ""),
//Se filtra la columna de Atis y se quitan los null
    FilteredNullAtis = Table.SelectRows(FilteredNullFecha, each [Atis] <> null and [Atis] <> ""),
    RemovedOtherColumnsFinal = Table.SelectColumns(FilteredNullAtis,{"Atiempo", "Atis", "Tipo Orden", "Tipo Tarea", "Departamento", "CC Tec", "Fecha", "Medio de Acceso", "Baremos"})
in
    RemovedOtherColumnsFinal