// TBLAccesoCuadrillas
let
    Source = Excel.CurrentWorkbook(){[Name="AccesoCuadrillas"]}[Content],
    ChangedType = Table.TransformColumnTypes(Source,{{"Compania", type text}, {"Departamento", type text}, {"CCTec", type text}, {"Acceso", type text}, {"Cargo", type text}, {"Año", Int64.Type}, {"Mes", Int64.Type}, {"FechaMin", type date}, {"FechaMax", type date}}),
    MergedMesAct = Table.NestedJoin(ChangedType, {"Año", "Mes"}, MesAct, {"Año", "Mes"}, "MesAct", JoinKind.LeftAnti),
    RemovedOtherColumns = Table.SelectColumns(MergedMesAct,{"Compania", "Departamento", "CCTec", "Acceso", "Cargo", "Año", "Mes", "FechaMin", "FechaMax"})
in
    RemovedOtherColumns