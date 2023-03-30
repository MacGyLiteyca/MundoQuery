// Cuadrillas
let
    MyRuta = Ruta&"\Indicadores\ConformacionCuadrillas",
    TransformarCuadrillas = 
        let
            Origen = (ParámetroCuadrillas as binary) => let
            Source = Excel.Workbook(ParámetroCuadrillas, null, true),
            CONFORMACION_CONSOLIDADO_Table = Source{[Item="CONFORMACION_CONSOLIDADO",Kind="Table"]}[Data],
            RemovedOtherColumns = Table.SelectColumns(CONFORMACION_CONSOLIDADO_Table,{"EMPRESA", "DEPARTAMENTO", "CEDULA TECNICO", "NOMBRE TECNICO", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "CEDULA LIDER ", "LIDER DE GESTION", "CEDULA PROFESIONAL", "PROFESIONAL", "FECHA INICIAL", "FECHA FIN"}),
            ChangedType = Table.TransformColumnTypes(RemovedOtherColumns,{{"EMPRESA", type text}, {"DEPARTAMENTO", type text}, {"CEDULA TECNICO", type text}, {"NOMBRE TECNICO", type text}, {"CEDULA AUX GESTION", type text}, {"AUXILIAR DE GESTION", type text}, {"CEDULA SUPERVISOR", type text}, {"SUPERVISOR", type text}, {"CEDULA LIDER ", type text}, {"LIDER DE GESTION", type text}, {"CEDULA PROFESIONAL", type text}, {"PROFESIONAL", type text}, {"FECHA INICIAL", type date}, {"FECHA FIN", type date}})
        in
            ChangedType
    in
        Origen,
    EjemploCuadrillas =
        let
            Source = Folder.Files(MyRuta),
            Navigation1 = Source{0}[Content]
        in
            Navigation1,
    MesAct =
        let 
            Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/MesUtilizar.pq")), #shared)
        in Source, 
    Source = Folder.Files(MyRuta),
    MesInsertado = Table.AddColumn(Source, "Mes", each Text.BetweenDelimiters([Name], " ", "."), type text),
    AñoInsertado = Table.AddColumn(MesInsertado, "Año", each Text.BetweenDelimiters([Name], ".", "."), type text),
    #"Inserted Merged Column" = Table.AddColumn(AñoInsertado, "FechaArchivo", each Text.Combine({"01", [Mes], [Año]}, "/"), type text),
    ChangedTypeAñoMes = Table.TransformColumnTypes(#"Inserted Merged Column",{{"Año", type number}, {"Mes", type number}}),
    MergedMesAct = Table.NestedJoin(ChangedTypeAñoMes, {"Año", "Mes"}, MesAct, {"Año", "Mes"}, "MesAct", JoinKind.RightOuter),
    FilteredNullName = Table.SelectRows(MergedMesAct, each [Name] <> null and [Name] <> ""),
    FilteredHiddenFiles1 = Table.SelectRows(FilteredNullName, each [Attributes]?[Hidden]? <> true),
    InvokeCustomFunction1 = Table.AddColumn(FilteredHiddenFiles1, "Transformar archivo", each TransformarCuadrillas([Content])),
    RemovedOtherColumns1 = Table.SelectColumns(InvokeCustomFunction1,{"FechaArchivo", "Transformar archivo"}),
    RemovedErrors1 = Table.RemoveRowsWithErrors(RemovedOtherColumns1, {"Transformar archivo"}),
    ExpandedTableColumn1 = Table.ExpandTableColumn(RemovedErrors1, "Transformar archivo", Table.ColumnNames(TransformarCuadrillas(EjemploCuadrillas))),
    ChangedType = Table.TransformColumnTypes(ExpandedTableColumn1,{{"EMPRESA", type text}, {"DEPARTAMENTO", type text}, {"CEDULA TECNICO", type text}, {"NOMBRE TECNICO", type text}, {"CEDULA AUX GESTION", type text}, {"AUXILIAR DE GESTION", type text}, {"CEDULA SUPERVISOR", type text}, {"SUPERVISOR", type text}, {"CEDULA LIDER ", type text}, {"LIDER DE GESTION", type text}, {"CEDULA PROFESIONAL", type text}, {"PROFESIONAL", type text}, {"FECHA INICIAL", type date}, {"FECHA FIN", type date}, {"FechaArchivo", type date}}),
    CapitalizedEachWord = Table.TransformColumns(ChangedType,{{"EMPRESA", Text.Proper, type text}, {"DEPARTAMENTO", Text.Proper, type text}})
in
    CapitalizedEachWord