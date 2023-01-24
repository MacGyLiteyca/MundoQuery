# MundoQuery

Aca se van a colocar muchas funciones realizadas en Power Query que son utilizadas en muchos proyectos
Se debe utilizar este modelo para llamar la función al Query

let
    Source = Expression.Evaluate(Text.FromBinary(Web.Contents( "https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/fxListaFechas.pq") ), #shared)
in
    Source
    
    
Y como esta función regresa una tabla con 3 columnas si se llama desde otra tabla se debe colocar en el tipo de dato 

type table[Fecha=date, Año=Int64.Type, Mes=Int64.Type]

De este modo el expandir las columnas ya tendran definido su tipo de dato
