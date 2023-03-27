// AccesoCuadrillas
let
    Source = InfoID,
    fxListaFechas =
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents( "https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/fxListaFechas.pq") ), #shared)
    in Source,
    FilteredRows = Table.SelectRows(Source, each [External ID] <> null and [External ID] <> ""),
    InvokedListaFechas = Table.AddColumn(FilteredRows, "fxListaFechas", each fxListaFechas([FechaMin], [FechaMax]), type table[Fecha=date, Año=Int64.Type, Mes=Int64.Type]),
    ExpandedListaFechas = Table.ExpandTableColumn(InvokedListaFechas, "fxListaFechas", {"Fecha"}, {"Fecha"}),
    SelectedColumns = Table.SelectColumns(ExpandedListaFechas,{"External ID", "Departamento", "EECC Colaboradora", "Fecha"}),
    MergedCuadrillas = Table.NestedJoin(SelectedColumns, {"External ID", "Departamento", "EECC Colaboradora", "Fecha"}, CuadrillasFechas, {"CEDULA TECNICO", "DEPARTAMENTO", "EMPRESA", "Fecha"}, "Cuadrillas2", JoinKind.FullOuter),
    ExpandedCuadrillas = Table.ExpandTableColumn(MergedCuadrillas, "Cuadrillas2", {"EMPRESA", "DEPARTAMENTO", "CEDULA TECNICO", "CEDULA AUX GESTION", "CEDULA SUPERVISOR", "CEDULA LIDER ", "CEDULA PROFESIONAL", "Fecha", "CC Acceso", "Cargo"}, {"Cuadri.EMPRESA", "Cuadri.DEPARTAMENTO", "Cuadri.CEDULA TECNICO", "Cuadri.CEDULA AUX GESTION", "Cuadri.CEDULA SUPERVISOR", "Cuadri.CEDULA LIDER ", "Cuadri.CEDULA PROFESIONAL", "Cuadri.Fecha", "Cuadri.CC Acceso", "Cuadri.Cargo"}),
    AddedConditionalCCTEC = Table.AddColumn(ExpandedCuadrillas, "CC Tec", each if [Cuadri.CEDULA TECNICO] = null then [External ID] else [Cuadri.CEDULA TECNICO], type text),
    AddedConditionalDate = Table.AddColumn(AddedConditionalCCTEC, "Fecha In", each if [Cuadri.Fecha] = null then [Fecha] else [Cuadri.Fecha], type date),
    AddedConditionalCompania = Table.AddColumn(AddedConditionalDate, "Compania", each if [Cuadri.EMPRESA] = null then [EECC Colaboradora] else [Cuadri.EMPRESA], type text),
    AddedConditionalDepar = Table.AddColumn(AddedConditionalCompania, "Departamentos", each if [Cuadri.DEPARTAMENTO] = null then [Departamento] else [Cuadri.DEPARTAMENTO], type text),
    InvokedFXAccesos = Table.AddColumn(AddedConditionalDepar, "MyFXAccesos", each MyFXAccesos([CC Tec], [Cuadri.CEDULA AUX GESTION], [Cuadri.CEDULA SUPERVISOR], [#"Cuadri.CEDULA LIDER "], [Cuadri.CEDULA PROFESIONAL], [Cuadri.CC Acceso], [Cuadri.Cargo], [Fecha In]), type table[CCTec = text, Acceso = text, Cargo = text, Año = Int64.Type, Mes = Int64.Type, Fecha = date]),
    OtherColumns = Table.SelectColumns(InvokedFXAccesos,{"Compania", "Departamento", "MyFXAccesos"}),
    ExpandedFXACCesos = Table.ExpandTableColumn(OtherColumns, "MyFXAccesos", {"CCTec", "Acceso", "Cargo", "Año", "Mes", "Fecha"}, {"CCTec", "Acceso", "Cargo", "Año", "Mes", "Fecha"}),
    MergedUsuarios = Table.NestedJoin(ExpandedFXACCesos, {"Acceso"}, Usuarios, {"CC Acceso"}, "Usuarios", JoinKind.RightOuter),
    RemovedOtherColumns1 = Table.SelectColumns(MergedUsuarios,{"Compania", "Departamento", "CCTec", "Acceso", "Cargo", "Año", "Mes", "Fecha"}),
    FilteredNullAcceso = Table.SelectRows(RemovedOtherColumns1, each [Acceso] <> null and [Acceso] <> ""),
    GroupedRows = Table.Group(FilteredNullAcceso, {"Compania", "Departamento", "CCTec", "Acceso", "Cargo", "Año", "Mes"}, {{"FechaMin", each List.Min([Fecha]), type nullable date}, {"FechaMax", each List.Max([Fecha]), type nullable date}}),
    AppendedTBLAccesoCuadrillas = Table.Combine({GroupedRows, TBLAccesoCuadrillas}),
    RemovedDuplicates = Table.Distinct(AppendedTBLAccesoCuadrillas),
    FilteredNullAccesos1 = Table.SelectRows(RemovedDuplicates, each [Acceso] <> null and [Acceso] <> "")
in
    FilteredNullAccesos1