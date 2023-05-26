# Informacion util para este proyecto

En las siguientes lineas se encuentra la información de como obtener estas consultas desde power query

| Nombre | Consulta | Util Extra |
|---|---|---|
|fxMyCalendario2.pq|let Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/fxMyCalendario2.pq")), #shared) in Source| Algo mas|
|fxMyCalendarioFinal.pq|let Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/fxMyCalendarioFinal.pq") ), #shared) in Source||
|ProduccionAltas.pq|let Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/Produccion/ProduccionAltas.pq") ), #shared) in Source||
|ProduccionMantenimiento.pq|let Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/Produccion/ProduccionMantenimiento.pq") ), #shared) in Source||
|ConsolidadoCuadrillas.pq|let Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/Produccion/ConsolidadoCuadrillas.pq") ), #shared) in Source||
|Mes_Actu.pq|let Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/Mes_Actu.pq") ), #shared) in Source||
|fxMyCalendarioDia.pq|let Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/fxMyCalendarioDia.pq") ), #shared) in Source||
|fxMyCalendarioMes.pq|let Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/fxMyCalendarioMes.pq") ), #shared) in Source||
