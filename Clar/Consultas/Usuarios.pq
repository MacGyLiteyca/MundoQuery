// Usuarios
let
    Source = Excel.CurrentWorkbook(){[Name="Usuarios"]}[Content],
    ChangedType = Table.TransformColumnTypes(Source,{{"CC Acceso", type text}, {"Nombre", type text}, {"Departamento", type text}, {"Cargo", type text}, {"Usuario", type text}, {"Clave", Int64.Type}, {"Estado", type logical}, {"Consecutivo", Int64.Type}, {"Calculo Usuario", type text}, {"Calculo Clave", Int64.Type}}),
    FilteredEstadoTrue = Table.SelectRows(ChangedType, each [Estado] = true)
in
    FilteredEstadoTrue