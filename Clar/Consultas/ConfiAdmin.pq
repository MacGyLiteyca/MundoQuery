// ConfigAdmin
let
    Source =
    //Esta es la tabla con las columnas que debe tener para realizar la configuracion de los que vean los datos como admin
        try(Excel.CurrentWorkbook(){[Name = "ConfigAdmin"]}[Content])otherwise(#table(type table 
            [FechaInicio = date, FechaFin = date, CC Acceso = text, Nombre = text, Cargo = text, Contratista = text, Departamento = text], 
            {{#date(2022, 1, 1), #date(2023, 12, 31), "Admin", "Admin", "Admin", null, null}})),
    fxListaFechas =
        let 
            Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/fxListaFechas.pq")), #shared)
        in Source,
    MesAct =
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/MesUtilizar.pq")), #shared)
    in Source,
    ChangedType = Table.TransformColumnTypes(Source, {{"FechaInicio", type date}, {"FechaFin", type date}, {"CC Acceso", type text}, {"Nombre", type text}, {"Cargo", type text}, {"Contratista", type text}, {"Departamento", type text}}),
    InvokedListaFechas = Table.AddColumn(ChangedType, "fxListaFechas", each fxListaFechas([FechaInicio], [FechaFin]), type table [Fecha = date, Año = Int64.Type, Mes = Int64.Type]),
    ExpandedListaFechas = Table.ExpandTableColumn(InvokedListaFechas, "fxListaFechas", {"Fecha", "Año", "Mes"}, {"Fecha", "Año", "Mes"}),
    MergedMesAct = Table.NestedJoin(ExpandedListaFechas, {"Año", "Mes"}, MesAct, {"Año", "Mes"}, "MesAct", JoinKind.RightOuter)
in
    MergedMesAct
