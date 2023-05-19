#Informacion util para este proyecto

En las siguientes lineas se encuentra la información de como obtener estas consultas desde power query

| Nombre | Consulta | Util Extra |
|---|---|---|
|fxMyCalendario2.pq|let 
  Source = Expression.Evaluate(
    Text.FromBinary(
      Web.Contents(
        "https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/fxMyCalendario2.pq"
      )
    ), #shared
  ) 
in 
  Source| Algo mas|
|fxMyCalendarioFinal.pq|let Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Movi/fxMyCalendarioFinal.pq") ), #shared) in Source||
