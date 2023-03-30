// CuadrillasFechas
let
    fxListaFechas = 
        let 
            Source = Expression.Evaluate(Text.FromBinary(Web.Contents( "https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/fxListaFechas.pq") ), #shared)
        in Source,
    Source = 
        let 
            Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/Cuadrillas.pq")), #shared)
        in Source,
    InvokedListaFechas = Table.AddColumn(Source, "fxListaFechas", each fxListaFechas([FECHA INICIAL], [FECHA FIN]), type table[Fecha=date, Año=Int64.Type, Mes=Int64.Type]),
    ExpandedListaFechas = Table.ExpandTableColumn(InvokedListaFechas, "fxListaFechas", {"Fecha"}, {"Fecha"})
in
    ExpandedListaFechas