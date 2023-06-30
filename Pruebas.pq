let
    //Como fuente es la carpeta de Altas Mes Anterior
    Source = Csv.Document(
        Parámetro_Altas_Mes_Ant, [Delimiter = "Õ", Columns = 26, Encoding = 1252, QuoteStyle = QuoteStyle.None]
    ),
    //Filtro en la columna1 para quitar el guión
    FilteredRows01 = Table.SelectRows(Source, each not Text.Contains([Column1], "-")),
    //Filtro en la Columna2 para quitar en blanco
    FilteredRows02 = Table.SelectRows(FilteredRows01, each [Column2] <> null and [Column2] <> ""),
    //Utiliza la primera como titulos
    PromotedHeaders = Table.PromoteHeaders(FilteredRows02, [PromoteAllScalars = true]),
    //Se seleccionan las columnas a utilizar
    SelectColumns =
        try
            (
                Table.SelectColumns(
                    PromotedHeaders,
                    {
                        "Numero_de_actuacion",
                        "Subtipo_de_orden",
                        "Pet_atis",
                        "Departamento",
                        "Fecha_de_cierre_final",
                        "BA",
                        "IP_TV",
                        "external_id",
                        "Medio_de_Acceso"
                    }
                )
            )
        otherwise
            (
                Table.SelectColumns(
                    Table.ReplaceValue(
                        Table.ReplaceValue(
                            Table.RenameColumns(
                                Table.ExpandTableColumn(
                                    Table.NestedJoin(
                                        Table.SelectColumns(
                                            PromotedHeaders,
                                            {
                                                "DepartamentoHomologado",
                                                "Medio_de_Acceso",
                                                "Numero_de_actuacion",
                                                "MES",
                                                "ANIO"
                                            }
                                        ),
                                        {"ANIO", "MES", "Numero_de_actuacion"},
                                        AGTOA,
                                        {"Fecha_de_la_cita_año", "Fecha_de_la_cita_mes", "XA_ACTUACION"},
                                        "AGTOA",
                                        JoinKind.LeftOuter
                                    ),
                                    "AGTOA",
                                    {"BA", "Bucket", "Fecha_de_la_cita", "IP_TV", "Pet_atis", "Subtipo_de_orden"},
                                    {"BA", "Bucket", "Fecha_de_la_cita", "IP_TV", "Pet_atis", "Subtipo_de_orden"}
                                ),
                                {
                                    {"DepartamentoHomologado", "Departamento"},
                                    {"Bucket", "external_id"},
                                    {"Fecha_de_la_cita", "Fecha_de_cierre_final"}
                                }
                            ),
                            "OK",
                            "BA",
                            Replacer.ReplaceText,
                            {"BA"}
                        ),
                        "OK",
                        "IP_TV",
                        Replacer.ReplaceText,
                        {"IP_TV"}
                    ),
                    {
                        "Departamento",
                        "Medio_de_Acceso",
                        "Numero_de_actuacion",
                        "BA",
                        "external_id",
                        "Fecha_de_cierre_final",
                        "IP_TV",
                        "Pet_atis",
                        "Subtipo_de_orden"
                    }
                )
            ),
    //Se reemplaza NULL por null para trabajar con los tipos de datos correctos
    ReplacedNull = Table.ReplaceValue(
        SelectColumns,
        "NULL",
        null,
        Replacer.ReplaceValue,
        {
            "Numero_de_actuacion",
            "Subtipo_de_orden",
            "Pet_atis",
            "Departamento",
            "Fecha_de_cierre_final",
            "BA",
            "IP_TV",
            "external_id",
            "Medio_de_Acceso"
        }
    ),
    //Se cambia el tipo de dato segun corresponda a cada columnna
    ChangedType = Table.TransformColumnTypes(
        ReplacedNull,
        {
            {"Numero_de_actuacion", type text},
            {"Subtipo_de_orden", type text},
            {"Pet_atis", type text},
            {"Departamento", type text},
            {"Fecha_de_cierre_final", type datetime},
            {"BA", type text},
            {"IP_TV", type text},
            {"external_id", type text},
            {"Medio_de_Acceso", type text}
        }
    ),
    //Se agrega una columna de Año y se le suma un mes
    InsertedYearAdd = Table.AddColumn(
        ChangedType,
        "Año",
        each
            if (Date.Month([Fecha_de_cierre_final]) = 12) then
                (1 + Date.Year([Fecha_de_cierre_final]))
            else
                (Date.Year([Fecha_de_cierre_final])),
        Int64.Type
    ),
    //Se agrega la columna de Mes y se le agrega un mes
    InsertedMonthAdd = Table.AddColumn(
        InsertedYearAdd,
        "Mes",
        each if (Date.Month([Fecha_de_cierre_final]) = 12) then (1) else (1 + Date.Month([Fecha_de_cierre_final])),
        Int64.Type
    ),
    //Se agrega la columna calculada de A_LB+BA
    AddedALBBA = Table.AddColumn(
        InsertedMonthAdd,
        "A_LB+BA",
        each
            if ([Subtipo_de_orden] = "ALTALB") or ([Subtipo_de_orden] = "TRASLADOLB") then
                (1)
            else
                (if ([BA] = "BA") and ([Medio_de_Acceso] = "COBRE") then (1) else (0)),
        type number
    ),
    //Se agrega la columna de A_IPTV
    AddedAIPTV = Table.AddColumn(AddedALBBA, "A_IPTV", each if ([IP_TV] = "IP_TV") then (1) else (0), type number),
    //Se agrega la columna calculada de A_FTTH
    AddedAFTTH = Table.AddColumn(
        AddedAIPTV, "A_FTTH", each if ([BA] = "BA") and ([Medio_de_Acceso] = "FIBRA") then (1) else (0), type number
    )
in
    AddedAFTTH
