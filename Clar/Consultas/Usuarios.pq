// Usuarios
let
    Source = try(Excel.CurrentWorkbook(){[Name="Usuarios"]}[Content])otherwise(#table(type table 
            [CC Acceso = text, Nombre = text, Departamento = text, Cargo = text, Usuario = text, Clave = Int64.Type, Estado = logical, Consecutivo = Int64.Type, Calculo Usuario = text, Calculo Clave =Int64.Type], 
            {"Admin", "Admin", null, "Admin", "Admin", null, true, null, null})),
    ChangedType = Table.TransformColumnTypes(Source,{{"CC Acceso", type text}, {"Nombre", type text}, {"Departamento", type text}, {"Cargo", type text}, {"Usuario", type text}, {"Clave", Int64.Type}, {"Estado", type logical}, {"Consecutivo", Int64.Type}, {"Calculo Usuario", type text}, {"Calculo Clave", Int64.Type}}),
    FilteredEstadoTrue = Table.SelectRows(ChangedType, each [Estado] = true)
in
    FilteredEstadoTrue