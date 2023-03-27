// Departamentos
let
    Source = InfoID,
    FilteredNull = Table.SelectRows(Source, each [Departamento] <> null and [Departamento] <> ""),
    CapitalizedEachWord = Table.TransformColumns(FilteredNull,{{"Departamento", Text.Proper, type text}}),
    Departamento = CapitalizedEachWord[Departamento],
    RemovedDuplicates = List.Distinct(Departamento)
in
    RemovedDuplicates