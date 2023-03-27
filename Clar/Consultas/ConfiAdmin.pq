// ConfigAdmin
let
    Source = Excel.CurrentWorkbook(){[Name="ConfigAdmin"]}[Content],
    ChangedType = Table.TransformColumnTypes(Source,{{"FechaInicio", type date}, {"FechaFin", type date}, {"CC Acceso", type text}, {"Nombre", type text}, {"Cargo", type text}, {"Contratista", type text}, {"Departamento", type text}}),
    InvokedListaFechas = Table.AddColumn(ChangedType, "fxListaFechas", each fxListaFechas([FechaInicio], [FechaFin]), type table[Fecha=date, Año=Int64.Type, Mes=Int64.Type]),
    ExpandedListaFechas = Table.ExpandTableColumn(InvokedListaFechas, "fxListaFechas", {"Fecha", "Año", "Mes"}, {"Fecha", "Año", "Mes"}),
    MergedMesAct = Table.NestedJoin(ExpandedListaFechas, {"Año", "Mes"}, MesAct, {"Año", "Mes"}, "MesAct", JoinKind.RightOuter)
in
    MergedMesAct