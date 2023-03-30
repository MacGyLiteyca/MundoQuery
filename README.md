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

El listado de los posibles llamados actuales existentes son los siguientes, y los que son funciones que tienen como resultado tabla tambien les dejo la estructura al llamarlo en la nueva columna

fxListaFechas =
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/fxListaFechas.pq")), #shared)
    in Source
    type table[Fecha=date, Año=Int64.Type, Mes=Int64.Type]

MyFXAccesos = 
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/MyFXAccesosClaro.pq")), #shared)
    in Source
    type table[CCTec = text, Acceso = text, Cargo = text, Año = Int64.Type, Mes = Int64.Type, Fecha = date]

AccesoCuadrillas = 
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/AccesosCuadrillas.pq")), #shared)
    in Source

CCActivas = 
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/CCActivas.pq")), #shared)
    in Source

InfoID = 
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/InfoID.pq")), #shared)
    in Source

Cuadrifechas = 
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/CuadriFechas.pq")), #shared)
    in Source

Usuarios = 
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/Usuarios.pq")), #shared)
    in Source

TBLAccesoCuadrillas = 
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/TBLAccesoCuadrillas.pq")), #shared)
    in Source

Cuadrillas = 
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/Cuadrillas.pq")), #shared)
    in Source

ConfigAdmin = 
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/ConfiAdmin.pq")), #shared)
    in Source

MesAct =
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/MesUtilizar.pq")), #shared)
    in Source

Empresas =
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/Empresas.pq")), #shared)
    in Source

Departamentos =
    let 
        Source = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/MacGyLiteyca/MundoQuery/main/Clar/Consultas/Departamentos.pq")), #shared)
    in Source