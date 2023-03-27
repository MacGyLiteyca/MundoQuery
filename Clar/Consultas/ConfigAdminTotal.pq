// ConfigAdminTotal
let
    Source = Excel.CurrentWorkbook(){[Name="ConfigAdmin"]}[Content],
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