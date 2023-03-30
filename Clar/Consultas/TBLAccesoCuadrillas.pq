// TBLAccesoCuadrillas
let
    Source = try(Excel.CurrentWorkbook(){[Name="AccesoCuadrillas"]}[Content])otherwise(#table(type table 
            [Compania = text, Departamento = text, CCTec = text, Acceso = text, Cargo = text, Año = Int64.Type, Mes = Int64.Type, FechaMin = date, FechaMax = date], 
            {{null, null, null, null, null, null, null, null, null}})),
    MesAct =
        let 
            Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/MesUtilizar.pq")), #shared)
        in Source, 
    ChangedType = Table.TransformColumnTypes(Source,{{"Compania", type text}, {"Departamento", type text}, {"CCTec", type text}, {"Acceso", type text}, {"Cargo", type text}, {"Año", Int64.Type}, {"Mes", Int64.Type}, {"FechaMin", type date}, {"FechaMax", type date}}),
    MergedMesAct = Table.NestedJoin(ChangedType, {"Año", "Mes"}, MesAct, {"Año", "Mes"}, "MesAct", JoinKind.LeftAnti),
    RemovedOtherColumns = Table.SelectColumns(MergedMesAct,{"Compania", "Departamento", "CCTec", "Acceso", "Cargo", "Año", "Mes", "FechaMin", "FechaMax"})
in
    RemovedOtherColumns