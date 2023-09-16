[
Tablas_Base = let
    Source = ProduccionTecnicos,
    Filtered_Extension = Table.SelectRows(Source, each [Extension] = ".xlsx"),
    Filtered_Folder = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\VersionesBI\V12 Mac\")),
    Filtered_Name = Table.SelectRows(Filtered_Folder, each Text.StartsWith([Name], "Tablas Base")),
    Removed_Other_Columns = Table.SelectColumns(Filtered_Name,{"Content"}),
    Transform_Content = Table.TransformColumns(Removed_Other_Columns, {"Content", each Excel.Workbook(_)}),
    Expanded_Content = Table.ExpandTableColumn(Transform_Content, "Content", {"Name", "Data", "Item", "Kind", "Hidden"}, {"Name", "Data", "Item", "Kind", "Hidden"}),
    Filtered_Kind_Table = Table.SelectRows(Expanded_Content, each [Kind] = "Table")
in
    Filtered_Kind_Table,
Tbl_Departamentos = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="TblDepartamentos"]}[Data],
    Trimmed_Departamento = Table.TransformColumns(Filtered_Rows,{{"Departamento", Text.Trim, type text}}),
    Cleaned_Departamento = Table.TransformColumns(Trimmed_Departamento,{{"Departamento", Text.Clean, type text}}),
    Capitalized_Departamento = Table.TransformColumns(Cleaned_Departamento,{{"Departamento", Text.Proper, type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Capitalized_Departamento, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Departamento = Table.SelectRows(Merged_Mes_Act, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Departamento,{"Mes_Actualizar"})
in
    Removed_Column_Mes_Act,
AccesosCuadrillas_2 = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="AccesosCuadrillas_2"]}[Data],
    Trimmed_Text = Table.TransformColumns(Filtered_Rows,{{"Area Cuadri", Text.Trim, type text}, {"Nom Super", Text.Trim, type text}, {"Nom Gestor", Text.Trim, type text}, {"Nom Tec", Text.Trim, type text}, {"Contrata", Text.Trim, type text}, {"Departamento", Text.Trim, type text}, {"Cargo", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Area Cuadri", Text.Clean, type text}, {"Nom Super", Text.Clean, type text}, {"Nom Gestor", Text.Clean, type text}, {"Nom Tec", Text.Clean, type text}, {"Contrata", Text.Clean, type text}, {"Departamento", Text.Clean, type text}, {"Cargo", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Area Cuadri", Text.Proper, type text}, {"Nom Super", Text.Proper, type text}, {"Nom Gestor", Text.Proper, type text}, {"Nom Tec", Text.Proper, type text}, {"Contrata", Text.Proper, type text}, {"Departamento", Text.Proper, type text}, {"Cargo", Text.Proper, type text}}),
    Invoke_fxCalendario_Dia = fxMiCalendarioDia(Capitalized_Each_Word, "FechaMin", "FechaMax"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Dia, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Departamento = Table.SelectRows(Merged_Mes_Act, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Departamento,{"Mes_Actualizar"})
in
    Removed_Column_Mes_Act,
Tbl_Bonos = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="TblBonos"]}[Data],
    Trimmed_Text = Table.TransformColumns(Filtered_Rows,{{"Cargo", Text.Trim, type text}, {"CuadrillaArea", Text.Trim, type text}, {"TipoCuadrilla", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Cargo", Text.Clean, type text}, {"CuadrillaArea", Text.Clean, type text}, {"TipoCuadrilla", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Cargo", Text.Proper, type text}, {"CuadrillaArea", Text.Proper, type text}, {"TipoCuadrilla", Text.Proper, type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Capitalized_Each_Word, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Cargo = Table.SelectRows(Merged_Mes_Act, each [Cargo] <> null and [Cargo] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Cargo,{"Mes_Actualizar"}),
    Added_Cargo_2 = Table.AddColumn(Removed_Column_Mes_Act, "Personalizado", each if [Cargo] = "Admin" then "Aux Tec" else if [Cargo] = "TECNICO" then "Aux Tec" else null, type text),
    Merged_Tbl_Bonos = Table.NestedJoin(Added_Cargo_2, {"Personalizado", "CuadrillaArea", "TipoCuadrilla", "Año", "Mes"}, Added_Cargo_2, {"Cargo", "CuadrillaArea", "TipoCuadrilla", "Año", "Mes"}, "Added Conditional Column", JoinKind.LeftOuter),
    Expanded_Tbl_Bonos = Table.ExpandTableColumn(Merged_Tbl_Bonos, "Added Conditional Column", {"Salario", "Max Porc Bono", "Parte Presta", "Parte Cuadri 2 Per"}, {"Aux.Salario", "Aux.Max Porc Bono", "Aux.Parte Presta", "Aux.Parte Cuadri 2 Per"})
in
    Expanded_Tbl_Bonos,
Tbl_Meta_Mostrar = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="TblMetaMostrar"]}[Data],
    Trimmed_Text = Table.TransformColumns(Filtered_Rows,{{"Departamento", Text.Trim, type text}, {"CuadrillaArea", Text.Trim, type text}, {"Tipo", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Departamento", Text.Clean, type text}, {"CuadrillaArea", Text.Clean, type text}, {"Tipo", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Departamento", Text.Proper, type text}, {"CuadrillaArea", Text.Proper, type text}, {"Tipo", Text.Proper, type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Capitalized_Each_Word, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Departamento = Table.SelectRows(Merged_Mes_Act, each [Departamento] <> null and [Departamento] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Departamento,{"Mes_Actualizar"})
in
    Removed_Column_Mes_Act,
Hom_Area_Valor = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="HomAreaVal"]}[Data],
    Trimmed_Text = Table.TransformColumns(Filtered_Rows,{{"Area", Text.Trim, type text}, {"AreaHom", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Area", Text.Clean, type text}, {"AreaHom", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Area", Text.Proper, type text}, {"AreaHom", Text.Proper, type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Capitalized_Each_Word, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Area = Table.SelectRows(Merged_Mes_Act, each [Area] <> null and [Area] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Area,{"Mes_Actualizar"})
in
    Removed_Column_Mes_Act,
Causales_Excluir_Reitero = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="CausalesExcluirReitero"]}[Data],
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Filtered_Rows, "Fecha Inicio", "Fecha Fin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Area = Table.SelectRows(Merged_Mes_Act, each [Acceso] <> null and [Acceso] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Area,{"Mes_Actualizar"})
in
    Removed_Column_Mes_Act,
Tabla_Indicadores = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="TblFD"]}[Data],
    Trimmed_Text = Table.TransformColumns(Filtered_Rows,{{"Aperturas", Text.Trim, type text}, {"Productos", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Aperturas", Text.Clean, type text}, {"Productos", Text.Clean, type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Cleaned_Text, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Corto = Table.SelectRows(Merged_Mes_Act, each [Corto] <> null and [Corto] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Corto,{"Mes_Actualizar"})
in
    Removed_Column_Mes_Act,
Parametro_Nota = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="ParametroNota"]}[Data],
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Filtered_Rows, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Removed_Column_Mes_Act = Table.RemoveColumns(Merged_Mes_Act,{"Mes_Actualizar"}),
    Removed_Duplicates = Table.Distinct(Removed_Column_Mes_Act)
in
    Removed_Duplicates,
Tecnicos_Localidad = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="TecLocal"]}[Data],
    Changed_Type = Table.TransformColumnTypes(Filtered_Rows,{{"CEDULA", type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Changed_Type, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Removed_Column_Mes_Act = Table.RemoveColumns(Merged_Mes_Act,{"Mes_Actualizar"}),
    Removed_Duplicates = Table.Distinct(Removed_Column_Mes_Act),
    Added_Tipo_Tecnico = Table.AddColumn(Removed_Duplicates, "Tipo Tecnico", each "Localidad", type text)
in
    Added_Tipo_Tecnico,
Valor_Materiales = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="ValMatLog"]}[Data],
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Filtered_Rows, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Removed_Column_Mes_Act = Table.RemoveColumns(Merged_Mes_Act,{"Mes_Actualizar"}),
    Grouped_Rows = Table.Group(Removed_Column_Mes_Act, {"codigo_material", "descriocion_material", "Año", "Mes"}, {{"Valor", each List.Average([VALOR]), type nullable number}}),
    Removed_Duplicates = Table.Distinct(Grouped_Rows)
in
    Removed_Duplicates,
Tiempos = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="TiemLog"]}[Data],
    Trimmed_Text = Table.TransformColumns(Filtered_Rows,{{"Tipo Tecnico", Text.Trim, type text}, {"Tipo", Text.Trim, type text}, {"Lapso", Text.Trim, type text}, {"Rango", Text.Trim, type text}}),
    Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Tipo Tecnico", Text.Clean, type text}, {"Tipo", Text.Clean, type text}, {"Lapso", Text.Clean, type text}, {"Rango", Text.Clean, type text}}),
    Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Tipo Tecnico", Text.Proper, type text}, {"Tipo", Text.Proper, type text}, {"Lapso", Text.Proper, type text}, {"Rango", Text.Proper, type text}}),
    Added_Dias = Table.AddColumn(Capitalized_Each_Word, "Días", each try List.Numbers([Días menor],1+[Días Mayor]-[Días menor]) otherwise List.Numbers([Días menor],1000)),
    Expanded_Dias = Table.ExpandListColumn(Added_Dias, "Días"),
    Changed_Type = Table.TransformColumnTypes(Expanded_Dias,{{"Días", type number}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Changed_Type, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Removed_Column_Mes_Act = Table.RemoveColumns(Merged_Mes_Act,{"Mes_Actualizar", "Días Mayor", "Días menor"}),
    Removed_Duplicates = Table.Distinct(Removed_Column_Mes_Act)
in
    Removed_Duplicates,
Limites_Rangos_Tesa = let
    Source = Tablas_Base,
    Filtered_Rows = Source{[Item="Limites_Rangos_Tesa"]}[Data],
    Trimmed = Table.TransformColumns(Filtered_Rows,{{"Area", Text.Trim, type text}}),
    Cleaned = Table.TransformColumns(Trimmed,{{"Area", Text.Clean, type text}}),
    Capitalized = Table.TransformColumns(Cleaned,{{"Area", Text.Proper, type text}}),
    Invoke_fxCalendario_Mes = fxMiCalendarioMes(Capitalized, "FechaInicio", "FechaFin"),
    Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
    Filtered_Null_Area = Table.SelectRows(Merged_Mes_Act, each [Area] <> null and [Area] <> ""),
    Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Area,{"Mes_Actualizar"})
in
    Removed_Column_Mes_Act
]