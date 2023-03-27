// MesAct
let
    Source = Excel.CurrentWorkbook(){[Name="MesAct"]}[Content],
    ChangedType = Table.TransformColumnTypes(Source,{{"Año", type number}, {"Mes", type number}})
in
    ChangedType