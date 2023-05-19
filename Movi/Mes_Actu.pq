let
    Source = Excel.CurrentWorkbook(){[Name="Mes_Actu"]}[Content],
    Changed_Type = Table.TransformColumnTypes(Source,{{"Mes", Int64.Type}, {"Año", Int64.Type}}),
    Tabla_Mes_Actual = #table(type table[Mes = Int64.Type, Año = Int64.Type], {{Date.Month(DateTime.FixedLocalNow()), Date.Year(DateTime.FixedLocalNow())}}),
    Mes_Actualizar = if(EsHistorial)then(Changed_Type)else(Tabla_Mes_Actual)
in
    Mes_Actualizar