// Departamentos
let
    Source = 
        let 
            Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/InfoID.pq")), #shared)
        in Source,
    FilteredNull = Table.SelectRows(Source, each [Departamento] <> null and [Departamento] <> ""),
    CapitalizedEachWord = Table.TransformColumns(FilteredNull,{{"Departamento", Text.Proper, type text}}),
    Departamento = CapitalizedEachWord[Departamento],
    RemovedDuplicates = List.Distinct(Departamento)
in
    RemovedDuplicates