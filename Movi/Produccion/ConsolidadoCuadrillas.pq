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

    TransformaCuadrillas = 
        let
            Origen = (ParámetroProduccionAltas as binary) => let
    //Como fuente es la carpeta de Producción Altas
        Source = Excel.Workbook(ParámetroProduccionAltas, null, true),
    //Selección de la hoja en el excel Cuadrillas
        Cuadrillas1 = Source{[Name="Cuadrillas"]}[Data],
    //Utiliza la primera como titulos
        PromotedHeaders = Table.PromoteHeaders(Cuadrillas1, [PromoteAllScalars=true]),
    //Se asegur que el tipo de dato sea fecha en las columnas inicial y final
        ParsedDate = Table.TransformColumns(PromotedHeaders,{{"Fecha Inicial", each Date.From(Value.FromText(_)), type date}, {"Fecha Final", each Date.From(Value.FromText(_)), type date}}),
    //Selección de tipo de dato de las columnas
        ChangedType = Table.TransformColumnTypes(ParsedDate,{{"EMPRESA", type text}, {"DEPARTAMENTO", type text}, {"AREA", type text}, {"CEDULA TECNICO", type text}, {"NOMBRE TECNICO", type text}, {"TIPO CUADRILLA", type text}, {"ID RECURSO TOA", type text}, {"CEDULA AUX GESTION", type text}, {"AUXILIAR DE GESTION", type text}, {"CEDULA SUPERVISOR", type text}, {"SUPERVISOR", type text}, {"Fecha Inicial", type date}, {"Fecha Final", type date}, {"CEDULA AUXILIAR", type text}, {"NOMBRE AUXILIAR", type text}}),
    //Quitado los espacios en blanco
        TrimmedText = Table.TransformColumns(ChangedType,{{"EMPRESA", Text.Trim, type text}, {"DEPARTAMENTO", Text.Trim, type text}, {"AREA", Text.Trim, type text}, {"NOMBRE TECNICO", Text.Trim, type text}, {"TIPO CUADRILLA", Text.Trim, type text}, {"AUXILIAR DE GESTION", Text.Trim, type text}, {"SUPERVISOR", Text.Trim, type text}, {"NOMBRE AUXILIAR", Text.Trim, type text}}),
    //Quitado los espacios extra
        CleanedText = Table.TransformColumns(TrimmedText,{{"EMPRESA", Text.Clean, type text}, {"DEPARTAMENTO", Text.Clean, type text}, {"AREA", Text.Clean, type text}, {"NOMBRE TECNICO", Text.Clean, type text}, {"TIPO CUADRILLA", Text.Clean, type text}, {"AUXILIAR DE GESTION", Text.Clean, type text}, {"SUPERVISOR", Text.Clean, type text}, {"NOMBRE AUXILIAR", Text.Clean, type text}}),
    //Dejado todo en mayúsculas
        UppercasedText = Table.TransformColumns(CleanedText,{{"EMPRESA", Text.Upper, type text}, {"DEPARTAMENTO", Text.Upper, type text}, {"AREA", Text.Upper, type text}, {"NOMBRE TECNICO", Text.Upper, type text}, {"TIPO CUADRILLA", Text.Upper, type text}, {"AUXILIAR DE GESTION", Text.Upper, type text}, {"SUPERVISOR", Text.Upper, type text}, {"NOMBRE AUXILIAR", Text.Upper, type text}}),
    //Se quitan las filas que contengan errores
        RemovedErrors = Table.RemoveRowsWithErrors(UppercasedText, {"EMPRESA", "DEPARTAMENTO", "AREA", "CEDULA TECNICO", "NOMBRE TECNICO", "TIPO CUADRILLA", "ID RECURSO TOA", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "Fecha Inicial", "Fecha Final", "NOMBRE AUXILIAR", "CEDULA AUXILIAR"}),
        SelectedColumns = Table.SelectColumns(RemovedErrors,{"EMPRESA", "DEPARTAMENTO", "AREA", "CEDULA TECNICO", "NOMBRE TECNICO", "TIPO CUADRILLA", "ID RECURSO TOA", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "Fecha Inicial", "Fecha Final", "NOMBRE AUXILIAR", "CEDULA AUXILIAR"}),
        Filtered_Null_CC_Tec = Table.SelectRows(SelectedColumns, each [CEDULA TECNICO] <> null and [CEDULA TECNICO] <> "")
    in
        Filtered_Null_CC_Tec
        in
            Origen,

//Busca la carpeta DatasProduccion
    Source = Folder.Files(LaRuta&"\DatasProduccion"),
    Insertado_Year = Table.AddColumn(Source, "Año", each Text.BetweenDelimiters([Name], " ", "_", 2, 0), type text),
    Insertado_Mes = Table.AddColumn(Insertado_Year, "Mes", each Text.BetweenDelimiters([Name], "_", " "), type text),
    Changed_Type_Date = Table.TransformColumnTypes(Insertado_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
    Merged_Mes_Act = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actu, {"Mes", "Año"}, "Mes_Actu", JoinKind.RightOuter),
    //Entre los atributos busca el estado de oculto del archivo
    FilteredHiddenFiles1 = Table.SelectRows(Merged_Mes_Act, each [Attributes]?[Hidden]? <> true),
//Utliza la transformacion y la aplica en cada archivo encontrado
    InvokeCustomFunction1 = Table.AddColumn(FilteredHiddenFiles1, "Transformar archivo", each TransformaCuadrillas([Content])),
//Selecciona las columnas a dejar
    RemovedOtherColumns1 = Table.SelectColumns(InvokeCustomFunction1,{"Transformar archivo"}),
//Quita los errores del paso de transformacion
    RemovedErrors1 = Table.RemoveRowsWithErrors(RemovedOtherColumns1, {"Transformar archivo"}),
//Expande la columna de transformacion utilizando la funcion de ejemplo
    ExpandedTableColumn1 = Table.ExpandTableColumn(RemovedErrors1, "Transformar archivo", Table.ColumnNames(TransformaCuadrillas(EjemploProduccionAltas))),
//Seleccionar el tipo de dato de cada columna
    ChangedType = Table.TransformColumnTypes(ExpandedTableColumn1,{{"EMPRESA", type text}, {"DEPARTAMENTO", type text}, {"AREA", type text}, {"CEDULA TECNICO", type text}, {"NOMBRE TECNICO", type text}, {"TIPO CUADRILLA", type text}, {"ID RECURSO TOA", type text}, {"CEDULA AUX GESTION", type text}, {"AUXILIAR DE GESTION", type text}, {"CEDULA SUPERVISOR", type text}, {"SUPERVISOR", type text}, {"Fecha Inicial", type date}, {"Fecha Final", type date}, {"CEDULA AUXILIAR", type text}, {"NOMBRE AUXILIAR", type text}}),
    //Los tipo de cuadriila Fibra se cambian a C2
    ReplacedFibraTipoCuadri = Table.ReplaceValue(ChangedType,"FIBRA","C2",Replacer.ReplaceText,{"TIPO CUADRILLA"}),
//Los tipo de Cuadrilla en blanco se pasan a M1
    ReplacedNullTipoCuadri = Table.ReplaceValue(ReplacedFibraTipoCuadri,null,"M1",Replacer.ReplaceValue,{"TIPO CUADRILLA"}),
//Se agrega la columna para cruzar con el calendario
    AddedCustom = Table.AddColumn(ReplacedNullTipoCuadri, "Util", each "X_X", type text),
//Se le da un nombre a cada columna para el uso en las próximas consultas
    RenamedColumns = Table.RenameColumns(AddedCustom,{{"EMPRESA", "Contrata"}, {"DEPARTAMENTO", "Departamento"}, {"AREA", "AreaCuadri"}, {"CEDULA TECNICO", "CC"}, {"NOMBRE TECNICO", "Nom Tec"}, {"TIPO CUADRILLA", "Tipo Cuadrilla"}, {"ID RECURSO TOA", "Id TOA"}, {"CEDULA AUX GESTION", "CC Gest"}, {"AUXILIAR DE GESTION", "Nom Gest"}, {"CEDULA SUPERVISOR", "CC Super"}, {"SUPERVISOR", "Nom Super"}, {"CEDULA AUXILIAR", "CC Aux"}, {"NOMBRE AUXILIAR", "Nom Aux"}}),
//Se agrega el año con fecha inicial
    InsertedYear = Table.AddColumn(RenamedColumns, "Año", each Date.Year([Fecha Inicial]), Int64.Type),
//Se agrega el mes con fecha inicial
    InsertedMonth = Table.AddColumn(InsertedYear, "Mes", each Date.Month([Fecha Inicial]), Int64.Type),
//Se quitan los registros duplicados que se puedan encontrar
    RemovedDuplicates = Table.Distinct(InsertedMonth),
    Mayusculas = Table.TransformColumns(RemovedDuplicates,{{"Nom Tec", Text.Proper, type text}, {"Nom Aux", Text.Proper, type text}, {"Nom Gest", Text.Proper, type text}, {"Nom Super", Text.Proper, type text}, {"Contrata", Text.Proper, type text}}),
    ReplacedAux1 = Table.ReplaceValue(Mayusculas,"NO TIENE","X_X",Replacer.ReplaceText,{"CC Aux", "Nom Aux"}),
    ReplacedAux2 = Table.ReplaceValue(ReplacedAux1,null,"X_X",Replacer.ReplaceValue,{"CC Aux", "Nom Aux"}),
    ReplacedAux3 = Table.ReplaceValue(ReplacedAux2,"0","X_X",Replacer.ReplaceValue,{"CC Aux", "Nom Aux"}),
    ReplacedAux4 = Table.ReplaceValue(ReplacedAux3,"NA","X_X",Replacer.ReplaceText,{"CC Aux", "Nom Aux"})
in
    ReplacedAux4