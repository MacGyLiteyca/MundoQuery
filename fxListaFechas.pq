// fxListaFechas
let
    fxListaFechas = let
        Funcion = ( //optional al colocar al inicio de uno de los parámetros permite que sea opcional, tambien debe quedar opcional en el resto de pasos de la documentación
            FechaMinimo as date, 
            FechaMaximo as date
        ) as any =>
let 
//Numero de días entre las fechas
    Duracion =    //Se suma un día para ajustar la cantidad en la resta
        Number.Abs(Duration.TotalDays(FechaMaximo-FechaMinimo))+1,
//Crea un listado de fechas
    ListaFechas = List.Dates(List.Min({Date.From(FechaMinimo), Date.From(FechaMaximo)}), Duracion, #duration(1,0,0,0)),
//Pasa el listado a una tabla utilizable
    ConvertedToTable = Table.FromList(ListaFechas, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
//Se le da nombre a la columna
    RenamedColumns = Table.RenameColumns(ConvertedToTable,{{"Column1", "Fecha"}}),
//Se le da formato a la columna
    ChangedType = Table.TransformColumnTypes(RenamedColumns,{{"Fecha", type date}}),
//Se agrega el año
    InsertedYear = Table.AddColumn(ChangedType, "Año", each Date.Year([Fecha]), Int64.Type),
//Se agrega el mes
    InsertedMonth = Table.AddColumn(InsertedYear, "Mes", each Date.Month([Fecha]), Int64.Type)
in
    InsertedMonth,

//documentación con desplegables en los casos que aplica y ejemplos
Documentacion =
    type function (
    FechaMinimo as date,
    FechaMaximo as date) as list meta
    [Documentation.Name = "fxListaFechas",
    Documentation.LongDescription = "Esta función toma una fecha inicial y una fecha final y genera un listado entre estas 2 fechas día por día; toma automáticamente cual es la fecha inicial o menor y la final o mas reciente",
    Documentation.Examples = 
        {
            [
                Description = 
                "Fechas entre el 01/01/2022 hasta el 03/01/2022 junto al año y mes",
                Code = "fxListaFechas(#date(2022, 01, 01), #date(2022, 01, 03))",
                Result = 
"#table(type table[Fecha = date, Año = number, Mes = number], 
    {{01/01/2022, 2022, 1},
    {02/01/2022, 2022, 1},
    {03/01/2022, 2022, 1}})"
            ],
            [
                Description = 
                "Fechas entre el 05/01/2022 hasta el 08/01/2022 junto al año y mes",
                Code = "fxListaFechas(#date(2022, 01, 05),#date(2022, 01, 08))",
                Result = 
"#table(type table[Fecha = date, Año = number, Mes = number], 
    {{05/01/2022, 2022, 1},
    {06/01/2022, 2022, 1},
    {07/01/2022, 2022, 1},
    {08/01/2022, 2022, 1}})"
            ],
            [
                Description = 
                "Fechas entre el 03/01/2022 hasta el 01/01/2022 junto al año y mes",
                Code = "fxListaFechas(#date(2022, 01, 03),#date(2022, 01, 01))",
                Result = 
"#table(type table[Fecha = date, Año = number, Mes = number], 
    {{01/01/2022, 2022, 1},
    {02/01/2022, 2022, 1},
    {03/01/2022, 2022, 1}})"
            ],
            [
                Description = 
                "Fechas entre el 08/01/2022 hasta el 05/01/2022 junto al año y mes",
                Code = "fxListaFechas(#date(2022, 01, 08),#date(2022, 01, 05))",
                Result = 
"#table(type table[Fecha = date, Año = number, Mes = number], 
    {{05/01/2022, 2022, 1},
    {06/01/2022, 2022, 1},
    {07/01/2022, 2022, 1},
    {08/01/2022, 2022, 1}})"
            ]
        },
        Documentation.Category = 
        "List",

        Documentation.Source = 
        "Local",

        Documentation.Version = " 1.0 ",

        Documentation.Author = 
        "Jorge Acuña"
    ]
in
    Value.ReplaceType (
        Funcion, 
        Documentacion 
    )
in
    fxListaFechas