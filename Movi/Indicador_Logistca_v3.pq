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
        #"Filtered Rows" = Source{[Item="TblDepartamentos"]}[Data],
        Trimmed_Departamento = Table.TransformColumns(#"Filtered Rows",{{"Departamento", Text.Trim, type text}}),
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

    Indicador_Odisea = let
        Source = Table.Combine({Produccion_Altas, Produccion_Mantenimiento}),
        Inserted_Year = Table.AddColumn(Source, "Año", each Date.Year([Fecha]), Int64.Type),
        Inserted_Month = Table.AddColumn(Inserted_Year, "Mes", each Date.Month([Fecha]), Int64.Type),
        Grouped_Rows = Table.Group(Inserted_Month, {"CC Tec", "Año", "Mes"}, {{"Total", each Table.RowCount(_), Int64.Type}}),
        Merged_Gestion_Odisea = Table.NestedJoin(Grouped_Rows, {"CC Tec", "Año", "Mes"}, Gestion_Odisea, {"Identificacion", "Año", "Mes"}, "Gestion_Odisea", JoinKind.LeftOuter),
        ExpandedGestion_Odisea = Table.ExpandTableColumn(Merged_Gestion_Odisea, "Gestion_Odisea", {"Sin Gestion", "All"}, {"Sin Gestion", "All"}),
        Replaced_Null_Sin_Gestion = Table.ReplaceValue(ExpandedGestion_Odisea,null,0,Replacer.ReplaceValue,{"Sin Gestion"}),
        Merged_Parametro_Nota = Table.NestedJoin(Replaced_Null_Sin_Gestion, {"Año", "Mes"}, Parametro_Nota, {"Año", "Mes"}, "Parametro_Nota", JoinKind.LeftOuter),
        Expanded_Parametro_Nota = Table.ExpandTableColumn(Merged_Parametro_Nota, "Parametro_Nota", {"Ind Odisea"}, {"Ind Odisea"}),
        Added_Porcentaje_Cumple = Table.AddColumn(Expanded_Parametro_Nota, "% Cumple", each [Sin Gestion]/[Total], type number),
        Added_Indicador = Table.AddColumn(Added_Porcentaje_Cumple, "Indicador", each if([#"% Cumple"]<=[Ind Odisea])then("Cumple")else("No Cumple"), type text),
        Expanded_All = Table.ExpandTableColumn(Added_Indicador, "All", {"Fecha Caso", "Pedido_Atis", "Estado Odisea", "Dias"}, {"Fecha Caso", "Pedido_Atis", "Estado Odisea", "Dias"}),
        Added_Indicador_Logistica = Table.AddColumn(Expanded_All, "Indicador Log", each "Odisea", type text),
        Removed_Columns = Table.RemoveColumns(Added_Indicador_Logistica,{"Total", "Sin Gestion", "Ind Odisea"})
    in
        Removed_Columns,

    Gestion_Odisea = let
        Source = ProduccionTecnicos,
        Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".xlsx")),
        Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\Logistica\GestionODISEA\")),
        Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], ".", " "), type text),
        Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BeforeDelimiter([Name], "."), type text),
        Added_Fecha = Table.AddColumn(Added_Mes, "Fecha", each Text.Combine({[Mes], [Año]}, "/"), type text),
        Parsed_Date_Fecha = Table.TransformColumns(Added_Fecha,{{"Fecha", each Date.EndOfMonth(Date.From(DateTimeZone.From(_))), type date}}),
        Changed_Type_Date = Table.TransformColumnTypes(Parsed_Date_Fecha,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
        Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
        Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
        Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Excel.Workbook(_)}),
        Expanded_Content = Table.ExpandTableColumn(Transform_Content, "Content", {"Name", "Data", "Kind"}, {"Content.Name", "Content.Data", "Content.Kind"}),
        Filtered_Kind = Table.SelectRows(Expanded_Content, each ([Content.Kind] = "Table")),
        Removed_Other_Columns = Table.SelectColumns(Filtered_Kind,{"Content.Data", "Año", "Mes", "Fecha"}),
        Expanded_Content_data = Table.ExpandTableColumn(Removed_Other_Columns, "Content.Data", {"Fecha_Cierre", "Identificacion", "Departamento", "Actuacion", "Pedido_Atis", "ESTADO ORDEN"}, {"Fecha_Cierre", "Identificacion", "Departamento", "Actuacion", "Pedido_Atis", "ESTADO ORDEN"}),
        Filtered_Null_Fecha = Table.SelectRows(Expanded_Content_data, each [Fecha_Cierre] <> null and [Fecha_Cierre] <> ""),
        Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"Fecha_Cierre", each Date.From(Value.FromText(_)), type date}}),
        Changed_Type = Table.TransformColumnTypes(Transform_Fecha,{{"Fecha_Cierre", type date}, {"Identificacion", type text}, {"Departamento", type text}, {"Actuacion", type text}, {"Pedido_Atis", type text}, {"ESTADO ORDEN", type text}}),
        Trimmed_Text = Table.TransformColumns(Changed_Type,{{"Identificacion", Text.Trim, type text}, {"Departamento", Text.Trim, type text}, {"Actuacion", Text.Trim, type text}, {"Pedido_Atis", Text.Trim, type text}, {"ESTADO ORDEN", Text.Trim, type text}}),
        Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Identificacion", Text.Clean, type text}, {"Departamento", Text.Clean, type text}, {"Actuacion", Text.Clean, type text}, {"Pedido_Atis", Text.Clean, type text}, {"ESTADO ORDEN", Text.Clean, type text}}),
        Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Departamento", Text.Proper, type text}, {"ESTADO ORDEN", Text.Proper, type text}}),
        Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"ESTADO ORDEN", "Estado Odisea"}, {"Fecha_Cierre", "Fecha Caso"}}),
        Filtered_Null_Atis = Table.SelectRows(Renamed_Columns, each [Pedido_Atis] <> null and [Pedido_Atis] <> ""),
        Filtered_Null_CC_Tec = Table.SelectRows(Filtered_Null_Atis, each [Identificacion] <> null and [Identificacion] <> ""),
        Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_CC_Tec, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
        Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
        Removed_Columns = Table.RemoveColumns(Filtered_Null_Dep,{"TblDepartamentos"}),
        Removed_Duplicates = Table.Distinct(Removed_Columns),
        Added_Dias_Orden = Table.AddColumn(Removed_Duplicates, "Dias", each if(Date.Month([Fecha])=Date.Month(Date.From(DateTime.LocalNow())))and(Date.Year([Fecha])=Date.Year(Date.From(DateTime.LocalNow())))then(Date.From(DateTime.LocalNow())-Date.From([Fecha Caso]))else([Fecha]-Date.From([Fecha Caso]))),
        Extracted_Days_Orden = Table.TransformColumns(Added_Dias_Orden,{{"Dias", Duration.Days, Int64.Type}}),
        Grouped_Rows = Table.Group(Extracted_Days_Orden, {"Identificacion", "Año", "Mes"}, {{"Sin Gestion", each Table.RowCount(_), Int64.Type}, {"All", each _, type table [Fecha Caso=nullable date, Identificacion=text, Departamento=text, Actuacion=text, Pedido_Atis=text, Estado Odisea=text, Año=nullable number, Mes=nullable number, Fecha=date, Dias=number]}})
    in
        Grouped_Rows,

    Parametro_Nota = let
        Source = Tablas_Base,
        Filtered_Rows = Source{[Item="ParametroNota"]}[Data],
        Invoke_fxCalendario_Mes = fxMiCalendarioMes(Filtered_Rows, "FechaInicio", "FechaFin"),
        Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Mes, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
        Removed_Column_Mes_Act = Table.RemoveColumns(Merged_Mes_Act,{"Mes_Actualizar"}),
        Removed_Duplicates = Table.Distinct(Removed_Column_Mes_Act)
    in
        Removed_Duplicates,

    Series_Siscos = let
        Source = ProduccionTecnicos,
        Filtered_Extension = Table.SelectRows(Source, each ([Extension] = ".xlsx")),
        Filtered_Folder_Path = Table.SelectRows(Filtered_Extension, each Text.Contains([Folder Path], "\CalculoBonificacion\Logistica\SeriesEnCalleSISCOS\") and not Text.Contains([Folder Path], "CuadroMando")),
        Added_Year = Table.AddColumn(Filtered_Folder_Path, "Año", each Text.BetweenDelimiters([Name], ".", " "), type text),
        Added_Mes = Table.AddColumn(Added_Year, "Mes", each Text.BeforeDelimiter([Name], "."), type text),
        Added_Fecha = Table.AddColumn(Added_Mes, "Fecha", each Text.Combine({[Mes], [Año]}, "/"), type text),
        Parsed_Date_Fecha = Table.TransformColumns(Added_Fecha,{{"Fecha", each Date.EndOfMonth(Date.From(DateTimeZone.From(_))), type date}}),
        Changed_Type_Date = Table.TransformColumnTypes(Parsed_Date_Fecha,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
        Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
        Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
        Transform_Content = Table.TransformColumns(Filtered_Null_Name, {"Content", each Excel.Workbook(_)}),
        Expanded_Content = Table.ExpandTableColumn(Transform_Content, "Content", {"Name", "Data", "Kind"}, {"Content.Name", "Content.Data", "Content.Kind"}),
        Filtered_Kind = Table.SelectRows(Expanded_Content, each ([Content.Kind] = "Table")),
        Removed_Other_Columns = Table.SelectColumns(Filtered_Kind,{"Content.Data", "Año", "Mes", "Fecha"}),
        Expanded_Content_data = Table.ExpandTableColumn(Removed_Other_Columns, "Content.Data", {"DEPARTAMENTO", "codigo_material", "descriocion_material", "tipo_material", "cedula_tecnico", "serial", "fecha_entrega"}, {"DEPARTAMENTO", "codigo_material", "descriocion_material", "tipo_material", "cedula_tecnico", "serial", "fecha_entrega"}),
        Filtered_Null_Fecha = Table.SelectRows(Expanded_Content_data, each [fecha_entrega] <> null and [fecha_entrega] <> ""),
        Transform_Fecha = Table.TransformColumns(Filtered_Null_Fecha,{{"fecha_entrega", each Date.From(Value.FromText(_)), type date}}),
        Changed_Type = Table.TransformColumnTypes(Transform_Fecha,{{"codigo_material", type text}, {"descriocion_material", type text}, {"tipo_material", type text}, {"cedula_tecnico", type text}, {"serial", type text}, {"fecha_entrega", type date}, {"DEPARTAMENTO", type text}}),
        #"Trimmed Text" = Table.TransformColumns(Changed_Type,{{"codigo_material", Text.Trim, type text}, {"descriocion_material", Text.Trim, type text}, {"tipo_material", Text.Trim, type text}, {"cedula_tecnico", Text.Trim, type text}, {"serial", Text.Trim, type text}, {"DEPARTAMENTO", Text.Trim, type text}}),
        #"Cleaned Text" = Table.TransformColumns(#"Trimmed Text",{{"codigo_material", Text.Clean, type text}, {"descriocion_material", Text.Clean, type text}, {"tipo_material", Text.Clean, type text}, {"cedula_tecnico", Text.Clean, type text}, {"serial", Text.Clean, type text}, {"DEPARTAMENTO", Text.Clean, type text}}),
        Capitalized_Each_Word = Table.TransformColumns(#"Cleaned Text",{{"DEPARTAMENTO", Text.Proper, type text}}),
        Renamed_Columns = Table.RenameColumns(Capitalized_Each_Word,{{"DEPARTAMENTO", "Departamento"}, {"codigo_material", "Cod Mat"}, {"descriocion_material", "Material"}, {"cedula_tecnico", "CC Tec"}, {"serial", "Serial"}, {"fecha_entrega", "Fecha Caso"}}),
        Filtered_Null_Serial = Table.SelectRows(Renamed_Columns, each [Serial] <> null and [Serial] <> ""),
        Filtered_Null_CC_Tec = Table.SelectRows(Filtered_Null_Serial, each [CC Tec] <> null and [CC Tec] <> ""),
        Merged_Tbl_Departamentos = Table.NestedJoin(Filtered_Null_CC_Tec, {"Departamento"}, Tbl_Departamentos, {"Departamento"}, "TblDepartamentos", JoinKind.RightOuter),
        Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Departamentos, each [Departamento] <> null and [Departamento] <> ""),
        Added_Indicador_Logistica = Table.AddColumn(Filtered_Null_Dep, "Indicador Log", each if([tipo_material]="MATERIAL MOVISTAR")then("Rotacion")else("Reintegro"), type text),
        Removed_Columns = Table.RemoveColumns(Added_Indicador_Logistica,{"TblDepartamentos", "tipo_material"}),
        Removed_Duplicates = Table.Distinct(Removed_Columns),
        Added_Dias_Calle = Table.AddColumn(Removed_Duplicates, "Dias", each if(Date.Month([Fecha])=Date.Month(Date.From(DateTime.LocalNow())))then(Date.From(DateTime.LocalNow())-Date.From([Fecha Caso]))else([Fecha]-Date.From([Fecha Caso]))),
        Extracted_Days_Calle = Table.TransformColumns(Added_Dias_Calle,{{"Dias", Duration.Days, Int64.Type}}),
        Added_Cantidad = Table.AddColumn(Extracted_Days_Calle, "Cantidad", each 1, type number),
        Merged_Tecnicos_Localidad = Table.NestedJoin(Added_Cantidad, {"CC Tec", "Año", "Mes"}, Tecnicos_Localidad, {"CEDULA", "Año", "Mes"}, "Tecnicos_Localidad", JoinKind.LeftOuter),
        Expanded_Tecnicos_Localidad = Table.ExpandTableColumn(Merged_Tecnicos_Localidad, "Tecnicos_Localidad", {"Tipo Tecnico"}, {"Tipo Tecnico"}),
        Replaced_Null_Tipo_Tecnico = Table.ReplaceValue(Expanded_Tecnicos_Localidad,null,"Bodega",Replacer.ReplaceValue,{"Tipo Tecnico"}),
        Merged_Valor_Material = Table.NestedJoin(Replaced_Null_Tipo_Tecnico, {"Cod Mat", "Año", "Mes"}, Valor_Materiales, {"codigo_material", "Año", "Mes"}, "Valor_Materiales", JoinKind.LeftOuter),
        Expanded_Valor_Material = Table.ExpandTableColumn(Merged_Valor_Material, "Valor_Materiales", {"Valor"}, {"Valor"}),
        Replaced_Null_Valor = Table.ReplaceValue(Expanded_Valor_Material,null,1,Replacer.ReplaceValue,{"Valor"}),
        Merged_Tiempos = Table.NestedJoin(Replaced_Null_Valor, {"Tipo Tecnico", "Indicador Log", "Año", "Mes", "Dias"}, Tiempos, {"Tipo Tecnico", "Tipo", "Año", "Mes", "Días"}, "Tiempos", JoinKind.LeftOuter),
        Expanded_Tiempos = Table.ExpandTableColumn(Merged_Tiempos, "Tiempos", {"Lapso", "Rango"}, {"Lapso", "Rango"}),
        Added_Cumplimiento = Table.AddColumn(Expanded_Tiempos, "Cumplimiento", each if([Lapso]="A Tiempo")then("Cumple")else("No Cumple"), type text),
        Pivoted_Cumplimiento = Table.Pivot(Added_Cumplimiento, List.Distinct(Added_Cumplimiento[Cumplimiento]), "Cumplimiento", "Cantidad", List.Sum),
        Replaced_Null_No_Cumple = try(Table.ReplaceValue(Pivoted_Cumplimiento,null,0,Replacer.ReplaceValue,{"No Cumple"}))otherwise(Table.AddColumn(Pivoted_Cumplimiento, "No Cumple", each 0, type number)),
        Replaced_Null_Cumple = try(Table.ReplaceValue(Replaced_Null_No_Cumple,null,0,Replacer.ReplaceValue,{"Cumple"}))otherwise(Table.AddColumn(Replaced_Null_No_Cumple, "Cumple", each 0, type number)),
        Grouped_Rows = Table.Group(Replaced_Null_Cumple, {"CC Tec", "Año", "Mes", "Indicador Log"}, {{"Cumple", each List.Sum([Cumple]), type nullable number}, {"No Cumple", each List.Sum([No Cumple]), type nullable number}, {"All", each _, type table [Departamento=text, Cod Mat=text, Material=text, CC Tec=text, Serial=text, Fecha Caso=nullable date, Año=nullable number, Mes=nullable number, Fecha=date, Indicador Log=text, Dias=number, Tipo Tecnico=nullable text, Valor=nullable number, Lapso=nullable text, Rango=nullable text, Cumple=nullable number, No Cumple=nullable number]}}),
        Merged_Parametro_Nota = Table.NestedJoin(Grouped_Rows, {"Año", "Mes"}, Parametro_Nota, {"Año", "Mes"}, "Parametro_Nota", JoinKind.LeftOuter),
        Expanded_Parametro_Nota = Table.ExpandTableColumn(Merged_Parametro_Nota, "Parametro_Nota", {"Rotacion", "Reintegro"}, {"Rotacion", "Reintegro"}),
        Added_Indicador = Table.AddColumn(Expanded_Parametro_Nota, "Indicador", each if([Indicador Log]="Rotacion")then(if([Rotacion]>=[No Cumple])then("Cumple")else("No Cumple"))else(if([Reintegro]>=[No Cumple])then("Cumple")else("No Cumple")), type text),
        Added_Porcentaje_Cumple = Table.AddColumn(Added_Indicador, "% Cumple", each 1-([No Cumple]/([Cumple]+[No Cumple])), type number),
        Expanded_All = Table.ExpandTableColumn(Added_Porcentaje_Cumple, "All", {"Cod Mat", "Material", "Serial", "Fecha Caso", "Dias", "Tipo Tecnico", "Valor", "Lapso", "Rango"}, {"Cod Mat", "Material", "Serial", "Fecha Caso", "Dias", "Tipo Tecnico", "Valor", "Lapso", "Rango"}),
        Removed_Columns_Final = Table.RemoveColumns(Expanded_All,{"Rotacion", "Reintegro", "Cumple", "No Cumple", "Tipo Tecnico"})
    in
        Removed_Columns_Final,

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

    Indicador_Logistica = let
        Source = Table.Combine({Indicador_Odisea, Series_Siscos}),
        Added_Cant_Cumple = Table.AddColumn(Source, "CanCumple", each if([Indicador]="Cumple")then(0)else(1), type number),
        Removed_Other_Columns = Table.SelectColumns(Added_Cant_Cumple,{"CC Tec", "Año", "Mes", "Indicador Log", "CanCumple"}),
        Removed_Duplicates = Table.Distinct(Removed_Other_Columns),
        Pivoted_Indicador_Log = Table.Pivot(Removed_Duplicates, List.Distinct(Removed_Duplicates[#"Indicador Log"]), "Indicador Log", "CanCumple", List.Sum),
        Replaced_Null_Odisea = try(Table.ReplaceValue(Pivoted_Indicador_Log,null,0,Replacer.ReplaceValue,{"Odisea"}))otherwise(Table.AddColumn(Pivoted_Indicador_Log, "Odisea", each 0, type number)),
        Replaced_Null_Rotacion = try(Table.ReplaceValue(Replaced_Null_Odisea,null,0,Replacer.ReplaceValue,{"Rotacion"}))otherwise(Table.AddColumn(Replaced_Null_Odisea, "Rotacion", each 0, type number)),
        Replaced_Null_Reintegro = try(Table.ReplaceValue(Replaced_Null_Rotacion,null,0,Replacer.ReplaceValue,{"Reintegro"}))otherwise(Table.AddColumn(Replaced_Null_Rotacion, "Reintegro", each 0, type number)),
        Added_Logistica = Table.AddColumn(Replaced_Null_Reintegro, "Logistica", each if(([Odisea]+[Rotacion]+[Reintegro])=0)then(0)else(1), type number),
        Unpivoted_Indicador_Log = Table.Unpivot(Added_Logistica, {"Odisea", "Rotacion", "Reintegro", "Logistica"}, "Indicador Log", "Estado Indicador"),
        Added_Estado = Table.AddColumn(Unpivoted_Indicador_Log, "Estado", each if [Estado Indicador] = 0 then "Cumple" else "No Cumple", type text),
        Removed_Estado_Indicador = Table.RemoveColumns(Added_Estado,{"Estado Indicador"}),
        Merged_Accesos = Table.NestedJoin(Removed_Estado_Indicador, {"CC Tec", "Año", "Mes"}, Cuadrillas_Bonificacion, {"CCTec", "Año", "Mes"}, "AccesosCuadrillas", JoinKind.LeftOuter),
        Expanded_Accesos = Table.ExpandTableColumn(Merged_Accesos, "AccesosCuadrillas", {"Acceso", "Cargo"}, {"Acceso", "Cargo"}),
        Replaced_Null_Acceso = Table.ReplaceValue(Expanded_Accesos,null,"9999999999",Replacer.ReplaceValue,{"Acceso"}),
        Replaced_Null_Cargo = Table.ReplaceValue(Replaced_Null_Acceso,null,"Admin",Replacer.ReplaceValue,{"Cargo"}),
        Removed_Duplicates_Final = Table.Distinct(Replaced_Null_Cargo),
        Removed_Other_Columns_Final = Table.SelectColumns(Removed_Duplicates_Final,{"CC Tec", "Año", "Mes", "Indicador Log", "Estado", "Acceso", "Cargo"})
    in
        Removed_Other_Columns_Final,

    AccesosCuadrillas_2 = let
        Source = Tablas_Base,
        #"Filtered Rows" = Source{[Item="AccesosCuadrillas_2"]}[Data],
        Trimmed_Text = Table.TransformColumns(#"Filtered Rows",{{"Area Cuadri", Text.Trim, type text}, {"Nom Super", Text.Trim, type text}, {"Nom Gestor", Text.Trim, type text}, {"Nom Tec", Text.Trim, type text}, {"Contrata", Text.Trim, type text}, {"Departamento", Text.Trim, type text}, {"Cargo", Text.Trim, type text}}),
        Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Area Cuadri", Text.Clean, type text}, {"Nom Super", Text.Clean, type text}, {"Nom Gestor", Text.Clean, type text}, {"Nom Tec", Text.Clean, type text}, {"Contrata", Text.Clean, type text}, {"Departamento", Text.Clean, type text}, {"Cargo", Text.Clean, type text}}),
        Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Area Cuadri", Text.Proper, type text}, {"Nom Super", Text.Proper, type text}, {"Nom Gestor", Text.Proper, type text}, {"Nom Tec", Text.Proper, type text}, {"Contrata", Text.Proper, type text}, {"Departamento", Text.Proper, type text}, {"Cargo", Text.Proper, type text}}),
        Invoke_fxCalendario_Dia = fxMiCalendarioDia(Capitalized_Each_Word, "FechaMin", "FechaMax"),
        Merged_Mes_Act = Table.NestedJoin(Invoke_fxCalendario_Dia, {"Mes", "Año"}, Mes_Actualizar, {"Mes", "Año"}, "Mes_Actualizar", JoinKind.RightOuter),
        Filtered_Null_Departamento = Table.SelectRows(Merged_Mes_Act, each [Departamento] <> null and [Departamento] <> ""),
        Removed_Column_Mes_Act = Table.RemoveColumns(Filtered_Null_Departamento,{"Mes_Actualizar"})
    in
        Removed_Column_Mes_Act,

    Cuadrillas_Bonificacion = let
        Source = AccesosCuadrillas_2,
        Removed_Date = Table.RemoveColumns(Source,{"Fecha"}),
        Removed_Duplicates = Table.Distinct(Removed_Date),
        Grouped_Rows = Table.Group(Removed_Duplicates, {"CCTec", "Acceso", "Cargo", "Departamento", "Año", "Mes"}, {{"Lineas", each Table.RowCount(_), Int64.Type}, {"All", each _, type table [CCTec=nullable text, Acceso=nullable text, Cargo=text, Departamento=text, Contrata=text, Nom Tec=text, Nom Gestor=text, Nom Super=text, Area Cuadri=text, ApuCuadrilla=nullable number, Año=number, Mes=number]}}),
        Expanded_All = Table.ExpandTableColumn(Grouped_Rows, "All", {"Contrata", "Nom Tec", "Nom Gestor", "Nom Super", "Area Cuadri", "ApuCuadrilla"}, {"Contrata", "Nom Tec", "Nom Gestor", "Nom Super", "Area Cuadri", "ApuCuadrilla"})
    in
        Expanded_All
in
    Indicador_Logistica