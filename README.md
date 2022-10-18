# MundoQuery

Aca se van a colocar muchas funciones realizadas en Power Query que son utilizadas en muchos proyectos
Se debe utilizar este modelo para llamar la función al Query

let
    Source = Expression.Evaluate(Text.FromBinary(Web.Contents( "https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/fxListaFechas.pq?token=GHSAT0AAAAAAB2DPJEXEAQU2F6JIZ3TX67YY2PCOIQ") ), #shared)
in
    Source
