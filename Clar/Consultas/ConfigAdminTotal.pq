// ConfigAdminTotal
let
    Source = try(Excel.CurrentWorkbook(){[Name="ConfigAdmin"]}[Content])otherwise(#table(type table 
            [FechaInicio = date, FechaFin = date, CC Acceso = text, Nombre = text, Cargo = text, Contratista = text, Departamento = text], 
            {{#date(2022, 1, 1), #date(2023, 12, 31), "Admin", "Admin", "Admin", null, null}})),
    Empresas =
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/Empresas.pq")), #shared)
    in Source, 
    Departamentos =
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/Departamentos.pq")), #shared)
    in Source, 
    ChangedType = Table.TransformColumnTypes(Source,{{"FechaInicio", type date}, {"FechaFin", type date}, {"CC Acceso", type text}, {"Nombre", type text}, {"Cargo", type text}, {"Contratista", type text}, {"Departamento", type text}}),
    AddedEmpresa = Table.AddColumn(ChangedType, "Empresa", each if([Contratista]=null)then(Empresas)else({[Contratista]})),
    AddedDepartamentos = Table.AddColumn(AddedEmpresa, "Departamentos", each if([Departamento]=null)then(Departamentos)else({[Departamento]})),
    ExpandedEmpresas = Table.ExpandListColumn(AddedDepartamentos, "Empresa"),
    ExpandedDepartamentos = Table.ExpandListColumn(ExpandedEmpresas, "Departamentos"),
    ChangedType1 = Table.TransformColumnTypes(ExpandedDepartamentos,{{"Empresa", type text}, {"Departamentos", type text}}),
    RemovedOtherColumns = Table.SelectColumns(ChangedType1,{"FechaInicio", "FechaFin", "CC Acceso", "Cargo", "Empresa", "Departamentos"}),
    RemovedDuplicates = Table.Distinct(RemovedOtherColumns)
in
    RemovedDuplicates