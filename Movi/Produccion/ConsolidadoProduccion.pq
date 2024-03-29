// ConsolidadoProduccion
let
// fxMyCalendarioFinal
    fxMyCalendarioFinal = let Source = 
        Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/fxMyCalendarioFinal.pq") ), #shared) in Source, 
// fxMyCalendarioDia
    fxMyCalendarioDia = let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/fxMyCalendarioDia.pq") ), #shared) in Source, 
// fxMyListaFechas
    fxMyfxListaFechas = let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/fxListaFechas.pq") ), #shared) in Source, 
// TblDepartamentos
    TblDepartamentos = let
        Source = Excel.Workbook(File.Contents(Ruta&"\VersionesBI\V12 Mac\Tablas Base V2.xlsx"), null, true),
        TblDepartamentos_Table = Source{[Item="TblDepartamentos",Kind="Table"]}[Data],
        Changed_Type = Table.TransformColumnTypes(TblDepartamentos_Table,{{"FechaInicio", type date}, {"FechaFin", type date}, {"Departamento", type text}, {"Zona", type text}, {"Latitud", type number}, {"Longitud", type number}}),
        Trimmed_Dep = Table.TransformColumns(Changed_Type,{{"Departamento", Text.Trim, type text}}),
        Cleaned_Dep = Table.TransformColumns(Trimmed_Dep,{{"Departamento", Text.Clean, type text}}),
        Capitalized_Dep = Table.TransformColumns(Cleaned_Dep,{{"Departamento", Text.Proper, type text}}),
        Call_My_Calendario = fxMyCalendarioDia(Capitalized_Dep, "FechaInicio", "FechaFin"),
        Merged_Mes_Year = Table.NestedJoin(Call_My_Calendario, {"Mes", "Año"}, Mes_Actu, {"Mes", "Año"}, "Mes_Actu", JoinKind.RightOuter)
    in
        Merged_Mes_Year, 
// ProduccionAltas
    ProduccionAltas = let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/Produccion/ProduccionAltas.pq") ), #shared),
        Trimmed_Dep = Table.TransformColumns(Source,{{"Departamento", Text.Trim, type text}}),
        Cleaned_Dep = Table.TransformColumns(Trimmed_Dep,{{"Departamento", Text.Clean, type text}}),
        Capitalized_Dep = Table.TransformColumns(Cleaned_Dep,{{"Departamento", Text.Proper, type text}}),
        Added_Area_Cuadri = Table.AddColumn(Capitalized_Dep, "AreaCuadri", each "INSTALACIONES", type text),
        Merged_Tbl_Dep = Table.NestedJoin(Added_Area_Cuadri, {"Departamento", "Fecha"}, TblDepartamentos, {"Departamento", "Fecha"}, "TblDepartamentos", JoinKind.RightOuter),
        Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Dep, each [Departamento] <> null and [Departamento] <> ""),
        Removed_Duplicates = Table.Distinct(Filtered_Null_Dep)
    in
        Removed_Duplicates, 
// ProduccionMantenimiento
    ProduccionMantenimiento = let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/Produccion/ProduccionMantenimiento.pq") ), #shared),
        Trimmed_Dep = Table.TransformColumns(Source,{{"Departamento", Text.Trim, type text}}),
        Cleaned_Dep = Table.TransformColumns(Trimmed_Dep,{{"Departamento", Text.Clean, type text}}),
        Capitalized_Dep = Table.TransformColumns(Cleaned_Dep,{{"Departamento", Text.Proper, type text}}),
        Added_Area_Cuadri = Table.AddColumn(Capitalized_Dep, "AreaCuadri", each "MANTENIMIENTO", type text),
        Merged_Tbl_Dep = Table.NestedJoin(Added_Area_Cuadri, {"Departamento", "Fecha"}, TblDepartamentos, {"Departamento", "Fecha"}, "TblDepartamentos", JoinKind.RightOuter),
        Filtered_Null_Dep = Table.SelectRows(Merged_Tbl_Dep, each [Departamento] <> null and [Departamento] <> ""),
        Removed_Duplicates = Table.Distinct(Filtered_Null_Dep)
    in 
        Removed_Duplicates, 
// ConsolidadoCuadrillas
    ConsolidadoCuadrillas = let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/Produccion/ConsolidadoCuadrillas.pq") ), #shared),
        Trimmed_Text = Table.TransformColumns(Source,{{"Departamento", Text.Trim, type text}}),
        Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Departamento", Text.Clean, type text}}),
        Capitalized_Each_Word = Table.TransformColumns(Cleaned_Text,{{"Departamento", Text.Proper, type text}})
    in
        Capitalized_Each_Word, 
// Personal_Sin_Cuadrillas
    Personal_Sin_Cuadrillas = let
        Conformacion_Cuadrillas = Table.SelectColumns(ConsolidadoCuadrillas,{"Contrata", "Departamento", "AreaCuadri", "CC", "Nom Tec", "Tipo Cuadrilla", "CC Gest", "Nom Gest", "CC Super", "Nom Super", "Fecha Inicial", "Fecha Final", "Nom Aux", "CC Aux"}),
        Cuadrillas_Completas = fxMyCalendarioFinal(Conformacion_Cuadrillas, "Fecha Inicial", "Fecha Final"),
        Source = Table.Combine({ProduccionAltas, ProduccionMantenimiento}),
        Selected_Columns = Table.SelectColumns(Source,{"Departamento", "CC Tec", "Fecha", "Baremos", "AreaCuadri", "Actividades"}),
        Replaced_Null_Bar_Act = Table.ReplaceValue(Selected_Columns,null,0,Replacer.ReplaceValue,{"Baremos", "Actividades"}),
        Grouped_Rows_Produccion = Table.Group(Replaced_Null_Bar_Act, {"Departamento", "CC Tec", "Fecha"}, {{"Bar", each List.Sum([Baremos]), type nullable number}, {"Act", each List.Sum([Actividades]), type nullable number}}),
        Added_AreaCuadri = Table.AddColumn(Grouped_Rows_Produccion, "AreaCuadri", each if [Bar] >= [Act] then "INSTALACIONES" else "MANTENIMIENTO", type text),
        Merged_Cuadrillas = Table.NestedJoin(Added_AreaCuadri, {"Departamento", "CC Tec", "Fecha"}, Cuadrillas_Completas, {"Departamento", "CC", "Fecha"}, "ConsolidadoCuadrillas", JoinKind.LeftAnti),
        Expanded_Cuadrillas = Table.ExpandTableColumn(Merged_Cuadrillas, "ConsolidadoCuadrillas", {"Contrata", "Nom Tec", "Tipo Cuadrilla", "CC Gest", "Nom Gest", "CC Super", "Nom Super", "Nom Aux", "CC Aux"}, {"Contrata", "Nom Tec", "Tipo Cuadrilla", "CC Gest", "Nom Gest", "CC Super", "Nom Super", "Nom Aux", "CC Aux"}),
        Replaced_Null_1 = Table.ReplaceValue(Expanded_Cuadrillas,null,"Liteyca",Replacer.ReplaceValue,{"Contrata", "Nom Tec", "Nom Gest", "Nom Super", "Nom Aux"}),
        Replaced_Null_2 = Table.ReplaceValue(Replaced_Null_1,null,"X_X",Replacer.ReplaceValue,{"Departamento", "CC Gest", "CC Super", "CC Aux"}),
        Replaced_Null_Tipo_Cuadrilla = Table.ReplaceValue(Replaced_Null_2,null,"M1",Replacer.ReplaceValue,{"Tipo Cuadrilla"}),
        Grouped_Rows = Table.Group(Replaced_Null_Tipo_Cuadrilla, {"Departamento", "CC Tec"}, {{"Fecha Inicial", each List.Min([Fecha]), type nullable date}, {"Fecha Final", each List.Max([Fecha]), type nullable date}, {"All", each _, type table [Departamento=nullable text, CC Tec=nullable text, Fecha=nullable date, AreaCuadri=text, Contrata=nullable text, Nom Tec=nullable text, Tipo Cuadrilla=nullable text, CC Gest=nullable text, Nom Gest=nullable text, CC Super=nullable text, Nom Super=nullable text, Nom Aux=nullable text, CC Aux=nullable text]}}),
        Expanded_All = Table.ExpandTableColumn(Grouped_Rows, "All", {"AreaCuadri", "Contrata", "Nom Tec", "Tipo Cuadrilla", "CC Gest", "Nom Gest", "CC Super", "Nom Super", "Nom Aux", "CC Aux"}, {"AreaCuadri", "Contrata", "Nom Tec", "Tipo Cuadrilla", "CC Gest", "Nom Gest", "CC Super", "Nom Super", "Nom Aux", "CC Aux"}),
        Renamed_Dep = Table.RenameColumns(Expanded_All,{{"Departamento", "Dep Cuadri"}}),
        Removed_Duplicates = Table.Distinct(Renamed_Dep)
    in
        Removed_Duplicates, 
// AccesosCuadrillas_2
    AccesosCuadrillas_2 = let
        Source = Excel.Workbook(File.Contents(Ruta&"\VersionesBI\V12 Mac\Tablas Base V2.xlsx"), null, true),
        AccesosCuadrillas_2_Table = Source{[Item="AccesosCuadrillas_2",Kind="Table"]}[Data],
        Changed_Type = Table.TransformColumnTypes(AccesosCuadrillas_2_Table,{{"CCTec", type text}, {"Acceso", type text}, {"Cargo", type text}, {"Año", Int64.Type}, {"Mes", Int64.Type}, {"Departamento", type text}, {"Contrata", type text}, {"Nom Tec", type text}, {"Nom Gestor", type text}, {"Nom Super", type text}, {"FechaMin", type date}, {"FechaMax", type date}, {"ApuCuadrilla", type number}}),
        Merged_Mes_Act = Table.NestedJoin(Changed_Type, {"Mes", "Año"}, Mes_Actu, {"Mes", "Año"}, "Mes_Actu", JoinKind.RightOuter),
        Filtered_Null_Year = Table.SelectRows(Merged_Mes_Act, each [Año] <> null and [Año] <> ""),
        Removed_Other_Columns = Table.SelectColumns(Filtered_Null_Year,{"CCTec", "Acceso", "Cargo", "Departamento", "FechaMin", "FechaMax", "ApuCuadrilla"}),
        Fx_My_Calendario = fxMyCalendarioDia(Removed_Other_Columns, "FechaMin", "FechaMax")
    in
        Fx_My_Calendario, 
// TblBonos
    TblBonos = let
        Source = Excel.Workbook(File.Contents(Ruta&"\VersionesBI\V12 Mac\Tablas Base V2.xlsx"), null, true),
        TblBonos_Table = Source{[Item="TblBonos",Kind="Table"]}[Data],
        Changed_Type = Table.TransformColumnTypes(TblBonos_Table,{{"FechaInicio", type date}, {"FechaFin", type date}, {"Cargo", type text}, {"CuadrillaArea", type text}, {"TipoCuadrilla", type text}, {"BonoCuadrilla", type number}, {"IncrementoBono", type number}, {"MetaMes", type number}, {"Salario", Int64.Type}, {"Max Porc Bono", type number}, {"Parte Presta", type number}, {"Parte Cuadri 2 Per", type number}}),
        My_Calendario_Dia = fxMyCalendarioDia(Changed_Type, "FechaInicio", "FechaFin"),
        Merged_Mes_Act = Table.NestedJoin(My_Calendario_Dia, {"Mes", "Año"}, Mes_Actu, {"Mes", "Año"}, "Mes_Actu", JoinKind.RightOuter),
        Added_Cargo_2 = Table.AddColumn(Merged_Mes_Act, "Personalizado", each if [Cargo] = "Admin" then "Aux Tec" else if [Cargo] = "TECNICO" then "Aux Tec" else null, type text),
        Merged_Tbl_Bonos = Table.NestedJoin(Added_Cargo_2, {"Personalizado", "CuadrillaArea", "TipoCuadrilla", "Fecha"}, Added_Cargo_2, {"Cargo", "CuadrillaArea", "TipoCuadrilla", "Fecha"}, "Added Conditional Column", JoinKind.LeftOuter),
        Expanded_Tbl_Bonos = Table.ExpandTableColumn(Merged_Tbl_Bonos, "Added Conditional Column", {"Salario", "Max Porc Bono", "Parte Presta", "Parte Cuadri 2 Per"}, {"Aux.Salario", "Aux.Max Porc Bono", "Aux.Parte Presta", "Aux.Parte Cuadri 2 Per"}),
        Capitalized_Each_Word = Table.TransformColumns(Expanded_Tbl_Bonos,{{"Cargo", Text.Proper, type text}})
    in
        Capitalized_Each_Word, 
// TblMetaMostrar
    TblMetaMostrar = let
        Source = Excel.Workbook(File.Contents(Ruta&"\VersionesBI\V12 Mac\Tablas Base V2.xlsx"), null, true),
        TblMetaMostrar_Table = Source{[Item="TblMetaMostrar",Kind="Table"]}[Data],
        Changed_Type = Table.TransformColumnTypes(TblMetaMostrar_Table,{{"FechaInicio", type date}, {"FechaFin", type date}, {"Departamento", type text}, {"CuadrillaArea", type text}, {"Tipo", type text}, {"MetaMostrar", type number}}),
        Trimmed_Text_Dep = Table.TransformColumns(Changed_Type,{{"Departamento", Text.Trim, type text}}),
        Cleaned_Text_Dep = Table.TransformColumns(Trimmed_Text_Dep,{{"Departamento", Text.Clean, type text}}),
        Capitalized_Dep = Table.TransformColumns(Cleaned_Text_Dep,{{"Departamento", Text.Proper, type text}}),
        Invocar_Fx_Calendario_dia = fxMyCalendarioDia(Capitalized_Dep, "FechaInicio", "FechaFin")
    in
        Invocar_Fx_Calendario_dia, 
// Cuadrillas
    Cuadrillas = let
        Source = ConsolidadoCuadrillas,
        Renamed_Columns = Table.RenameColumns(Source,{{"Departamento", "Dep Cuadri"}, {"CC", "CC Tec"}}),
        Capitalized_Each_Word = Table.TransformColumns(Renamed_Columns,{{"Contrata", Text.Proper, type text}, {"Dep Cuadri", Text.Proper, type text}, {"Nom Tec", Text.Proper, type text}, {"Nom Gest", Text.Proper, type text}, {"Nom Super", Text.Proper, type text}, {"Nom Aux", Text.Proper, type text}}),
        Removed_Other_Columns = Table.SelectColumns(Capitalized_Each_Word,{"Contrata", "Dep Cuadri", "AreaCuadri", "CC Tec", "Nom Tec", "Tipo Cuadrilla", "CC Gest", "Nom Gest", "CC Super", "Nom Super", "Fecha Inicial", "Fecha Final", "Nom Aux", "CC Aux"}),
        Appended_Personal_Sin_Cuadrillas = Table.Combine({Removed_Other_Columns, Personal_Sin_Cuadrillas}),
        fxMyCalendario = fxMyCalendarioFinal(Appended_Personal_Sin_Cuadrillas, "Fecha Inicial", "Fecha Final"),
        Added_Tipo_Empresa = Table.AddColumn(fxMyCalendario, "Tipo Empresa", each if [Contrata] = "Liteyca" then "Propio" else "Contratista", type text),
        Merged_Acceso_Cuadrillas = Table.NestedJoin(Added_Tipo_Empresa, {"CC Tec", "Dep Cuadri", "Fecha"}, AccesosCuadrillas_2, {"CCTec", "Departamento", "Fecha"}, "AccesosCuadrillas_2", JoinKind.LeftOuter),
        Expanded_Acceso_Cuadrillas = Table.ExpandTableColumn(Merged_Acceso_Cuadrillas, "AccesosCuadrillas_2", {"Acceso", "Cargo", "ApuCuadrilla"}, {"Acceso", "Cargo", "ApuCuadrilla"}),
        Replaced_Cargo = Table.ReplaceValue(Expanded_Acceso_Cuadrillas,null,"Admin",Replacer.ReplaceValue,{"Cargo"}),
        Replaced_Acceso = Table.ReplaceValue(Replaced_Cargo,null,"9999999999",Replacer.ReplaceValue,{"Acceso"}),
        Replaced_Apu_Cuadrilla = Table.ReplaceValue(Replaced_Acceso,null,0,Replacer.ReplaceValue,{"ApuCuadrilla"}),
        Merged_Tbl_Bonos = Table.NestedJoin(Replaced_Apu_Cuadrilla, {"Cargo", "AreaCuadri", "Tipo Cuadrilla", "Fecha"}, TblBonos, {"Cargo", "CuadrillaArea", "TipoCuadrilla", "Fecha"}, "TblBonos", JoinKind.LeftOuter),
        Expanded_Tbl_Bonos = Table.ExpandTableColumn(Merged_Tbl_Bonos, "TblBonos", {"BonoCuadrilla", "IncrementoBono", "MetaMes", "Salario", "Max Porc Bono", "Parte Presta", "Parte Cuadri 2 Per", "Aux.Salario", "Aux.Max Porc Bono", "Aux.Parte Presta", "Aux.Parte Cuadri 2 Per"}, {"BonoCuadrilla", "IncrementoBono", "MetaMes", "Salario", "Max Porc Bono", "Parte Presta", "Parte Cuadri 2 Per", "Aux.Salario", "Aux.Max Porc Bono", "Aux.Parte Presta", "Aux.Parte Cuadri 2 Per"}),
        Merged_Meta_Mostrar = Table.NestedJoin(Expanded_Tbl_Bonos, {"Dep Cuadri", "AreaCuadri", "Tipo Cuadrilla", "Fecha"}, TblMetaMostrar, {"Departamento", "CuadrillaArea", "Tipo", "Fecha"}, "TblMetaMostrar", JoinKind.LeftOuter),
        Expanded_Meta_Mostrar = Table.ExpandTableColumn(Merged_Meta_Mostrar, "TblMetaMostrar", {"MetaMostrar"}, {"Pre.MetaMostrar"}),
        Filtered_Null_Fecha = Table.SelectRows(Expanded_Meta_Mostrar , each [Fecha] <> null and [Fecha] <> "")
    in
        Filtered_Null_Fecha, 
// CantProducionDia
    CantProducionDia = let
    Source = Table.Combine({ProduccionAltas, ProduccionMantenimiento}),
    Grouped_Rows = Table.Group(Source, {"CC Tec", "Fecha"}, {{"Recuento", each Table.RowCount(_), Int64.Type}}),
    Added_Dia_Trabajado = Table.AddColumn(Grouped_Rows, "DiaTrabajado", each 1/[Recuento], type number)
in
    Added_Dia_Trabajado, 
// Cuadrillas_Sin_Produccion
    Cuadrillas_Sin_Produccion = let
        My_Produccion = Table.Combine({ProduccionAltas, ProduccionMantenimiento}),
        Source = let
            Source = ConsolidadoCuadrillas,
            Renamed_Columns = Table.RenameColumns(Source,{{"Departamento", "Dep Cuadri"}, {"CC", "CC Tec"}}),
            Removed_Other_Columns = Table.SelectColumns(Renamed_Columns,{"Contrata", "Dep Cuadri", "AreaCuadri", "CC Tec", "Nom Tec", "Tipo Cuadrilla", "CC Gest", "Nom Gest", "CC Super", "Nom Super", "Fecha Inicial", "Fecha Final", "Nom Aux", "CC Aux"}),
            Appended_Query = Table.Combine({Removed_Other_Columns, Personal_Sin_Cuadrillas}),
            fxMyCalendario = fxMyCalendarioFinal(Appended_Query, "Fecha Inicial", "Fecha Final"),
            Removed_Duplicates = Table.Distinct(fxMyCalendario)
        in
            Removed_Duplicates,
        Selected_Columns = Table.SelectColumns(Source,{"Dep Cuadri", "CC Tec", "Fecha"}),
        Trimmed_Text = Table.TransformColumns(Selected_Columns,{{"Dep Cuadri", Text.Trim, type text}}),
        Cleaned_Text = Table.TransformColumns(Trimmed_Text,{{"Dep Cuadri", Text.Clean, type text}}),
        Capitalized_Dep = Table.TransformColumns(Cleaned_Text,{{"Dep Cuadri", Text.Proper, type text}}),
        Merged_Produccion = Table.NestedJoin(Capitalized_Dep, {"Dep Cuadri", "CC Tec", "Fecha"}, My_Produccion, {"Departamento", "CC Tec", "Fecha"}, "Produccion", JoinKind.LeftAnti),
        Expanded_Produccion = Table.ExpandTableColumn(Merged_Produccion, "Produccion", {"Atiempo", "Atis", "Tipo Orden", "Tipo Tarea", "Medio de Acceso", "Baremos", "AreaCuadri", "Actividades"}, {"Atiempo", "Atis", "Tipo Orden", "Tipo Tarea", "Medio de Acceso", "Baremos", "AreaCuadri", "Actividades"}),
        Filtered_Null_Dep = Table.SelectRows(Expanded_Produccion, each [Dep Cuadri] <> null and [Dep Cuadri] <> ""),
        Renamed_Departamento = Table.RenameColumns(Filtered_Null_Dep,{{"Dep Cuadri", "Departamento"}}),
        Replaced_Null_Bar_Act = Table.ReplaceValue(Renamed_Departamento,null,0,Replacer.ReplaceValue,{"Baremos", "Actividades"}),
        Added_Recuento = Table.AddColumn(Replaced_Null_Bar_Act, "Recuento", each 1, Int64.Type),
        Added_Dia_Trabajado = Table.AddColumn(Added_Recuento, "DiaTrabajado", each 1, type number),
        Removed_Duplicates = Table.Distinct(Added_Dia_Trabajado)
    in
        Removed_Duplicates, 
// Produccion
    Produccion = let
        Source = Table.Combine({ProduccionAltas, ProduccionMantenimiento}),
        Filtered_Null_Dep = Table.SelectRows(Source, each [Departamento] <> null and [Departamento] <> ""),
        Replaced_Null_Bar_Act = Table.ReplaceValue(Filtered_Null_Dep,null,0,Replacer.ReplaceValue,{"Baremos", "Actividades"}),
        Merged_Cant_Por_Dia = Table.NestedJoin(Replaced_Null_Bar_Act, {"CC Tec", "Fecha"}, CantProducionDia, {"CC Tec", "Fecha"}, "CantProducionDia", JoinKind.LeftOuter),
        Expanded_Recuento = Table.ExpandTableColumn(Merged_Cant_Por_Dia, "CantProducionDia", {"Recuento", "DiaTrabajado"}, {"Recuento", "DiaTrabajado"}),
        Appended_Cuadrillas_Sin_Produccion = Table.Combine({Expanded_Recuento, Cuadrillas_Sin_Produccion})
    in
        Appended_Cuadrillas_Sin_Produccion, 
// HomAreaVal
    HomAreaVal = let
        Source = Excel.Workbook(File.Contents(Ruta&"\VersionesBI\V12 Mac\Tablas Base V2.xlsx"), null, true),
        HomAreaVal_Table = Source{[Item="HomAreaVal",Kind="Table"]}[Data],
        Changed_Type = Table.TransformColumnTypes(HomAreaVal_Table,{{"FechaInicio", type date}, {"FechaFin", type date}, {"Area", type text}, {"AreaHom", type text}, {"Valor", type number}, {"Valor Tec", Int64.Type}, {"Valor Admin", Int64.Type}}),
        Invoked_My_Calendario = fxMyCalendarioDia(Changed_Type, "FechaInicio", "FechaFin"),
        Merged_Mes_Act = Table.NestedJoin(Invoked_My_Calendario, {"Mes", "Año"}, Mes_Actu, {"Mes", "Año"}, "Mes_Actu", JoinKind.RightOuter)
    in
        Merged_Mes_Act, 
//Calidad_I_M
    Calidad_I_M = let
        MyRuta = Ruta, 
        MyArchivoUtilizar = Archivos_Utilizar,
        MyTransformaReitero = TransformaReitero,
        MyEjemploReitero = EjemploReitero,
        MyTransformaInfancia = TransformaInfancia,
        MyEjemploInfancia = EjemploInfancia,
        MyInfancias = let
            Source = Folder.Files(MyRuta&"\CalculoBonificacion\Infancia"),
            Insertado_Year = Table.AddColumn(Source, "Año", each Text.BetweenDelimiters([Name], "_", ".", 1, 0), type text),
            Insertado_Mes = Table.AddColumn(Insertado_Year, "Mes", each Text.BetweenDelimiters([Name], "_", "_"), type text),
            Changed_Type_Date = Table.TransformColumnTypes(Insertado_Mes,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
            Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, MyArchivoUtilizar, {"Mes", "Año"}, "Archivos_Utilizar", JoinKind.RightOuter),
            Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
            FilteredHiddenFiles = Table.SelectRows(Filtered_Null_Name, each [Attributes]?[Hidden]? <> true),
            InvokeCustomFunction = Table.AddColumn(FilteredHiddenFiles, "Transformar archivo", each MyTransformaInfancia([Content])),
            RemovedOtherColumns = Table.SelectColumns(InvokeCustomFunction,{"Transformar archivo", "Año", "Mes"}),
            RemovedErrors = Table.RemoveRowsWithErrors(RemovedOtherColumns, {"Transformar archivo"}),
            ExpandedTableColumn = Table.ExpandTableColumn(RemovedErrors, "Transformar archivo", Table.ColumnNames(MyTransformaInfancia(MyEjemploInfancia))),
            ChangedType = Table.TransformColumnTypes(ExpandedTableColumn,{{"XA_ACTUACION_ALTA", type text}, {"Pet_atis_ALTA", type text}, {"PRODUCTO", type text}, {"Medio_de_Acceso_ALTA", type text}, {"Fecha_de_cierre_final_ALTA", type date}, {"external_id", type text}, {"Departamento", type text}, {"Año", Int64.Type}, {"Mes", Int64.Type}, {"APERTURA_AV", type text}, {"CIERRE_AV", type text}}),
            RemovedOtherColumns1 = Table.SelectColumns(ChangedType,{"Pet_atis_ALTA", "CIERRE_AV", "APERTURA_AV"}),
            AddedExcluir = Table.AddColumn(RemovedOtherColumns1, "Excluir", each "NO", type text),
            RenamedColumns = Table.RenameColumns(AddedExcluir,{{"Pet_atis_ALTA", "Pet_atis"}})
        in
            RenamedColumns,
        MyCausalesExcluirReitero = let        
            Source = Excel.Workbook(File.Contents(MyRuta&"\VersionesBI\V12 Mac\Tablas Base V2.xlsx"), null, true),
            CausalesExcluirReitero_Table = Source{[Item="CausalesExcluirReitero",Kind="Table"]}[Data],
            ChangedType = Table.TransformColumnTypes(CausalesExcluirReitero_Table,{{"Acceso", type text}, {"Causal", type text}, {"Excluir", type text}, {"Fecha Inicio", type date}, {"Fecha Fin", type date}}),
            InvokedListaFechas = Table.AddColumn(ChangedType, "fxListaFechas", each fxMyfxListaFechas([Fecha Inicio], [Fecha Fin]), type table[Fecha=date, Año=Int64.Type, Mes=Int64.Type]),
            ExpandedListaFechas = Table.ExpandTableColumn(InvokedListaFechas, "fxListaFechas", {"Año", "Mes"}, {"Año", "Mes"}),
            RemovedDuplicates = Table.Distinct(ExpandedListaFechas)
        in
            RemovedDuplicates, 
        MyReiteros = let
        Source = Folder.Files(MyRuta&"\CalculoBonificacion\Reitero"),
        InsertedYear = Table.AddColumn(Source, "Año", each Text.BetweenDelimiters([Name], "_", ".", 1, 0), type text),
        InsertedMonth = Table.AddColumn(InsertedYear, "Mes", each Text.BetweenDelimiters([Name], "_", "_"), type text),
        Changed_Type_Date = Table.TransformColumnTypes(InsertedMonth,{{"Año", Int64.Type}, {"Mes", Int64.Type}}),
        Merged_Mes_Actu = Table.NestedJoin(Changed_Type_Date, {"Mes", "Año"}, MyArchivoUtilizar, {"Mes", "Año"}, "Archivos_Utilizar", JoinKind.RightOuter),
        Filtered_Null_Name = Table.SelectRows(Merged_Mes_Actu, each [Name] <> null and [Name] <> ""),
        FilteredHiddenFiles = Table.SelectRows(Filtered_Null_Name, each [Attributes]?[Hidden]? <> true),
        InvokeCustomFunction = Table.AddColumn(FilteredHiddenFiles, "Transformar archivo (2)", each MyTransformaReitero([Content])),
        RemovedOtherColumns = Table.SelectColumns(InvokeCustomFunction,{"Año", "Mes", "Transformar archivo (2)"}),
        RemovedErrors = Table.RemoveRowsWithErrors(RemovedOtherColumns, {"Transformar archivo (2)"}),
        ExpandedTableColumn = Table.ExpandTableColumn(RemovedErrors, "Transformar archivo (2)", Table.ColumnNames(MyTransformaReitero(MyEjemploReitero))),
        ChangedType = Table.TransformColumnTypes(ExpandedTableColumn,{{"Pet_atis", type text}, {"Identificador_PC_Linea", type text}, {"Fecha_de_cierre_final", type date}, {"Familia", type text}, {"Medio_de_Acceso", type text}, {"external_id", type text}, {"external_id_MTTOA", type text}, {"Departamento", type text}, {"Año", Int64.Type}, {"Mes", Int64.Type}, {"APERTURA_AV", type text}, {"CIERRE_AV", type text}}),
        MergedExcluir = Table.NestedJoin(ChangedType, {"Medio_de_Acceso", "APERTURA_AV", "Año", "Mes"}, MyCausalesExcluirReitero, {"Acceso", "Causal", "Año", "Mes"}, "CausalesExcluirReitero", JoinKind.LeftOuter),
        ExpandedExcluir = Table.ExpandTableColumn(MergedExcluir, "CausalesExcluirReitero", {"Excluir"}, {"Excluir"}),
        ReplacedNullExcluir = Table.ReplaceValue(ExpandedExcluir,null,"NO",Replacer.ReplaceValue,{"Excluir"}),
        RemovedOtherColumns1 = Table.SelectColumns(ReplacedNullExcluir,{"Pet_atis", "APERTURA_AV", "CIERRE_AV", "Excluir"})
    in
        RemovedOtherColumns1,
        Source = Table.Combine({MyReiteros, MyInfancias}),
        RemovedDuplicates = Table.Distinct(Source)
    in
        RemovedDuplicates,
// ConsolidadoProduccion
    ConsolidadoProduccion = let
        Source = Cuadrillas,
        Merged_Produccion = Table.NestedJoin(Source, {"Dep Cuadri", "CC Tec", "Fecha"}, Produccion, {"Departamento", "CC Tec", "Fecha"}, "Produccion", JoinKind.LeftOuter),
        Expanded_Produccion = Table.ExpandTableColumn(Merged_Produccion, "Produccion", {"Atiempo", "Atis", "Tipo Orden", "Tipo Tarea", "Departamento", "Medio de Acceso", "Baremos", "Actividades", "Recuento", "DiaTrabajado"}, {"Atiempo", "Atis", "Tipo Orden", "Tipo Tarea", "Departamento", "Medio de Acceso", "Baremos", "Actividades", "Recuento", "DiaTrabajado"}),
        Merged_Homologa_Area = Table.NestedJoin(Expanded_Produccion, {"AreaCuadri", "Fecha"}, HomAreaVal, {"Area", "Fecha"}, "HomAreaVal", JoinKind.LeftOuter),
        Expanded_Homologado_Area = Table.ExpandTableColumn(Merged_Homologa_Area, "HomAreaVal", {"Valor", "Valor Tec", "Valor Admin"}, {"Valor", "Valor Tec", "Valor Admin"}),
        Added_Bar_Tec = Table.AddColumn(Expanded_Homologado_Area, "$Bar Tec", each [Baremos]*[Valor Tec], type number),
        Added_Bar_admin = Table.AddColumn(Added_Bar_Tec, "$Bar Admin", each [Baremos]*[Valor Admin], type number),
        Added_Trabajado = Table.AddColumn(Added_Bar_admin, "Trabajado", each if([AreaCuadri]="INSTALACIONES")then([Baremos]+([Actividades]*[Valor]))else([Actividades]+([Baremos]*[Valor])), type number),
        Added_Meta_Dia = Table.AddColumn(Added_Trabajado, "Meta Dia", each if([Habil]="Habil")then([MetaMes]/[Habiles]/[Recuento])else(0), type number),
        Added_Real_Meta_Dia = Table.AddColumn(Added_Meta_Dia, "RealMetaDia", each if([Habil]="Habil")then(if([Cargo]="Supervisor")then(if([AreaCuadri]="MANTENIMIENTO")then([MetaMes])else([Meta Dia]))else([Meta Dia]))else(0), type number),
        Added_Meta_Mostrar = Table.AddColumn(Added_Real_Meta_Dia, "MetaMostrar", each if([Cargo]="Tecnico")then(if([Pre.MetaMostrar]=null)then([RealMetaDia])else([Pre.MetaMostrar]))else([RealMetaDia]), type number),
        Renamed_Columns = Table.RenameColumns(Added_Meta_Mostrar,{{"BonoCuadrilla", "BonoCduarilla"}}),
        Removed_Other_Columns = Table.SelectColumns(Renamed_Columns,{"Contrata", "Dep Cuadri", "AreaCuadri", "CC Tec", "Nom Tec", "Tipo Cuadrilla", "CC Gest", "Nom Gest", "CC Super", "Nom Super", "Nom Aux", "CC Aux", "Fecha", "Año", "Mes", "Habiles", "Habil", "Tipo Empresa", "Acceso", "Cargo", "ApuCuadrilla", "BonoCduarilla", "IncrementoBono", "MetaMes", "Salario", "Max Porc Bono", "Parte Presta", "Parte Cuadri 2 Per", "Aux.Salario", "Aux.Max Porc Bono", "Aux.Parte Presta", "Aux.Parte Cuadri 2 Per", "Atiempo", "Atis", "Tipo Orden", "Tipo Tarea", "Departamento", "Medio de Acceso", "Baremos", "Actividades", "Recuento", "DiaTrabajado", "Valor Admin", "$Bar Tec", "$Bar Admin", "Trabajado", "Meta Dia", "RealMetaDia", "MetaMostrar"}),
        Merged_Calidad_IM = Table.NestedJoin(Removed_Other_Columns, {"Atis"}, Calidad_I_M, {"Pet_atis"}, "Calidad_I_M", JoinKind.LeftOuter),
        Expanded_Calidad_IM = Table.ExpandTableColumn(Merged_Calidad_IM, "Calidad_I_M", {"APERTURA_AV", "CIERRE_AV", "Excluir"}, {"Calidad_I_M.APERTURA_AV", "Calidad_I_M.CIERRE_AV", "Calidad_I_M.Excluir"}),
        Replaced_Null_Excluir = Table.ReplaceValue(Expanded_Calidad_IM,null,"Nada",Replacer.ReplaceValue,{"Calidad_I_M.Excluir"}),
        Added_Afecta_Calidad = Table.AddColumn(Replaced_Null_Excluir, "Afecta Calidad", each if([Calidad_I_M.Excluir]="NO")then("Afecta")else("No Afecta"), type text),
        Added_Puntos_Colombia = Table.AddColumn(Added_Afecta_Calidad, "Puntos Colombia", each if([Tipo Orden]="AVERIA")then([Actividades]*1.3)else([Baremos]), type number),
        Added_Dia_No_Tabaja = Table.AddColumn(Added_Puntos_Colombia, "DiaNoTrabajo", each if([Habil]="Habil")and([DiaTrabajado]=null)then(1)else(0), type number),
        Replaced_Null_Dep = Table.ReplaceValue(Added_Dia_No_Tabaja,null,each [Dep Cuadri],Replacer.ReplaceValue,{"Departamento"})
    in
        Replaced_Null_Dep
in
    ConsolidadoProduccion