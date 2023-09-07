let
    Produccion_Altas = let
        Source = ProduccionTecnicos,
        Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".xlsb")),
        Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\DatasProduccion\")),
        Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], " ", "_", 2, 0), type text),
        Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", " "), type text),
        Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
        Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
        Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
        Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Excel.Workbook(_)}),
        Expanded_Content = Table.ExpandTableColumn(Transform_Content, "Content", {"Name", "Data"}, {"Content.Name", "Content.Data"}),
        Expanded_Produccion = Expanded_Content{[Content.Name="Produccion"]}[Content.Data],
        Promoted_Headers = Table.PromoteHeaders(Expanded_Produccion, [PromoteAllScalars=true]),
        Filtered_Null_Fecha = Table.SelectRows(Promoted_Headers, each [Fecha de cierre] <> null and [Fecha de cierre] <> ""),
        Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha de cierre", each Date.From(Value.FromText(_)), type date}}),
        Removed_Other_Columns = Table.SelectColumns(Transform_Fecha,{"id_actuacion", "pedido_atis", "Tipo Actuacion", "Tipo Tarea", "Departamento", "Num Empleado", "Fecha de cierre", "TIPO DE RED", "TOTAL BAREMOS"}),
        Changed_Type = Table.TransformColumnTypes(Removed_Other_Columns,{{"id_actuacion", type text}, {"pedido_atis", type text}, {"Tipo Actuacion", type text}, {"Tipo Tarea", type text}, {"Departamento", type text}, {"Num Empleado", type text}, {"Fecha de cierre", type date}, {"TIPO DE RED", type text}, {"TOTAL BAREMOS", type number}}),
        Trimmed_Text = Table.TransformColumns(Changed_Type,{{"Tipo Tarea", Text.Trim, type text}, {"Departamento", Text.Trim, type text}, {"TIPO DE RED", Text.Trim, type text}, {"Tipo Actuacion", Text.Trim, type text}}),
        Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Tipo Tarea", Text.Clean, type text}, {"Departamento", Text.Clean, type text}, {"TIPO DE RED", Text.Clean, type text}, {"Tipo Actuacion", Text.Clean, type text}}),
        Capitalized_Departamento = Table.TransformColumns(Cleaned_Text,{{"Departamento", Text.Proper, type text}}),
        Renamed_Columns = Table.RenameColumns(Capitalized_Departamento,{{"pedido_atis", "Atis"}, {"id_actuacion", "Atiempo"}, {"Num Empleado", "CC Tec"}, {"Fecha de cierre", "Fecha"}, {"Tipo Actuacion", "Tipo Orden"}, {"TOTAL BAREMOS", "Baremos"}, {"TIPO DE RED", "Medio de Acceso"}}),
        Filtered_Null_Atis = Table.SelectRows(Renamed_Columns, each [Atis] <> null and [Atis] <> ""),
        Filtered_Null_CC_Tec = Table.SelectRows(Filtered_Null_Atis, each [CC Tec] <> null and [CC Tec] <> ""),
        Added_Area_Cuadri = Table.AddColumn(Filtered_Null_CC_Tec, "AreaCuadri", each "Instalaciones", type text),
        Merged_Tbl_Departamentos = Table.NestedJoin(Added_Area_Cuadri, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
        Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
        Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
        Removed_Duplicates = Table.Distinct(Removed_Columns)
    in
        Removed_Duplicates,

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

    Produccion_Mantenimiento = let
        Source = ProduccionTecnicos,
        Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".xlsb")),
        Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\DatasProduccionMantenimiento\")),
        Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], " ", "_", 2, 0), type text),
        Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", " "), type text),
        Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
        Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
        Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
        Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Excel.Workbook(_)}),
        Expanded_Content = Table.ExpandTableColumn(Transform_Content, "Content", {"Name", "Data"}, {"Content.Name", "Content.Data"}),
        Expanded_Base = Expanded_Content{[Content.Name="BASE"]}[Content.Data],
        Promoted_Headers = Table.PromoteHeaders(Expanded_Base, [PromoteAllScalars=true]),
        Filtered_Null_Fecha = Table.SelectRows(Promoted_Headers, each [Fecha_de_cierre_final] <> null and [Fecha_de_cierre_final] <> ""),
        Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha_de_cierre_final", each Date.From(Value.FromText(_)), type date}}),
        Removed_Other_Columns = Table.SelectColumns(Transform_Fecha,{"Tipo_de_orden", "Subtipo_de_orden", "Pet_atis", "Identificador_PC_Linea", "Departamento", "external_id", "Fecha_de_cierre_final"}),
        Changed_Type = Table.TransformColumnTypes(Removed_Other_Columns,{{"Tipo_de_orden", type text}, {"Subtipo_de_orden", type text}, {"Pet_atis", type text}, {"Identificador_PC_Linea", type text}, {"Departamento", type text}, {"external_id", type text}, {"Fecha_de_cierre_final", type date}}),
        Trimmed_Text = Table.TransformColumns(Changed_Type,{{"Tipo_de_orden", Text.Trim, type text}, {"Subtipo_de_orden", Text.Trim, type text}, {"Departamento", Text.Trim, type text}}),
        Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Tipo_de_orden", Text.Clean, type text}, {"Subtipo_de_orden", Text.Clean, type text}, {"Departamento", Text.Clean, type text}}),
        Capitalized_Departamento = Table.TransformColumns(Cleaned_Text,{{"Departamento", Text.Proper, type text}}),
        Renamed_Columns = Table.RenameColumns(Capitalized_Departamento,{{"Pet_atis", "Atis"}, {"Identificador_PC_Linea", "Atiempo"}, {"Tipo_de_orden", "Tipo Orden"}, {"external_id", "CC Tec"}, {"Fecha_de_cierre_final", "Fecha"}, {"Subtipo_de_orden", "Tipo Tarea"}}),
        Filtered_Null_Atis = Table.SelectRows(Renamed_Columns, each [Atis] <> null and [Atis] <> ""),
        Filtered_Null_CC_Tec = Table.SelectRows(Filtered_Null_Atis, each [CC Tec] <> null and [CC Tec] <> ""),
        Added_Area_Cuadri = Table.AddColumn(Filtered_Null_CC_Tec, "AreaCuadri", each "Mantenimiento", type text),
        Merged_Tbl_Departamentos = Table.NestedJoin(Added_Area_Cuadri, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
        Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
        Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
        Removed_Duplicates = Table.Distinct(Removed_Columns),
        Added_Actividades = Table.AddColumn(Removed_Duplicates, "Actividades", each 1, type number)
    in
        Added_Actividades,

    Produccion = let
        Source = Table.Combine({Produccion_Altas, Produccion_Mantenimiento}),
        Filtered_Null_Dep = Table.SelectRows(Source, each [Departamento] <> null and [Departamento] <> ""),
        Replaced_Null_Bar_Act = Table.ReplaceValue(Filtered_Null_Dep,null,0,Replacer.ReplaceValue,{"Baremos", "Actividades"}),
        Merged_Cant_Por_Dia = Table.NestedJoin(Replaced_Null_Bar_Act, {"CC Tec", "Fecha"}, Cant_Producion_Dia, {"CC Tec", "Fecha"}, "CantProducionDia", JoinKind.LeftOuter),
        Expanded_Recuento = Table.ExpandTableColumn(Merged_Cant_Por_Dia, "CantProducionDia", {"Recuento", "DiaTrabajado"}, {"Recuento", "DiaTrabajado"}),
        Appended_Cuadrillas_Sin_Produccion = Table.Combine({Expanded_Recuento, Cuadrillas_Sin_Produccion})
    in
        Appended_Cuadrillas_Sin_Produccion,

    Cant_Producion_Dia = let
        Source = Table.Combine({Produccion_Altas, Produccion_Mantenimiento}),
        Grouped_Rows = Table.Group(Source, {"CC Tec", "Fecha"}, {{"Recuento", each Table.RowCount(_), Int64.Type}}),
        Added_Dia_Trabajado = Table.AddColumn(Grouped_Rows, "DiaTrabajado", each 1/[Recuento], type number)
    in
        Added_Dia_Trabajado,

    Consolidado_Cuadrillas = let
        Source = ProduccionTecnicos,
        Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".xlsb")),
        Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\DatasProduccion\")),
        Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], " ", "_", 2, 0), type text),
        Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BetweenDelimiters([Name], "_", " "), type text),
        Changed_Type_Date = Table.TransformColumnTypes(Added_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
        Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
        Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
        Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Excel.Workbook(_)}),
        Expanded_Content = Table.ExpandTableColumn(Transform_Content, "Content", {"Name", "Data"}, {"Content.Name", "Content.Data"}),
        Expanded_Cuadrillas = Expanded_Content{[Content.Name="Cuadrillas"]}[Content.Data],
        Promoted_Headers = Table.PromoteHeaders(Expanded_Cuadrillas, [PromoteAllScalars=true]),
        Filtered_Null_Fecha = Table.SelectRows(Promoted_Headers, each [Fecha Inicial] <> null and [Fecha Inicial] <> ""),
        Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha Inicial", each Date.From(Value.FromText(_)), type date}, {"Fecha Final", each Date.From(Value.FromText(_)), type date}}),
        Removed_Other_Columns = Table.SelectColumns(Transform_Fecha,{"EMPRESA", "DEPARTAMENTO", "AREA", "AREA DE COBERTURA", "CEDULA TECNICO", "NOMBRE TECNICO", "TIPO CUADRILLA", "ID RECURSO TOA", "CEDULA AUXILIAR", "NOMBRE AUXILIAR", "PROYECTO", "HABILIDAD", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "CEDULA LIDER ", "LIDER DE GESTION", "CEDULA PROFESIONAL", "PROFESIONAL", "Fecha Inicial", "Fecha Final"}),
        Changed_Type = Table.TransformColumnTypes(Removed_Other_Columns,{{"EMPRESA", type text}, {"DEPARTAMENTO", type text}, {"AREA", type text}, {"AREA DE COBERTURA", type text}, {"CEDULA TECNICO", type text}, {"NOMBRE TECNICO", type text}, {"TIPO CUADRILLA", type text}, {"ID RECURSO TOA", type text}, {"CEDULA AUXILIAR", type text}, {"NOMBRE AUXILIAR", type text}, {"PROYECTO", type text}, {"HABILIDAD", type text}, {"CEDULA AUX GESTION", type text}, {"AUXILIAR DE GESTION", type text}, {"CEDULA SUPERVISOR", type text}, {"SUPERVISOR", type text}, {"CEDULA LIDER ", type text}, {"LIDER DE GESTION", type text}, {"CEDULA PROFESIONAL", type text}, {"PROFESIONAL", type text}, {"Fecha Inicial", type date}, {"Fecha Final", type date}}),
        Replaced_To_Null_1 = Table.ReplaceValue(Changed_Type,"NO TIENE",null,Replacer.ReplaceValue,{"EMPRESA", "DEPARTAMENTO", "AREA", "AREA DE COBERTURA", "CEDULA TECNICO", "NOMBRE TECNICO", "CEDULA AUXILIAR", "NOMBRE AUXILIAR", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "CEDULA LIDER ", "LIDER DE GESTION", "CEDULA PROFESIONAL", "PROFESIONAL"}),
        Replaced_To_Null_2 = Table.ReplaceValue(Replaced_To_Null_1,"0",null,Replacer.ReplaceValue,{"EMPRESA", "DEPARTAMENTO", "AREA", "AREA DE COBERTURA", "CEDULA TECNICO", "NOMBRE TECNICO", "CEDULA AUXILIAR", "NOMBRE AUXILIAR", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "CEDULA LIDER ", "LIDER DE GESTION", "CEDULA PROFESIONAL", "PROFESIONAL"}),
        Replaced_To_Null_3 = Table.ReplaceValue(Replaced_To_Null_2,"NA",null,Replacer.ReplaceValue,{"EMPRESA", "DEPARTAMENTO", "AREA", "AREA DE COBERTURA", "CEDULA TECNICO", "NOMBRE TECNICO", "CEDULA AUXILIAR", "NOMBRE AUXILIAR", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "CEDULA LIDER ", "LIDER DE GESTION", "CEDULA PROFESIONAL", "PROFESIONAL"}),
        Replaced_To_Null_4 = Table.ReplaceValue(Replaced_To_Null_3,"",null,Replacer.ReplaceValue,{"EMPRESA", "DEPARTAMENTO", "AREA", "AREA DE COBERTURA", "CEDULA TECNICO", "NOMBRE TECNICO", "CEDULA AUXILIAR", "NOMBRE AUXILIAR", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "CEDULA LIDER ", "LIDER DE GESTION", "CEDULA PROFESIONAL", "PROFESIONAL"}),
        Replaced_To_Null_5 = Table.ReplaceValue(Replaced_To_Null_4,"NO APLICA",null,Replacer.ReplaceValue,{"EMPRESA", "DEPARTAMENTO", "AREA", "AREA DE COBERTURA", "CEDULA TECNICO", "NOMBRE TECNICO", "CEDULA AUXILIAR", "NOMBRE AUXILIAR", "CEDULA AUX GESTION", "AUXILIAR DE GESTION", "CEDULA SUPERVISOR", "SUPERVISOR", "CEDULA LIDER ", "LIDER DE GESTION", "CEDULA PROFESIONAL", "PROFESIONAL"}),
        Replaced_Null_Name_Liteyca = Table.ReplaceValue(Replaced_To_Null_5,null,"Liteyca",Replacer.ReplaceValue,{"NOMBRE TECNICO", "AUXILIAR DE GESTION", "SUPERVISOR", "LIDER DE GESTION", "PROFESIONAL"}),
        Trimmed_Text = Table.TransformColumns(Replaced_Null_Name_Liteyca,{{"EMPRESA", Text.Trim, type text}, {"DEPARTAMENTO", Text.Trim, type text}, {"AREA", Text.Trim, type text}, {"AREA DE COBERTURA", Text.Trim, type text}, {"NOMBRE TECNICO", Text.Trim, type text}, {"TIPO CUADRILLA", Text.Trim, type text}, {"NOMBRE AUXILIAR", Text.Trim, type text}, {"PROYECTO", Text.Trim, type text}, {"HABILIDAD", Text.Trim, type text}, {"AUXILIAR DE GESTION", Text.Trim, type text}, {"SUPERVISOR", Text.Trim, type text}, {"LIDER DE GESTION", Text.Trim, type text}, {"PROFESIONAL", Text.Trim, type text}}),
        Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"EMPRESA", Text.Clean, type text}, {"DEPARTAMENTO", Text.Clean, type text}, {"AREA", Text.Clean, type text}, {"AREA DE COBERTURA", Text.Clean, type text}, {"NOMBRE TECNICO", Text.Clean, type text}, {"TIPO CUADRILLA", Text.Clean, type text}, {"NOMBRE AUXILIAR", Text.Clean, type text}, {"PROYECTO", Text.Clean, type text}, {"HABILIDAD", Text.Clean, type text}, {"AUXILIAR DE GESTION", Text.Clean, type text}, {"SUPERVISOR", Text.Clean, type text}, {"LIDER DE GESTION", Text.Clean, type text}, {"PROFESIONAL", Text.Clean, type text}}),
        Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"EMPRESA", Text.Proper, type text}, {"DEPARTAMENTO", Text.Proper, type text}, {"AREA", Text.Proper, type text}, {"AREA DE COBERTURA", Text.Proper, type text}, {"NOMBRE TECNICO", Text.Proper, type text}, {"TIPO CUADRILLA", Text.Proper, type text}, {"NOMBRE AUXILIAR", Text.Proper, type text}, {"PROYECTO", Text.Proper, type text}, {"HABILIDAD", Text.Proper, type text}, {"AUXILIAR DE GESTION", Text.Proper, type text}, {"SUPERVISOR", Text.Proper, type text}, {"LIDER DE GESTION", Text.Proper, type text}, {"PROFESIONAL", Text.Proper, type text}}),
        Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"EMPRESA", "Contrata"}, {"DEPARTAMENTO", "Dep Cuadri"}, {"AREA", "AreaCuadri"}, {"CEDULA TECNICO", "CC Tec"}, {"NOMBRE TECNICO", "Nom Tec"}, {"AREA DE COBERTURA", "Cobertura"}, {"TIPO CUADRILLA", "Tipo Cuadrilla"}, {"ID RECURSO TOA", "Id TOA"}, {"CEDULA AUXILIAR", "CC Aux"}, {"NOMBRE AUXILIAR", "Nom Aux"}, {"PROYECTO", "Proyecto"}, {"HABILIDAD", "Habilidad"}, {"CEDULA AUX GESTION", "CC Gestor"}, {"AUXILIAR DE GESTION", "Nom Gestor"}, {"CEDULA SUPERVISOR", "CC Super"}, {"SUPERVISOR", "Nom Super"}, {"CEDULA LIDER ", "CC Lider"}, {"LIDER DE GESTION", "Nom Lider"}, {"CEDULA PROFESIONAL", "CC Profesional"}, {"PROFESIONAL", "Nom Profesional"}}),
        Filtered_Null_CC_Tec = Table.SelectRows(Renamed_Columns, each [CC Tec] <> null and [CC Tec] <> ""),
        Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_CC_Tec, {"Dep Cuadri"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
        Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Dep Cuadri] <> null and [Dep Cuadri] <> ""),
        Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
        Removed_Duplicates = Table.Distinct(Removed_Columns)
    in
        Removed_Duplicates,

    Personal_Sin_Cuadrillas = let
        My_Conformacion_Cuadrillas = Table.SelectColumns(Consolidado_Cuadrillas,{"Contrata", "Dep Cuadri", "AreaCuadri", "CC Tec", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Fecha Inicial", "Fecha Final", "Nom Aux", "CC Aux"}),
        Cuadrillas_Completas = fxMiCalendarioDia(My_Conformacion_Cuadrillas, "Fecha Inicial", "Fecha Final"),
        Consolidado_Produccion = Table.Combine({Produccion_Altas, Produccion_Mantenimiento}),
        Removed_Other_Columns = Table.SelectColumns(Consolidado_Produccion,{"Departamento", "CC Tec", "Fecha", "Baremos", "AreaCuadri", "Actividades"}),
        Replaced_Null_Bar_Act = Table.ReplaceValue(Removed_Other_Columns,null,0,Replacer.ReplaceValue,{"Baremos", "Actividades"}),
        Grouped_Rows_Produccion = Table.Group(Replaced_Null_Bar_Act, {"Departamento", "CC Tec", "Fecha"}, {{"Bar", each List.Sum([Baremos]), type nullable number}, {"Act", each List.Sum([Actividades]), type nullable number}}),
        Added_AreaCuadri = Table.AddColumn(Grouped_Rows_Produccion, "AreaCuadri", each if [Bar] >= [Act] then "INSTALACIONES" else "MANTENIMIENTO", type text),
        Merged_Cuadrillas = Table.NestedJoin(Added_AreaCuadri, {"Departamento", "CC Tec", "Fecha"}, Cuadrillas_Completas, {"Dep Cuadri", "CC Tec", "Fecha"}, "ConsolidadoCuadrillas", JoinKind.LeftAnti),
        Expanded_Cuadrillas = Table.ExpandTableColumn(Merged_Cuadrillas, "ConsolidadoCuadrillas", {"Contrata", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Nom Aux", "CC Aux"}, {"Contrata", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Nom Aux", "CC Aux"}),
        Replaced_Null_1 = Table.ReplaceValue(Expanded_Cuadrillas,null,"Liteyca",Replacer.ReplaceValue,{"Contrata", "Nom Tec", "Nom Gestor", "Nom Super", "Nom Aux"}),
        Replaced_Null_Tipo_Cuadrilla = Table.ReplaceValue(Replaced_Null_1,null,"M1",Replacer.ReplaceValue,{"Tipo Cuadrilla"}),
        Grouped_Rows = Table.Group(Replaced_Null_Tipo_Cuadrilla, {"Departamento", "CC Tec"}, {{"Fecha Inicial", each List.Min([Fecha]), type nullable date}, {"Fecha Final", each List.Max([Fecha]), type nullable date}, {"All", each _, type table [Departamento=text, CC Tec=nullable text, Fecha=nullable date, Bar=nullable number, Act=nullable number, AreaCuadri=text, Contrata=nullable text, Nom Tec=nullable text, Tipo Cuadrilla=nullable text, CC Gestor=nullable text, Nom Gestor=nullable text, CC Super=nullable text, Nom Super=nullable text, Nom Aux=nullable text, CC Aux=nullable text]}}),
        Expanded_All = Table.ExpandTableColumn(Grouped_Rows, "All", {"AreaCuadri", "Contrata", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Nom Aux", "CC Aux"}, {"AreaCuadri", "Contrata", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Nom Aux", "CC Aux"}),
        Renamed_Dep = Table.RenameColumns(Expanded_All,{{"Departamento", "Dep Cuadri"}}),
        Removed_Duplicates = Table.Distinct(Renamed_Dep)
    in
        Removed_Duplicates,

    Cuadrillas_Sin_Produccion = let
        My_Produccion = Table.Combine({Produccion_Altas, Produccion_Mantenimiento}),
        Source = let
            Source = Consolidado_Cuadrillas,
            Removed_Other_Columns = Table.SelectColumns(Source,{"Contrata", "Dep Cuadri", "AreaCuadri", "CC Tec", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Fecha Inicial", "Fecha Final", "Nom Aux", "CC Aux"}),
            Appended_Query = Table.Combine({Removed_Other_Columns, Personal_Sin_Cuadrillas}),
            fxMyCalendario = fxMiCalendarioDia(Appended_Query, "Fecha Inicial", "Fecha Final"),
            Removed_Duplicates = Table.Distinct(fxMyCalendario)
        in
            Removed_Duplicates,
        Selected_Columns = Table.SelectColumns(Source,{"Dep Cuadri", "CC Tec", "Fecha"}),
        Merged_Produccion = Table.NestedJoin(Selected_Columns, {"Dep Cuadri", "CC Tec", "Fecha"}, My_Produccion, {"Departamento", "CC Tec", "Fecha"}, "Produccion", JoinKind.LeftAnti),
        Expanded_Produccion = Table.ExpandTableColumn(Merged_Produccion, "Produccion", {"Atiempo", "Atis", "Tipo Orden", "Tipo Tarea", "Medio de Acceso", "Baremos", "AreaCuadri", "Actividades"}, {"Atiempo", "Atis", "Tipo Orden", "Tipo Tarea", "Medio de Acceso", "Baremos", "AreaCuadri", "Actividades"}),
        Filtered_Null_Dep = Table.SelectRows(Expanded_Produccion, each [Dep Cuadri] <> null and [Dep Cuadri] <> ""),
        Renamed_Departamento = Table.RenameColumns(Filtered_Null_Dep,{{"Dep Cuadri", "Departamento"}}),
        Replaced_Null_Bar_Act = Table.ReplaceValue(Renamed_Departamento,null,0,Replacer.ReplaceValue,{"Baremos", "Actividades"}),
        Added_Recuento = Table.AddColumn(Replaced_Null_Bar_Act, "Recuento", each 1, Int64.Type),
        Added_Dia_Trabajado = Table.AddColumn(Added_Recuento, "DiaTrabajado", each 1, type number),
        Removed_Duplicates = Table.Distinct(Added_Dia_Trabajado)
    in
        Removed_Duplicates,

    Rangos_Tesa = let
        Source = Produccion,
        Removed_Columns = Table.RemoveColumns(Source,{"AreaCuadri"}),
        Inserted_Year = Table.AddColumn(Removed_Columns, "Año", each Date.Year([Fecha]), Int64.Type),
        Inserted_Month = Table.AddColumn(Inserted_Year, "Mes", each Date.Month([Fecha]), Int64.Type),
        Merged_Cuadrillas = Table.NestedJoin(Inserted_Month, {"CC Tec", "Fecha"}, Cuadrillas, {"CC Tec", "Fecha"}, "Cuadrillas", JoinKind.LeftOuter),
        Expanded_Cuadrillas = Table.ExpandTableColumn(Merged_Cuadrillas, "Cuadrillas", {"AreaCuadri", "Contrata", "Dep Cuadri", "Nom Gestor", "Nom Super"}, {"AreaCuadri", "Contrata", "Dep Cuadri", "Nom Gestor", "Nom Super"}),
        Replaced_Null_Columns = Table.ReplaceValue(Expanded_Cuadrillas,null,"Liteyca",Replacer.ReplaceValue,{"Nom Gestor", "Nom Super", "AreaCuadri", "Contrata"}),
        Replaced_Null_Dep_Cuadri_to_Departamento = Table.ReplaceValue(Replaced_Null_Columns,null, each [Departamento],Replacer.ReplaceValue,{"Dep Cuadri"}),
        Added_Area = Table.AddColumn(Replaced_Null_Dep_Cuadri_to_Departamento, "Area", each if [Tipo Orden] = "AVERIA" then "Mantenimiento" else "Instalaciones", type text),
        Select_Columns = Table.SelectColumns(Added_Area,{"Departamento", "CC Tec", "Fecha", "Año", "Mes", "AreaCuadri", "Contrata", "Dep Cuadri", "Nom Gestor", "Nom Super", "Area"}),
        Removed_Duplicates = Table.Distinct(Select_Columns),
        Grouped_Rows_Dias_Tabajo = Table.Group(Removed_Duplicates, {"Departamento", "Area", "CC Tec", "Año", "Mes", "Nom Gestor", "Nom Super", "AreaCuadri", "Dep Cuadri", "Contrata"}, {{"Dias Trabajado", each Table.RowCount(_), Int64.Type}}),
        Added_Puntos_Base_Added_Area = Table.AddColumn(Added_Area, "Puntos", each if [Area] = "Instalaciones" then [Baremos] else [Actividades]* 1.3, type number),
        Grouped_Rows_Puntos = Table.Group(Added_Puntos_Base_Added_Area, {"Departamento", "Area", "CC Tec", "Año", "Mes", "Nom Gestor", "Nom Super", "AreaCuadri", "Dep Cuadri", "Contrata"}, {{"Puntos", each List.Sum([Puntos]), type number}}),
        Merged_Group_Dias_Tabajo = Table.NestedJoin(Grouped_Rows_Puntos, {"Departamento", "Area", "CC Tec", "Año", "Mes", "Nom Gestor", "Nom Super", "AreaCuadri", "Dep Cuadri", "Contrata"}, Grouped_Rows_Dias_Tabajo, {"Departamento", "Area", "CC Tec", "Año", "Mes", "Nom Gestor", "Nom Super", "AreaCuadri", "Dep Cuadri", "Contrata"}, "RangosTesa", JoinKind.LeftOuter),
        Expanded_Dias_Trabajo = Table.ExpandTableColumn(Merged_Group_Dias_Tabajo, "RangosTesa", {"Dias Trabajado"}, {"Dias Trabajado"}),
        Added_Diario_Puntos = Table.AddColumn(Expanded_Dias_Trabajo, "Diario Puntos", each [Puntos]/[Dias Trabajado], type number),
        Merged_Limites_Rangos_Tesa = Table.NestedJoin(Added_Diario_Puntos, {"AreaCuadri", "Año", "Mes"}, Limites_Rangos_Tesa, {"Area", "Año", "Mes"}, "Limites_Rangos_Tesa", JoinKind.LeftOuter),
        Expanded_Limites_Rangos_Tesa = Table.ExpandTableColumn(Merged_Limites_Rangos_Tesa, "Limites_Rangos_Tesa", {"Valor Alto", "Valor Bajo"}, {"Valor Alto", "Valor Bajo"}),
        Replaced_Null_Valor_Alto = Table.ReplaceValue(Expanded_Limites_Rangos_Tesa,null,7.5,Replacer.ReplaceValue,{"Valor Alto"}),
        Replaced_Null_Valor_Bajo = Table.ReplaceValue(Replaced_Null_Valor_Alto,null,6.5,Replacer.ReplaceValue,{"Valor Bajo"}),
        Added_Clasificacion = Table.AddColumn(Replaced_Null_Valor_Bajo, "Clasificacion", each if [Diario Puntos] >= [Valor Alto] then "Alto" else if [Diario Puntos] <= [Valor Bajo] then "Bajo" else "Medio", type text),
        Added_Clasificacion_Insta = Table.AddColumn(Added_Clasificacion, "ClasificacionInsta", each if [Diario Puntos] >= [Valor Alto] then "Alto" else if [Diario Puntos] <= [Valor Bajo] then "Bajo" else "Medio", type text),
        Added_Orden = Table.AddColumn(Added_Clasificacion_Insta, "Orden", each if [Clasificacion] = "Bajo" then 1 else if [Clasificacion] = "Medio" then 2 else if [Clasificacion] = "Alto" then 3 else 4, type number),
        Added_Mes_Año = Table.AddColumn(Added_Orden, "Mes Año", each Text.From([Año]) & " " & Text.From([Mes]), type text),
        Merged_Acceso_Cuadrillas = Table.NestedJoin(Added_Mes_Año, {"CC Tec", "Año", "Mes"}, AccesosCuadrillas_2, {"CCTec", "Año", "Mes"}, "AccesosCuadrillas", JoinKind.LeftOuter),
        Expanded_Acceso_Cuadrillas = Table.ExpandTableColumn(Merged_Acceso_Cuadrillas, "AccesosCuadrillas", {"Acceso", "Cargo"}, {"Acceso", "Cargo"}),
        Replaced_Null_Acceso = Table.ReplaceValue(Expanded_Acceso_Cuadrillas,null,"9999999999",Replacer.ReplaceValue,{"Acceso"}),
        Replaced_Null_Cargo = Table.ReplaceValue(Replaced_Null_Acceso,null,"Admin",Replacer.ReplaceValue,{"Cargo"}),
        Removed_Duplicates_Final = Table.Distinct(Replaced_Null_Cargo)
    in
        Removed_Duplicates_Final,

    Cuadrillas = let
        Source = Consolidado_Cuadrillas,
        Removed_Other_Columns = Table.SelectColumns(Source,{"Contrata", "Dep Cuadri", "AreaCuadri", "CC Tec", "Nom Tec", "Tipo Cuadrilla", "CC Gestor", "Nom Gestor", "CC Super", "Nom Super", "Fecha Inicial", "Fecha Final", "Nom Aux", "CC Aux"}),
        Appended_Personal_Sin_Cuadrillas = Table.Combine({Removed_Other_Columns, Personal_Sin_Cuadrillas}),
        fxMyCalendario = fxMiCalendarioFinal(Appended_Personal_Sin_Cuadrillas, "Fecha Inicial", "Fecha Final"),
        Added_Tipo_Empresa = Table.AddColumn(fxMyCalendario, "Tipo Empresa", each if [Contrata] = "Liteyca" then "Propio" else "Contratista", type text),
        Merged_Acceso_Cuadrillas = Table.NestedJoin(Added_Tipo_Empresa, {"CC Tec", "Dep Cuadri", "Fecha"}, AccesosCuadrillas_2, {"CCTec", "Departamento", "Fecha"}, "AccesosCuadrillas_2", JoinKind.LeftOuter),
        Expanded_Acceso_Cuadrillas = Table.ExpandTableColumn(Merged_Acceso_Cuadrillas, "AccesosCuadrillas_2", {"Acceso", "Cargo", "ApuCuadrilla"}, {"Acceso", "Cargo", "ApuCuadrilla"}),
        Replaced_Cargo = Table.ReplaceValue(Expanded_Acceso_Cuadrillas,null,"Admin",Replacer.ReplaceValue,{"Cargo"}),
        Replaced_Acceso = Table.ReplaceValue(Replaced_Cargo,null,"9999999999",Replacer.ReplaceValue,{"Acceso"}),
        Replaced_Apu_Cuadrilla = Table.ReplaceValue(Replaced_Acceso,null,0,Replacer.ReplaceValue,{"ApuCuadrilla"}),
        Merged_Tbl_Bonos = Table.NestedJoin(Replaced_Apu_Cuadrilla, {"Cargo", "AreaCuadri", "Tipo Cuadrilla", "Año", "Mes"}, Tbl_Bonos, {"Cargo", "CuadrillaArea", "TipoCuadrilla", "Año", "Mes"}, "TblBonos", JoinKind.LeftOuter),
        Expanded_Tbl_Bonos = Table.ExpandTableColumn(Merged_Tbl_Bonos, "TblBonos", {"BonoCuadrilla", "IncrementoBono", "MetaMes", "Salario", "Max Porc Bono", "Parte Presta", "Parte Cuadri 2 Per", "Aux.Salario", "Aux.Max Porc Bono", "Aux.Parte Presta", "Aux.Parte Cuadri 2 Per"}, {"BonoCuadrilla", "IncrementoBono", "MetaMes", "Salario", "Max Porc Bono", "Parte Presta", "Parte Cuadri 2 Per", "Aux.Salario", "Aux.Max Porc Bono", "Aux.Parte Presta", "Aux.Parte Cuadri 2 Per"}),
        Merged_Meta_Mostrar = Table.NestedJoin(Expanded_Tbl_Bonos, {"Dep Cuadri", "AreaCuadri", "Tipo Cuadrilla", "Año", "Mes"}, Tbl_Meta_Mostrar, {"Departamento", "CuadrillaArea", "Tipo", "Año", "Mes"}, "TblMetaMostrar", JoinKind.LeftOuter),
        Expanded_Meta_Mostrar = Table.ExpandTableColumn(Merged_Meta_Mostrar, "TblMetaMostrar", {"MetaMostrar"}, {"Pre.MetaMostrar"}),
        Filtered_Null_Fecha = Table.SelectRows(Expanded_Meta_Mostrar , each [Fecha] <> null and [Fecha] <> "")
    in
        Filtered_Null_Fecha,

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
in
    Rangos_Tesa