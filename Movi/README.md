#Informacion util para este proyecto

En las siguientes lineas se encuentra la información de como obtener estas consultas desde power query

|Nombre|Consulta|UtilExtra|
|fxMyCalendario2.pq|let Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/fxMyCalendario2.pq") ), #shared) in Source||
|fxMyCalendarioFinal.pq|let Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/fxMyCalendarioFinal.pq") ), #shared) in Source||



| Column 1 | Column 2 |
|---|---|
| This is a cell | This is another cell |
