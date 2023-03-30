// MesAct
let
    Source = try(Excel.CurrentWorkbook(){[Name="MesAct"]}[Content])otherwise(#table(type table 
            [Año = number, Mes = number], 
            {{Date.Year(DateTime.LocalNow()), Date.Month(DateTime.LocalNow())}})),
    ChangedType = Table.TransformColumnTypes(Source,{{"Año", type number}, {"Mes", type number}})
in
    ChangedType