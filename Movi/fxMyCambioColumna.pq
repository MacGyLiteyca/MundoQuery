let
    My_Fx_Reemplazo_Nombres = (Tabla_Inicial as table, CC_Cruzar as text, Nom_Cambiar as text, Tabla_Datos as table, CC_Datos as text, NomOficial as text) =>
    let     
        Merged_Querie_1 = Table.NestedJoin(Tabla_Inicial, {CC_Cruzar}, Tabla_Datos, {CC_Datos}, "Nombres_Consolidado", JoinKind.LeftOuter),
        Expanded_Querie_1 = Table.ExpandTableColumn(Merged_Querie_1, "Nombres_Consolidado", {NomOficial}, {"Nombre_Oficial"}),
        Removed_Columns_Originales = Table.RemoveColumns(Expanded_Querie_1,{Nom_Cambiar}),
        Renamed_Columns_Secundarias = Table.RenameColumns(Removed_Columns_Originales,{{"Nombre_Oficial", Nom_Cambiar}}),
        Replaced_Null_Value = Table.ReplaceValue(Renamed_Columns_Secundarias,null,"Desconocido",Replacer.ReplaceValue,{Nom_Cambiar})
    in 
        Replaced_Null_Value
in
    My_Fx_Reemplazo_Nombres

//= My_Fx_Reemplazo_Nombres(Reemplazar_Nom_Gest, "CC Super", "Nom Super", Con_Nombres_Consolidado, "CC", "Nombre_Oficial")