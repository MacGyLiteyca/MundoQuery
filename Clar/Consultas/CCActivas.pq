// CCActivas
let
    fxListaFechas = 
        let 
            Source = Expression.Evaluate(Text.FromBinary(Web.Contents( "https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/fxListaFechas.pq") ), #shared) 
        in Source,
    Source = 
        let 
            Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/Cuadrillas.pq")), #shared)
        in Source,
    ConfigAdmin = 
        let 
            Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/ConfiAdmin.pq")), #shared)
        in Source,
    InvokedListaFechas = Table.AddColumn(Source, "fxListaFechas", each fxListaFechas([FECHA INICIAL], [FECHA FIN]), type table[Fecha=date, Año=Int64.Type, Mes=Int64.Type]),
    ExpandedListaFechas = Table.ExpandTableColumn(InvokedListaFechas, "fxListaFechas", {"Fecha"}, {"Fecha"}),
    MergedConfigAdmin = Table.NestedJoin(ExpandedListaFechas, {"Fecha"}, ConfigAdmin, {"Fecha"}, "ConfigAdmin (2)", JoinKind.LeftOuter),
    ExpandedConfigAdmin = Table.ExpandTableColumn(MergedConfigAdmin, "ConfigAdmin (2)", {"CC Acceso"}, {"CC Acceso"}),
    AddedCedulas = Table.AddColumn(ExpandedConfigAdmin, "Cedulas", each {[CEDULA TECNICO],[CEDULA AUX GESTION],[CEDULA SUPERVISOR],[#"CEDULA LIDER "],[CEDULA PROFESIONAL],[CC Acceso]}),
    RemovedOtherColumns = Table.SelectColumns(AddedCedulas,{"Cedulas"}),
    ExpandedCedulas = Table.ExpandListColumn(RemovedOtherColumns, "Cedulas"),
    RemovedDuplicates = Table.Distinct(ExpandedCedulas),
    ChangedType = Table.TransformColumnTypes(RemovedDuplicates,{{"Cedulas", type text}})
in
    ChangedType